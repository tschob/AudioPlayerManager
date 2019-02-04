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

	public struct Formats {
		static var durationStringForNilObject	= "-:-"
	}

	open var playerItem						: AVPlayerItem?

	open var nowPlayingInfo					: [String: NSObject]?

	// MARK: - Lifecycle

	open func loadResource() {
		// Reloads the resource in the child class if necessary.
	}

	open func avPlayerItem() -> AVPlayerItem? {
		// Return the AVPlayerItem in the subclasses
		return nil
	}

	// MARK: - Now playing info

	open func initNowPlayingInfo() {
		// Init the now playing info here
		self.nowPlayingInfo = [String: NSObject]()
		self.updateNowPlayingInfoPlaybackDuration()
	}

	// MARK: - Helper

	open func durationInSeconds() -> Float? {
		guard let playerItem = self.playerItem, playerItem.duration != CMTime.indefinite else {
			return nil
		}
		return Float(CMTimeGetSeconds(playerItem.duration))
	}

	open func currentProgress() -> Float {
		guard let durationInSeconds = self.durationInSeconds(), durationInSeconds > 0 else {
			return Float(0)
		}
		return self.currentTimeInSeconds() / durationInSeconds
	}

	open func currentTimeInSeconds() -> Float {
		guard let playerItem = self.playerItem else {
			return Float(0)
		}

		// Return the current time, use the duration if the current time is higher than the duration, but greater than 0.0
		let currentTime = Float(CMTimeGetSeconds(playerItem.currentTime()))
		let duration = self.durationInSeconds() ?? 0.0
		guard (duration <= 0.0 || currentTime <= duration) else {
			return duration
		}

		return currentTime
	}

	// MARK: - Displayable Time strings

	open func displayablePlaybackTimeString() -> String {
		return AudioTrack.displayableString(from: TimeInterval(self.currentTimeInSeconds()))
	}

	open func displayableDurationString() -> String {
		return AudioTrack.displayableString(from: self.durationInSeconds())
	}

	open func displayableTimeLeftString() -> String {
		guard let durationInSeconds = self.durationInSeconds() else {
			return AudioTrack.Formats.durationStringForNilObject
		}
		let timeLeft = durationInSeconds - self.currentTimeInSeconds()
		return "-\(AudioTrack.displayableString(from: timeLeft))"
	}

	open func isPlayable() -> Bool {
		return true
	}

	// MARK: - INTERNAL -

	// MARK: - Lifecycle

	open func prepareForPlaying(_ playerItem: AVPlayerItem) {
		self.playerItem = playerItem
		self.initNowPlayingInfo()
	}

	open func cleanupAfterPlaying() {
		self.playerItem = nil
		self.nowPlayingInfo?.removeAll()
	}

	// MARK: - Now playing info

	open func updateNowPlayingInfoPlaybackDuration() {
		self.playerItem?.asset.loadDuration(completion: { [weak self] (duration: NSNumber?) in
			self?.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
		})
	}

	open func updateNowPlayingInfoPlaybackTime() {
		let currentTime = self.currentTimeInSeconds()
		// Check if the time isn't NaN.
		let currentTimeAsNumber : NSNumber? = ((currentTime.isNaN == false) ? NSNumber(value: Float(currentTime)) : nil)
		self.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTimeAsNumber
	}

	// MARK: - Helper

	open func identifier() -> String? {
		// Return an unqiue identifier of the item in the subclasses
		return nil
	}

	// MARK: - NSTimeInterval

	open class func displayableString(from seconds: Float?) -> String {
		guard let seconds = seconds else {
			return AudioTrack.Formats.durationStringForNilObject
		}
		return self.displayableString(from: TimeInterval(seconds))
	}

	open class func displayableString(from timeInterval: TimeInterval) -> String {
		let dateComponentsFormatter = DateComponentsFormatter()
		dateComponentsFormatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior.pad
		if (timeInterval >= 60 * 60) {
			dateComponentsFormatter.allowedUnits = [.hour, .minute, .second]
		} else {
			dateComponentsFormatter.allowedUnits = [.minute, .second]
		}
		return dateComponentsFormatter.string(from: timeInterval) ?? AudioTrack.Formats.durationStringForNilObject
	}
}
