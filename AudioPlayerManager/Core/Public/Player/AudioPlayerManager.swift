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

public class AudioPlayerManager: NSObject {

	// MARK: - PUBLIC -

	// MARK: - Properties

	public static let sharedInstance				= AudioPlayerManager()

	// MARK: - Configuration

	/// Set this to true if the `AudioPlayerManager` log should be enabled. The default is `false`.
	public static var Verbose						= true

	/// Set this to true if the `AudioPlayerManager` log should containt detailed information about the calling class, function and line. The default is `true`.
	public static var DetailedLog					= true

	/// Set this to true to use the systems `MPNowPlayingInfoCenter` (control center and lock screen). The default value is `true`.
	public var useNowPlayingInfoCenter				= true

	// Set this to true to receive control events
	public var useRemoteControlEvents				= true {
		didSet {
			self.setupRemoteControlEvents()
		}
	}

	// The `NSTimeInterval` of the players update interval. Eg. the PlaybackTimeChangeCallbacks will be called then.
	public var playingTimeRefreshRate				: NSTimeInterval = 0.1

	public var currentTrack							: AudioTrack? {
		return self.queue.currentTrack
	}

	// MARK: - Initializaiton

	public class func standaloneInstance() -> AudioPlayerManager {
		return self.standaloneInstance(useNowPlayingInfoCenter: nil, useRemoteControlEvents: nil)
	}

