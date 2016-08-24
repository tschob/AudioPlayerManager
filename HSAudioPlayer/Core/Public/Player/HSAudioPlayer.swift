//
//  HSAudioPlayer.swift
//  HSAudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public class HSAudioPlayer: NSObject {

	// MARK: - PUBLIC -

	// MARK: - Properties

	public static let sharedInstance				= HSAudioPlayer()

	// MARK: - Configuration

	/// Set this to true if the `HSAudioPlayer` log should be enabled. The default is `false`.
	public static var Verbose						= true

	/// Set this to true if the `HSAudioPlayer` log should containt detailed information about the calling class, function and line. The default is `true`.
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

	// MARK: - Initializaiton

	public class func audioPlayer() -> HSAudioPlayer {
		let audioPlayer = HSAudioPlayer()
		audioPlayer.setup()
		return audioPlayer
	}

	public class func audioPlayer(useNowPlayingInfoCenter useNowPlayingInfoCenter: Bool, useRemoteControlEvents: Bool) -> HSAudioPlayer {
		let audioPlayer = HSAudioPlayer()
		audioPlayer.useRemoteControlEvents = useRemoteControlEvents
		audioPlayer.useNowPlayingInfoCenter = useNowPlayingInfoCenter
		audioPlayer.setup()
		return audioPlayer
	}

	public override init() {
		super.init()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HSAudioPlayer.playerItemDidFinishPlaying), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
	}

	public func setup() {
		self.setup(useNowPlayingInfoCenter: self.useNowPlayingInfoCenter, useRemoteControlEvents: self.useRemoteControlEvents)
	}

	public func setup(useNowPlayingInfoCenter useNowPlayingInfoCenter: Bool, useRemoteControlEvents: Bool) {
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
			if let _currentPlayerItem = self.currentPlayerItem() {
				NSNotificationCenter.defaultCenter().postNotificationName(self.playerStateChangedNotificationKey(playerItem: _currentPlayerItem), object: nil)
			}
		}
	}

	public func play(playerItem: HSAudioPlayerItem) {
		HSAudioPlayerLog("play(playerItem: \(playerItem))")
		self.stop()
		self.play([playerItem], startPosition: 0)
	}

	public func play(playerItems: [HSAudioPlayerItem], startPosition: Int) {
		HSAudioPlayerLog("play(playerItems: \(playerItems.count) items, startPosition: \(startPosition))")
		self.replace(playerItems, startPosition: startPosition)
		// Start playing the new item
		self.restartCurrentPlayerItem()
    }

	public func replace(playerItem: HSAudioPlayerItem) {
		HSAudioPlayerLog("replace(playerItem: \(playerItem))")
		self.replace([playerItem], startPosition: 0)
	}

	public func replace(playerItems: [HSAudioPlayerItem], startPosition: Int) {
		HSAudioPlayerLog("replace(playerItems: \(playerItems.count) items, startPosition: \(startPosition))")
		self.stop()
		var reducedPlayerItems = [] as [HSAudioPlayerItem]
		for index in 0..<playerItems.count {
			let playerItem = playerItems[index]
			reducedPlayerItems.append(playerItem)
		}

		self.queue.replace(reducedPlayerItems, startPosition: startPosition)
		self.queueGeneration += 1
	}

	public func prepend(playerItems: [HSAudioPlayerItem], queueGeneration: Int) {
		if (self.queueGeneration == queueGeneration) {
			HSAudioPlayerLog("Queue generation (\(queueGeneration)) gets prepended with \(playerItems.count) player items.")
			self.queue.prepend(playerItems)
			self.callPlayStateChangeCallbacks()
		} else {
			HSAudioPlayerLog("Queue generation (\(queueGeneration)) isn't the same as the current (\(self.queueGeneration)). Won't prepend \(playerItems.count) player items.")
		}
	}

	public func append(playerItems: [HSAudioPlayerItem], queueGeneration: Int) {
		if (self.queueGeneration == queueGeneration) {
			HSAudioPlayerLog("Queue generation (\(queueGeneration)) gets appended with \(playerItems.count) player items.")
			self.queue.append(playerItems)
			self.callPlayStateChangeCallbacks()
		} else {
			HSAudioPlayerLog("Queue generation (\(queueGeneration)) isn't the same as the current (\(self.queueGeneration)). Won't append \(playerItems.count) player items.")
		}
	}

	// MARK: Pause

    public func pause() {
		if let _player = self.player {
            _player.pause()
			self.stopPlaybackTimeChangeTimer = true
			self.callPlaybackTimeChangeCallbacks()
			self.callPlayStateChangeCallbacks()
			if let _currentPlayerItem = self.currentPlayerItem() {
				NSNotificationCenter.defaultCenter().postNotificationName(self.playerStateChangedNotificationKey(playerItem: _currentPlayerItem), object: nil)
			}
        }
    }

	public func stop() {
		self.didStopPlayback = true
		self.pause()
		self.player?.seekToTime(CMTimeMake(0, 1))
		self.callPlayStateChangeCallbacks()
		self.callPlaybackTimeChangeCallbacks()
	}

	// MARK: Forward

	public func canForward() -> Bool {
		return self.queue.canForward()
	}

	public func forward() {
		self.stop()
		if (self.queue.forward() == true) {
			self.restartCurrentPlayerItem()
		}
    }

	// MARK: Rewind

    public func canRewind() -> Bool {
		if (self.currentPlayerItem()?.currentTimeInSeconds() > Float(1) || self.canRewindInQueue()) {
			return true
		}
        return false
    }

    public func rewind() {
		if (self.currentPlayerItem()?.currentTimeInSeconds() <= Float(1) && self.canRewindInQueue() == true) {
			self.stop()
			if (self.queue.rewind() == true) {
				self.restartCurrentPlayerItem()
			}
		} else {
			// Move to the beginning of the player item if we aren't in the beginning.
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
		let progressInSeconds = Int64(progress * (self.currentPlayerItem()?.durationInSeconds() ?? 0))
		let time = CMTimeMake(progressInSeconds, 1)
		self.seek(toTime: time)
	}

	// MARK: - Internal helper

    public func playerItemDidFinishPlaying() {
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

	public func addPlaybackTimeChangeCallback(sender: AnyObject, callback: (playerItem: HSAudioPlayerItem) -> Void) {
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

	public func addPlayStateChangeCallback(sender: AnyObject, callback: (playerItem: HSAudioPlayerItem?) -> Void) {
		let uid = "\(unsafeAddressOf(sender))"
		if var _callbacks = self.playStateChangeCallbacks[uid] {
			_callbacks.append(callback)
		} else {
			self.playStateChangeCallbacks[uid] = [callback]
		}
	}

	public func removePlayStateChangeCallback(sender: AnyObject) {
		let uid = "\(unsafeAddressOf(sender))"
		self.playbackPositionChangeCallbacks.removeValueForKey(uid)
	}

	// MARK: - Helper

	public func isPlaying() -> Bool {
		return self.player?.rate > 0
	}

	public func currentPlayerItem() -> HSAudioPlayerItem? {
		return self.queue.currentPlayingItem()
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

	private let audioPlayerStateChangedPrefix		= "HSAudioPlayer.\(NSUUID().UUIDString).playerStateChanged"

	private var player								: AVPlayer?

	private var queue								= HSAudioPlayerQueue()

	private var didStopPlayback						= false


	// MARK: Callbacks
	private var playStateChangeCallbacks			= Dictionary<String, [((playerItem: HSAudioPlayerItem?) -> (Void))]>()
	private var playbackPositionChangeCallbacks		= Dictionary<String, [((playerItem: HSAudioPlayerItem) -> (Void))]>()

	private var playbackPositionChangeTimer			: NSTimer?
	private var stopPlaybackTimeChangeTimer			= false

	private var addedPlayerStateObserver			= false

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

	private func restartCurrentPlayerItem() {
		HSAudioPlayerLog("restartCurrentPlayerItem")
		if (self.player != nil) {
			if (self.addedPlayerStateObserver == true) {
				self.addedPlayerStateObserver = false
				self.player?.removeObserver(self, forKeyPath: Keys.Status, context: nil)
			}
			self.stop()
		}

		if
			let _currentPlayerItem  = self.queue.currentPlayingItem() {
			self.player = AVPlayer()
			self.initPlayer()
			_currentPlayerItem.loadResource()
			if let _avPlayerItem = _currentPlayerItem.getAVPlayerItem() {
				_currentPlayerItem.prepareForPlaying(_avPlayerItem)
				self.player?.replaceCurrentItemWithPlayerItem(_avPlayerItem)
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
			MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.currentPlayerItem()?.nowPlayingInfo
		}
	}

	// MARK: - Plaback time change callback

	func callPlaybackTimeChangeCallbacks() {
		// Increase the current items playing time if the player is playing
		if let _currentPlayerItem = self.currentPlayerItem() {
			for sender in self.playbackPositionChangeCallbacks.keys {
				if let _callbacks = self.playbackPositionChangeCallbacks[sender] {
					for playbackPositionChangeClosure in _callbacks {
						playbackPositionChangeClosure(playerItem: _currentPlayerItem)
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
		self.playbackPositionChangeTimer =  NSTimer.scheduledTimerWithTimeInterval(self.playingTimeRefreshRate, target: self, selector: #selector(HSAudioPlayer.callPlaybackTimeChangeCallbacks), userInfo: nil, repeats: true)
		self.playbackPositionChangeTimer?.fire()
	}

	// MARK: - Play state change callback

	func callPlayStateChangeCallbacks() {
		for sender in self.playStateChangeCallbacks.keys {
			if let _callbacks = self.playStateChangeCallbacks[sender] {
				for playStateChangeClosure in _callbacks {
					playStateChangeClosure(playerItem: self.currentPlayerItem())
				}
			}
		}
	}
}

extension HSAudioPlayer {

	public func playerStateChangedNotificationKey(playerItem playerItem: HSAudioPlayerItem) -> String {
		return "\(self.audioPlayerStateChangedPrefix)_\(playerItem.identifier() ?? "")"
	}
}
