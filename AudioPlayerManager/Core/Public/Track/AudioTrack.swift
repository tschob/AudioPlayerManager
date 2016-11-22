//
//  AudioTrack.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

open class AudioTrack : NSObject {

	// MARK: - PUBLIC -

	// MARK: - Properties

	open var playerItem						: AVPlayerItem?

	open var nowPlayingInfo					: [String : NSObject]?

	// MARK: - Lifecycle

	open func loadResource() {
		// Reloads the resource in the child class if necessary.
	}

	open func getPlayerItem() -> AVPlayerItem? {
		// Return the AVPlayerItem in the subclasses
		return nil
	}

	// MARK: - Now playing info

	open func initNowPlayingInfo() {
		// Init the now playing info here
		self.nowPlayingInfo = [String : NSObject]()
		self.updateNowPlayingInfoPlaybackDuration()
	}

	// MARK: - Helper

	open func durationInSeconds() -> Float {
		if let _playerItem = self.playerItem, _playerItem.duration != kCMTimeIndefinite {
			return Float(CMTimeGetSeconds(_playerItem.duration))
		}
		return Float(0)
	}

	open func currentProgress() -> Float {
		if (self.durationInSeconds() > 0) {
			return self.currentTimeInSeconds() / self.durationInSeconds()
		}
		return Float(0)
	}

	open func currentTimeInSeconds() -> Float {
		if let _playerItem = self.playerItem {
			return Float(CMTimeGetSeconds(_playerItem.currentTime()))
		}
		return Float(0)
	}

	// MARK: - Displayable Time strings

	open func displayablePlaybackTimeString() -> String {
		return AudioTrack.displayableString(from: TimeInterval(self.currentTimeInSeconds()))
	}

	open func displayableDurationString() -> String {
		return AudioTrack.displayableString(from: TimeInterval(self.durationInSeconds()))
	}

	open func displayableTimeLeftString() -> String {
		let timeLeft = self.durationInSeconds() - self.currentTimeInSeconds()
		return "-\(AudioTrack.displayableString(from: TimeInterval(timeLeft)))"
	}

	open func isPlayable() -> Bool {
		return true
	}

	// MARK: - INTERNAL -

	// MARK: - Lifecycle

	func prepareForPlaying(_ playerItem: AVPlayerItem) {
		self.playerItem = playerItem
		self.initNowPlayingInfo()
	}

	func cleanupAfterPlaying() {
		self.playerItem = nil
		self.nowPlayingInfo?.removeAll()
	}

	// MARK: - Now playing info

	open func updateNowPlayingInfoPlaybackDuration() {
		if let _playerItem = self.playerItem {
			let duration = NSNumber(value: Int(CMTimeGetSeconds(_playerItem.asset.duration)) as Int)
			self.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
		}
	}

	// MARK: - Helper

	open func identifier() -> String? {
		// Return an unqiue identifier of the item in the subclasses
		return nil
	}

	// MARK: NSTimeInterval

	class func displayableString(from timeInterval: TimeInterval) -> String {
		let dateComponentsFormatter = DateComponentsFormatter()
		dateComponentsFormatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior.pad
		if (timeInterval >= 60 * 60) {
			dateComponentsFormatter.allowedUnits = [.hour, .minute, .second]
		} else {
			dateComponentsFormatter.allowedUnits = [.minute, .second]
		}
		return dateComponentsFormatter.string(from: timeInterval) ?? "0:00"
	}
}
