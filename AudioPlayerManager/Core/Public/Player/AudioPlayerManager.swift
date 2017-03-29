//
//  AudioPlayerManager.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

open class AudioPlayerManager: NSObject {

	// MARK: - PUBLIC -

	// MARK: - Properties

	open static let shared						= AudioPlayerManager()

	// MARK: - Configuration

	/// Set this to true if the `AudioPlayerManager` log should be enabled. The default is `false`.
	open static var verbose						= true

	/// Set this to true if the `AudioPlayerManager` log should contain detailed information about the calling class, function and line. The default is `true`
	open static var detailedLog					= true

	/// Set this to true to use the systems `MPNowPlayingInfoCenter` (control center and lock screen). The default value is `true`.
	open var useNowPlayingInfoCenter				= true

	// Set this to true to receive control events
	open var useRemoteControlEvents				= true {
		didSet {
			self.setupRemoteControlEvents()
		}
	}

	// The `NSTimeInterval` of the players update interval. Eg. the PlaybackTimeChangeCallbacks will be called then.
	open var playingTimeRefreshRate				: TimeInterval = 0.1

	open var currentTrack							: AudioTrack? {
		return self.queue.currentTrack
	}

	// MARK: - Initializaiton

	open class func makeStandalonePlayer() -> AudioPlayerManager {
		return self.makeStandalonePlayer(useNowPlayingInfoCenter: nil, useRemoteControlEvents: nil)
	}

	open class func makeStandalonePlayer(useNowPlayingInfoCenter: Bool?, useRemoteControlEvents: Bool?) -> AudioPlayerManager {
		let manager = AudioPlayerManager()
		if let _useRemoteControlEvents = useRemoteControlEvents {
			manager.useRemoteControlEvents = _useRemoteControlEvents
		}
		if let _useNowPlayingInfoCenter = useNowPlayingInfoCenter {
			manager.useNowPlayingInfoCenter = _useNowPlayingInfoCenter
		}
		return manager
	}

