//
//  HSAudioPlayerItem.swift
//  HSAudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public class HSAudioPlayerItem : NSObject {

	// MARK: - PUBLIC -

	// MARK: - Properties

	public var avPlayerItem						: AVPlayerItem?

	public var nowPlayingInfo					: [String : NSObject]?

	// MARK: - Lifecycle

	public func loadResource() {
		// Reloads the resource in the child class if necessary.
	}

	public func getAVPlayerItem() -> AVPlayerItem? {
		// Return the AVPlayerItem in the subclasses
		return nil
	}

	// MARK: - Now playing info

	public func initNowPlayingInfo() {
		// Init the now playing info here
		self.nowPlayingInfo = [String : NSObject]()
		self.updateNowPlayingInfoPlaybackDuration()
	}

	// MARK: - Helper

	public func durationInSeconds() -> Float {
		if let _avPlayerItem = self.avPlayerItem where _avPlayerItem.duration != kCMTimeIndefinite {
			return Float(CMTimeGetSeconds(_avPlayerItem.duration))
		}
		return Float(0)
	}

	public func currentProgress() -> Float {
		if (self.durationInSeconds() > 0) {
			return self.currentTimeInSeconds() / self.durationInSeconds()
		}
		return Float(0)
	}

	public func currentTimeInSeconds() -> Float {
		if let _avPlayerItem = self.avPlayerItem {
			return Float(CMTimeGetSeconds(_avPlayerItem.currentTime()))
		}
		return Float(0)
	}

	// MARK: - Displayable Time strings

	public func displayablePlaybackTimeString() -> String {
		return HSAudioPlayerItem.displayableStringFromTimeInterval(NSTimeInterval(self.currentTimeInSeconds()))
	}

	public func displayableDurationString() -> String {
		return HSAudioPlayerItem.displayableStringFromTimeInterval(NSTimeInterval(self.durationInSeconds()))
	}

	public func displayableTimeLeftString() -> String {
		let timeLeft = self.durationInSeconds() - self.currentTimeInSeconds()
		return "-\(HSAudioPlayerItem.displayableStringFromTimeInterval(NSTimeInterval(timeLeft)))"
	}

	public func isPlayable() -> Bool {
		return true
	}

	// MARK: - INTERNAL -

	// MARK: - Lifecycle

	func prepareForPlaying(avPlayerItem: AVPlayerItem) {
		self.avPlayerItem = avPlayerItem
		self.initNowPlayingInfo()
	}
	
	func cleanupAfterPlaying() {
		self.avPlayerItem = nil
		self.nowPlayingInfo?.removeAll()
	}

	// MARK: - Now playing info

	public func updateNowPlayingInfoPlaybackDuration() {
		if let _avPlayerItem = self.avPlayerItem {
			let duration = NSNumber(integer: Int(CMTimeGetSeconds(_avPlayerItem.asset.duration)))
			self.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
		}
	}

	// MARK: - Helper

	public func identifier() -> String? {
		// Return an unqiue identifier of the item in the subclasses
		return nil
	}

	// MARK: NSTimeInterval

	class func displayableStringFromTimeInterval(timeInterval: NSTimeInterval) -> String {
		let dateComponentsFormatter = NSDateComponentsFormatter()
		dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehavior.Pad
		if (timeInterval >= 60 * 60) {
			dateComponentsFormatter.allowedUnits = [.Hour, .Minute, .Second]
		} else {
			dateComponentsFormatter.allowedUnits = [.Minute, .Second]
		}
		return dateComponentsFormatter.stringFromTimeInterval(timeInterval) ?? "0:00"
	}
}
