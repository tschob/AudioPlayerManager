//
//  AudioTracksQueue.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit

class AudioTracksQueue: NSObject {

	// MARK: - Private variables

	fileprivate(set) var currentTrack		: AudioTrack?

	fileprivate var previousTrack			: AudioTrack? {
		let previousIndex = self.currentItemQueueIndex - 1
		if (previousIndex >= 0) {
			return self.queue[previousIndex]
		}
		return nil
	}

	fileprivate var queue					= [AudioTrack]()
	fileprivate var currentItemQueueIndex	= 0

	fileprivate var history					= [AudioTrack]()

	// MARK: - Set

	func replace(_ tracks: [AudioTrack]?, at startIndex: Int) {
		if let tracks = tracks {
			// Add the current track to the history
			if let currentTrack = self.currentTrack {
				self.history.append(currentTrack)
			}
			// Replace the tracks in the queue with the new ones
			self.queue = tracks
			self.currentItemQueueIndex = startIndex
			self.currentTrack?.cleanupAfterPlaying()
			self.currentTrack = tracks[startIndex]
		} else {
			self.queue.removeAll()
			self.currentTrack?.cleanupAfterPlaying()
			self.currentTrack = nil
			self.currentItemQueueIndex = 0
		}
	}

	func prepend(_ tracks: [AudioTrack]) {
		// Insert the tracks at the beginning of the queue
		self.queue.insert(contentsOf: tracks, at: 0)
		// Adjust the current index to the new size
		self.currentItemQueueIndex += tracks.count
	}

	func append(_ tracks: [AudioTrack]) {
		self.queue.append(contentsOf: tracks)
	}

	// MARK: - Forward

	func canForward() -> Bool {
		return (self.queue.isEmpty == false && self.followingTrack() != nil)
	}

	func forward() -> Bool {
		if (self.canForward() == true),
			let currentTrack = self.currentTrack,
			let followingTrack = self.followingTrack() {
				// Add current track to the history
				currentTrack.cleanupAfterPlaying()
				// Replace the current track with the new one
				self.currentTrack = followingTrack
				// Adjust the current track index
				self.currentItemQueueIndex += 1
				// Add the former track to the history
				self.history.append(currentTrack)
				return true
		}
		return false
	}

	fileprivate func followingTrack() -> AudioTrack? {
		let followingIndex = self.currentItemQueueIndex + 1
		if (followingIndex < self.queue.count) {
			return self.queue[followingIndex]
		}
		return nil
	}

	// MARK: - Rewind

	func canRewind() -> Bool {
		return (self.previousTrack != nil)
	}

	func rewind() -> Bool {
		if (self.canRewind() == true),
			let currentTrack = self.currentTrack {
				currentTrack.cleanupAfterPlaying()
				// Replace the current track with the former one
				self.currentTrack = self.previousTrack
				// Adjust the current index
				self.currentItemQueueIndex -= 1
				return true
		}
		return false
	}

	// MARK: - Get

	func count() -> Int {
		return self.queue.count
	}

	// History

	fileprivate func appendCurrentPlayingItemToQueue() {
		if let currentTrack = self.currentTrack {
			self.history.append(currentTrack)
		}
	}
}