	public class func standaloneInstance(useNowPlayingInfoCenter useNowPlayingInfoCenter: Bool?, useRemoteControlEvents: Bool?) -> AudioPlayerManager {
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

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AudioPlayerManager.trackDidFinishPlaying), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
	}

	public func setup() {
		self.setupRemoteControlEvents()
		self.setupAudioSession()
	}

	// MARK: - Control playback

	public func togglePlayPause() {
		if self.isPlaying() == true {
			self.pause()
		} else {
			self.play()
		}
	}

	// MARK: Play

	public func canPlay() -> Bool {
		return self.queue.count() > 0
	}

	public func play(updateNowPlayingInfo updateNowPlayingInfo: Bool = false) {
		if let _player = self.player {
			_player.play()
			if (updateNowPlayingInfo == true || self.didStopPlayback == true) {
				self.updateNowPlayingInfo()
			}
			self.didStopPlayback = false
			self.startPlaybackTimeChangeTimer()
			self.callPlayStateChangeCallbacks()
			if let _currentTrack = self.currentTrack {
				NSNotificationCenter.defaultCenter().postNotificationName(self.playerStateChangedNotificationKey(track: _currentTrack), object: nil)
			}
		}
	}

	public func play(audioTrack: AudioTrack) {
		Log("play(audioTrack: \(audioTrack))")
		self.stop()
		self.play([audioTrack], startIndex: 0)
	}

	public func play(audioTracks: [AudioTrack], startIndex: Int) {
		Log("play(audioTracks: \(audioTracks.count) tracks, startIndex: \(startIndex))")
		self.replace(audioTracks, startIndex: startIndex)
		// Start playing the new track
		self.restartCurrentTrack()
    }

	public func replace(audioTrack: AudioTrack) {
		Log("replace(audioTrack: \(audioTrack))")
		self.replace([audioTrack], startIndex: 0)
	}

	public func replace(audioTracks: [AudioTrack], startIndex: Int) {
		Log("replace(audioTracks: \(audioTracks.count) tracks, startIndex: \(startIndex))")
		self.stop()
		var reducedTracks = [] as [AudioTrack]
		for index in 0..<audioTracks.count {
			let audioTrack = audioTracks[index]
			reducedTracks.append(audioTrack)
		}

		self.queue.replace(reducedTracks, startIndex: startIndex)
		self.queueGeneration += 1
	}

	public func prepend(audioTracks: [AudioTrack], queueGeneration: Int) {
		if (self.queueGeneration == queueGeneration) {
			Log("Queue generation (\(queueGeneration)) gets prepended with \(audioTracks.count) tracks.")
			self.queue.prepend(audioTracks)
			self.callPlayStateChangeCallbacks()
		} else {
			Log("Queue generation (\(queueGeneration)) isn't the same as the current (\(self.queueGeneration)). Won't prepend \(audioTracks.count) tracks.")
		}
	}

	public func append(audioTracks: [AudioTrack], queueGeneration: Int) {
		if (self.queueGeneration == queueGeneration) {
			Log("Queue generation (\(queueGeneration)) gets appended with \(audioTracks.count) tracks.")
			self.queue.append(audioTracks)
			self.callPlayStateChangeCallbacks()
		} else {
			Log("Queue generation (\(queueGeneration)) isn't the same as the current (\(self.queueGeneration)). Won't append \(audioTracks.count) tracks.")
		}
	}

	// MARK: Pause

    public func pause() {
		if let _player = self.player {
            _player.pause()
			self.stopPlaybackTimeChangeTimer = true
			self.callPlaybackTimeChangeCallbacks()
			self.callPlayStateChangeCallbacks()
			if let _currentTrack = self.currentTrack {
				NSNotificationCenter.defaultCenter().postNotificationName(self.playerStateChangedNotificationKey(track: _currentTrack), object: nil)
			}
        }
    }

	public func stop(clearQueue clearQueue: Bool = false) {
		if (self.didStopPlayback == false) {
			self.didStopPlayback = true
			if (clearQueue == true) {
				self.queue.replace(nil, startIndex: 0)
				self.queueGeneration += 1
				self.player?.replaceCurrentItemWithPlayerItem(nil)
			} else {
				self.pause()
				self.player?.seekToTime(CMTimeMake(0, 1))
			}
			self.callPlayStateChangeCallbacks()
			self.callPlaybackTimeChangeCallbacks()
		}
	}

	// MARK: Forward

	public func canForward() -> Bool {
		return self.queue.canForward()
	}

	public func forward() {
		self.stop()
		if (self.queue.forward() == true) {
			self.restartCurrentTrack()
		}
    }

	// MARK: Rewind

    public func canRewind() -> Bool {
		if ((self.currentTrack?.currentTimeInSeconds() > Float(1) && self.currentTrack != nil) || self.canRewindInQueue()) {
			return true
		}
        return false
    }

    public func rewind() {
		if (self.currentTrack?.currentTimeInSeconds() <= Float(1) && self.canRewindInQueue() == true) {
			self.stop()
			if (self.queue.rewind() == true) {
				self.restartCurrentTrack()
			}
		} else {
			// Move to the beginning of the track if we aren't in the beginning.
			self.player?.seekToTime(CMTimeMake(0, 1))
			// Update the now playing info to show the new playback time
			self.updateNowPlayingInfo()
			// Call the callbacks to inform about the new time
			self.callPlaybackTimeChangeCallbacks()
		}
    }

	public func seek(toTime time: CMTime) {
		self.player?.seekToTime(time)
	}

	public func seek(toProgress progress: Float) {
		let progressInSeconds = Int64(progress * (self.currentTrack?.durationInSeconds() ?? 0))
		let time = CMTimeMake(progressInSeconds, 1)
		self.seek(toTime: time)
	}

	// MARK: - Internal helper

    public func trackDidFinishPlaying() {
        self.forward()
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if (object as? NSObject == self.player) {
			if (keyPath == Keys.Status) {
            	if self.player?.status == AVPlayerStatus.ReadyToPlay {
					self.play(updateNowPlayingInfo: true)
            	}
			}
        }
    }

	// MARK: - Playback time change callback

	public func addPlaybackTimeChangeCallback(sender: AnyObject, callback: (track: AudioTrack) -> Void) {
		let uid = "\(unsafeAddressOf(sender))"
		if var _callbacks = self.playbackPositionChangeCallbacks[uid] {
			_callbacks.append(callback)
		} else {
			self.playbackPositionChangeCallbacks[uid] = [callback]
		}
	}

	public func removePlaybackTimeChangeCallback(sender: AnyObject) {
		let uid = "\(unsafeAddressOf(sender))"
		self.playbackPositionChangeCallbacks.removeValueForKey(uid)
	}

	// MARK: - Play state change callback

	public func addPlayStateChangeCallback(sender: AnyObject, callback: (track: AudioTrack?) -> Void) {
		let uid = "\(unsafeAddressOf(sender))"
		if var _callbacks = self.playStateChangeCallbacks[uid] {
			_callbacks.append(callback)
		} else {
			self.playStateChangeCallbacks[uid] = [callback]
		}
	}

	public func removePlayStateChangeCallback(sender: AnyObject) {
		let uid = "\(unsafeAddressOf(sender))"
		self.playStateChangeCallbacks.removeValueForKey(uid)
	}

	// MARK: - Helper

	public func isPlaying() -> Bool {
		return self.player?.rate > 0
	}

	// MARK: - INTERNAL -

	// MARK: - Properties

	var queueGeneration								= 0

	// MARK: - Initializaiton

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func applicationDidEnterBackground(notification: NSNotification) {
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

	private struct Keys {
		static let Status	= "status"
	}

	private let audioPlayerManagerStateChangedPrefix	= "AudioPlayerManager.\(NSUUID().UUIDString).playerStateChanged"

	private var player									: AVPlayer?

	private var queue									= AudioTracksQueue()

	private var didStopPlayback							= false

	// MARK: Callbacks
	private var playStateChangeCallbacks				= Dictionary<String, [((track: AudioTrack?) -> (Void))]>()
	private var playbackPositionChangeCallbacks			= Dictionary<String, [((track: AudioTrack) -> (Void))]>()

	private var playbackPositionChangeTimer				: NSTimer?
	private var stopPlaybackTimeChangeTimer				= false

	private var addedPlayerStateObserver				= false

	// MARK: - Initializaiton

	private func setupAudioSession() {
		let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		let _ = try? AVAudioSession.sharedInstance().setActive(true)
	}

	private func initPlayer() {
		if let _player = self.player {
			_player.addObserver(self, forKeyPath: Keys.Status, options: NSKeyValueObservingOptions.New, context: nil)
			self.addedPlayerStateObserver = true
		}

		if (self.player?.respondsToSelector(Selector("setVolume:")) == true) {
			self.player?.volume = 1.0
		}
		self.player?.allowsExternalPlayback = true
		self.player?.usesExternalPlaybackWhileExternalScreenIsActive = true
	}

	private func setupRemoteControlEvents() {
		if (self.useRemoteControlEvents == true) {
			UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
		} else {
			UIApplication.sharedApplication().endReceivingRemoteControlEvents()
		}
	}

	// MARK: - Play

	private func restartCurrentTrack() {
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
				self.player?.replaceCurrentItemWithPlayerItem(_playerItem)
			}
		}
	}

	// MARK: Rewind

	private func canRewindInQueue() -> Bool {
		return self.queue.canRewind()
	}

	// MARK: - Internal helper

	private func updateNowPlayingInfo() {
		if (self.useNowPlayingInfoCenter == true) {
			MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.currentTrack?.nowPlayingInfo
		}
	}

	// MARK: - Plaback time change callback

	func callPlaybackTimeChangeCallbacks() {
		// Increase the current tracks playing time if the player is playing
		if let _currentTrack = self.currentTrack {
			for sender in self.playbackPositionChangeCallbacks.keys {
				if let _callbacks = self.playbackPositionChangeCallbacks[sender] {
					for playbackPositionChangeClosure in _callbacks {
						playbackPositionChangeClosure(track: _currentTrack)
					}
				}
			}
		}
		if (self.stopPlaybackTimeChangeTimer == true) {
			self.playbackPositionChangeTimer?.invalidate()
		}
	}

	private func startPlaybackTimeChangeTimer() {
		self.stopPlaybackTimeChangeTimer = false
		self.playbackPositionChangeTimer =  NSTimer.scheduledTimerWithTimeInterval(self.playingTimeRefreshRate, target: self, selector: #selector(AudioPlayerManager.callPlaybackTimeChangeCallbacks), userInfo: nil, repeats: true)
		self.playbackPositionChangeTimer?.fire()
	}

	// MARK: - Play state change callback

	func callPlayStateChangeCallbacks() {
		for sender in self.playStateChangeCallbacks.keys {
			if let _callbacks = self.playStateChangeCallbacks[sender] {
				for playStateChangeClosure in _callbacks {
					playStateChangeClosure(track: self.currentTrack)
				}
			}
		}
	}
}

extension AudioPlayerManager {

	public func playerStateChangedNotificationKey(track track: AudioTrack) -> String {
		return "\(self.audioPlayerManagerStateChangedPrefix)_\(track.identifier() ?? "")"
	}
}