	public override init() {
		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(AudioPlayerManager.trackDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
	}

	open func setup() {
		self.setupRemoteControlEvents()
		self.setupAudioSession()
	}

	// MARK: - Control playback

	open func togglePlayPause() {
		if self.isPlaying() == true {
			self.pause()
		} else {
			self.play()
		}
	}

	// MARK: Play

	open func canPlay() -> Bool {
		return self.queue.count() > 0
	}

	open func play(updateNowPlayingInfo: Bool = false) {
		if let _player = self.player {
			_player.play()
			if (updateNowPlayingInfo == true || self.didStopPlayback == true) {
				self.updateNowPlayingInfoIfNeeded()
			}
			self.didStopPlayback = false
			self.startPlaybackTimeChangeTimer()
			self.callPlayStateChangeCallbacks()
			if let _currentTrack = self.currentTrack {
				NotificationCenter.default.post(name: Notification.Name(rawValue: self.playerStateChangedNotificationKey(track: _currentTrack)), object: nil)
			}
		}
	}

	open func play(_ audioTrack: AudioTrack) {
		Log("play(audioTrack: \(audioTrack))")
		self.stop()
		self.play([audioTrack], at: 0)
	}

	open func play(_ audioTracks: [AudioTrack], at startIndex: Int) {
		Log("play(audioTracks: \(audioTracks.count) tracks, startIndex: \(startIndex))")
		self.replace(with: audioTracks, at: startIndex)
		// Start playing the new track
		self.restartCurrentTrack()
    }

	open func replace(with audioTrack: AudioTrack) {
		Log("replace(audioTrack: \(audioTrack))")
		self.replace(with: [audioTrack], at: 0)
	}

	open func replace(with audioTracks: [AudioTrack], at startIndex: Int) {
		Log("replace(audioTracks: \(audioTracks.count) tracks, startIndex: \(startIndex))")
		self.stop()
		var reducedTracks = [] as [AudioTrack]
		for index in 0..<audioTracks.count {
			let audioTrack = audioTracks[index]
			reducedTracks.append(audioTrack)
		}

		self.queue.replace(reducedTracks, at: startIndex)
		self.queueGeneration += 1
	}

	open func prepend(_ audioTracks: [AudioTrack], toQueue generation: Int) {
		if (self.queueGeneration == generation) {
			Log("Queue generation (\(generation)) gets prepended with \(audioTracks.count) tracks.")
			self.queue.prepend(audioTracks)
			self.callPlayStateChangeCallbacks()
		} else {
			Log("Queue generation (\(generation)) isn't the same as the current (\(self.queueGeneration)). Won't prepend \(audioTracks.count) tracks.")
		}
	}

	open func append(_ audioTracks: [AudioTrack], toQueue generation: Int) {
		if (self.queueGeneration == generation) {
			Log("Queue generation (\(generation)) gets appended with \(audioTracks.count) tracks.")
			self.queue.append(audioTracks)
			self.callPlayStateChangeCallbacks()
		} else {
			Log("Queue generation (\(generation)) isn't the same as the current (\(self.queueGeneration)). Won't append \(audioTracks.count) tracks.")
		}
	}

	// MARK: Pause

    open func pause() {
		if let _player = self.player {
            _player.pause()
			self.stopPlaybackTimeChangeTimer = true
			self.callPlaybackTimeChangeCallbacks()
			self.callPlayStateChangeCallbacks()
			if let _currentTrack = self.currentTrack {
				NotificationCenter.default.post(name: Notification.Name(rawValue: self.playerStateChangedNotificationKey(track: _currentTrack)), object: nil)
			}
        }
    }

	open func stop(clearQueue: Bool = false) {
		if (self.didStopPlayback == false) {
			self.didStopPlayback = true
			if (clearQueue == true) {
				self.clearQueue()
			} else {
				self.player?.seek(to: CMTimeMake(0, 1))
				self.pause()
			}
			self.callPlayStateChangeCallbacks()
			self.callPlaybackTimeChangeCallbacks()
		} else if (clearQueue == true) {
			self.clearQueue()
		}
	}

	// MARK: Forward

	open func canForward() -> Bool {
		return self.queue.canForward()
	}

	open func forward() {
		self.stop()
		if (self.queue.forward() == true) {
			self.restartCurrentTrack()
		}
    }

	// MARK: Rewind

    open func canRewind() -> Bool {
		guard let _currentTrack = self.currentTrack else {
			return false
		}

		if ((_currentTrack.currentTimeInSeconds() > Float(1)) || self.canRewindInQueue()) {
			return true
		}

        return false
    }

    open func rewind() {
		guard let _currentTrack = self.currentTrack else {
			self.stop()
			return
		}

		if (_currentTrack.currentTimeInSeconds() <= Float(1) && self.canRewindInQueue() == true) {
			self.stop()
			if (self.queue.rewind() == true) {
				self.restartCurrentTrack()
			}
		} else {
			// Move to the beginning of the track if we aren't in the beginning.
			self.player?.seek(to: CMTimeMake(0, 1))
			// Update the now playing info to show the new playback time
			self.updateNowPlayingInfoIfNeeded()
			// Call the callbacks to inform about the new time
			self.callPlaybackTimeChangeCallbacks()
		}
    }

	open func seek(toTime time: CMTime) {
		self.player?.seek(to: time)
	}

	open func seek(toProgress progress: Float) {
		let progressInSeconds = Int64(progress * (self.currentTrack?.durationInSeconds() ?? 0))
		let time = CMTimeMake(progressInSeconds, 1)
		self.seek(toTime: time)
	}

	// MARK: - Internal helper

    open func trackDidFinishPlaying() {
        self.forward()
    }

    override open func observeValue(forKeyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if (object as? NSObject == self.player) {
			if (forKeyPath == Keys.Status) {
            	if self.player?.status == AVPlayerStatus.readyToPlay {
					self.play(updateNowPlayingInfo: true)
            	}
			}
        }
    }

	// MARK: - Playback time change callback

	open func addPlaybackTimeChangeCallback(_ sender: AnyObject, callback: @escaping (_ track: AudioTrack) -> Void) {
		let uid = "\(Unmanaged.passUnretained(sender).toOpaque())"
		if var _callbacks = self.playbackPositionChangeCallbacks[uid] {
			_callbacks.append(callback)
		} else {
			self.playbackPositionChangeCallbacks[uid] = [callback]
		}
	}

	open func removePlaybackTimeChangeCallback(_ sender: AnyObject) {
		let uid = "\(Unmanaged.passUnretained(sender).toOpaque())"
		self.playbackPositionChangeCallbacks.removeValue(forKey: uid)
	}

	// MARK: - Play state change callback

	open func addPlayStateChangeCallback(_ sender: AnyObject, callback: @escaping (_ track: AudioTrack?) -> Void) {
		let uid = "\(Unmanaged.passUnretained(sender).toOpaque())"
		if var _callbacks = self.playStateChangeCallbacks[uid] {
			_callbacks.append(callback)
		} else {
			self.playStateChangeCallbacks[uid] = [callback]
		}
	}

	open func removePlayStateChangeCallback(_ sender: AnyObject) {
		let uid = "\(Unmanaged.passUnretained(sender).toOpaque())"
		self.playStateChangeCallbacks.removeValue(forKey: uid)
	}

	// MARK: - Helper

	open func isPlaying() -> Bool {
		guard let _player = self.player else {
			return false
		}

		return _player.rate > 0
	}

	// MARK: - INTERNAL -

	// MARK: - Properties

	var queueGeneration								= 0

	// MARK: - Initializaiton

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	func applicationDidEnterBackground(_ notification: Notification) {
		if (self.isPlaying() == false) {
			self.stop()
		}
	}

	// MARK: - Lifecycle

	func didUpdateMetadata() {
		self.callPlayStateChangeCallbacks()
	}

	// MARK: - PRIVATE -

	// MARK: - Properties

	fileprivate struct Keys {
		static let Status	= "status"
	}

	fileprivate let audioPlayerManagerStateChangedPrefix	= "AudioPlayerManager.\(UUID().uuidString).playerStateChanged"

	fileprivate var player									: AVPlayer?

	fileprivate var queue									= AudioTracksQueue()

	fileprivate var didStopPlayback							= false

	// MARK: Callbacks
	fileprivate var playStateChangeCallbacks				= Dictionary<String, [((_ track: AudioTrack?) -> (Void))]>()
	fileprivate var playbackPositionChangeCallbacks			= Dictionary<String, [((_ track: AudioTrack) -> (Void))]>()

	fileprivate var playbackPositionChangeTimer				: Timer?
	fileprivate var stopPlaybackTimeChangeTimer				= false

	fileprivate var addedPlayerStateObserver				= false

	// MARK: - Initializaiton

	fileprivate func setupAudioSession() {
		let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		let _ = try? AVAudioSession.sharedInstance().setActive(true)
	}

	fileprivate func initPlayer() {
		if let _player = self.player {
			_player.addObserver(self, forKeyPath: Keys.Status, options: NSKeyValueObservingOptions.new, context: nil)
			self.addedPlayerStateObserver = true
		}

		if (self.player?.responds(to: #selector(setter: AVAudioMixing.volume)) == true) {
			self.player?.volume = 1.0
		}
		self.player?.allowsExternalPlayback = true
		self.player?.usesExternalPlaybackWhileExternalScreenIsActive = true
	}

	fileprivate func setupRemoteControlEvents() {
		if (self.useRemoteControlEvents == true) {
			UIApplication.shared.beginReceivingRemoteControlEvents()
		} else {
			UIApplication.shared.endReceivingRemoteControlEvents()
		}
	}

	// MARK: - Play

	fileprivate func restartCurrentTrack() {
		Log("restartCurrentTrack")
		if (self.player != nil) {
			if (self.addedPlayerStateObserver == true) {
				self.addedPlayerStateObserver = false
				self.player?.removeObserver(self, forKeyPath: Keys.Status, context: nil)
			}
			self.stop()
		}

		if let _currentTrack  = self.queue.currentTrack {
			self.player = AVPlayer()
			self.initPlayer()
			_currentTrack.loadResource()
			if let _playerItem = _currentTrack.getPlayerItem() {
				_currentTrack.prepareForPlaying(_playerItem)
				self.player?.replaceCurrentItem(with: _playerItem)
			}
		}
	}

	// MARK: Rewind

	fileprivate func canRewindInQueue() -> Bool {
		return self.queue.canRewind()
	}

	// MARK: - Internal helper

	fileprivate func updateNowPlayingInfoIfNeeded() {
		if (self.useNowPlayingInfoCenter == true) {
			// Update the current play time
			self.currentTrack?.updateNowPlayingInfoPlaybackTime()
			MPNowPlayingInfoCenter.default().nowPlayingInfo = self.currentTrack?.nowPlayingInfo
		}
	}

	private func clearQueue() {
		self.queue.replace(nil, at: 0)
		self.queueGeneration += 1
		self.player?.replaceCurrentItem(with: nil)
	}

	// MARK: - Plaback time change callback

	func callPlaybackTimeChangeCallbacks() {
		self.updateNowPlayingInfoIfNeeded()
		// Increase the current tracks playing time if the player is playing
		if let _currentTrack = self.currentTrack {
			for sender in self.playbackPositionChangeCallbacks.keys {
				if let _callbacks = self.playbackPositionChangeCallbacks[sender] {
					for playbackPositionChangeClosure in _callbacks {
						playbackPositionChangeClosure(_currentTrack)
					}
				}
			}
		}
		if (self.stopPlaybackTimeChangeTimer == true) {
			self.playbackPositionChangeTimer?.invalidate()
		}
	}

	fileprivate func startPlaybackTimeChangeTimer() {
		self.stopPlaybackTimeChangeTimer = false
		self.playbackPositionChangeTimer =  Timer.scheduledTimer(timeInterval: self.playingTimeRefreshRate, target: self, selector: #selector(AudioPlayerManager.callPlaybackTimeChangeCallbacks), userInfo: nil, repeats: true)
		self.playbackPositionChangeTimer?.fire()
	}

	// MARK: - Play state change callback

	func callPlayStateChangeCallbacks() {
		for sender in self.playStateChangeCallbacks.keys {
			if let _callbacks = self.playStateChangeCallbacks[sender] {
				for playStateChangeClosure in _callbacks {
					playStateChangeClosure(self.currentTrack)
				}
			}
		}
	}
}

extension AudioPlayerManager {

	public func playerStateChangedNotificationKey(track: AudioTrack) -> String {
		return "\(self.audioPlayerManagerStateChangedPrefix)_\(track.identifier() ?? "")"
	}
}
