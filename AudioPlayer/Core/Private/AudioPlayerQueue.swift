//
//  AudioPlayerQueue.swift
//  AudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit

class AudioPlayerQueue: NSObject {

	// MARK: - Private variables

	private var currentItem				: AudioPlayerItem?

	private var queue					= [AudioPlayerItem]()
	private var currentItemQueueIndex	= 0

	private var history					= [AudioPlayerItem]()

	// MARK: Set

	func replace(playerItems: [AudioPlayerItem]?, startPosition: Int) {
		if let _playerItems = playerItems {
			// Add the current playing item to the history
			if let _currentItem = self.currentItem {
				self.history.append(_currentItem)
			}
			// Replace the items in the queue with the new ones
			self.queue = _playerItems
			self.currentItemQueueIndex = startPosition
			self.currentItem?.cleanupAfterPlaying()
			self.currentItem = _playerItems[startPosition]
		} else {
			self.queue.removeAll()
			self.currentItem?.cleanupAfterPlaying()
			self.currentItem = nil
			self.currentItemQueueIndex = 0
		}
	}

	func prepend(playerItems: [AudioPlayerItem]) {
		// Insert the player items at the beginning of the queue
		self.queue.insertContentsOf(playerItems, at: 0)
		// Adjust the current player item index to the new size
		self.currentItemQueueIndex += playerItems.count
	}

	func append(playerItems: [AudioPlayerItem]) {
		self.queue.appendContentsOf(playerItems)
	}

	// MARK: Forward

	func canForward() -> Bool {
		return (self.queue.count > 0 && self.followingPlayerItem() != nil)
	}

	func forward() -> Bool {
		if (self.canForward() == true),
			let _currentItem = self.currentItem,
			_followingPlayerItem = self.followingPlayerItem() {
				// Add current player item to the history
				_currentItem.cleanupAfterPlaying()
				// Replace current player item with the new one
				self.currentItem = _followingPlayerItem
				// Adjust the current item index
				self.currentItemQueueIndex += 1
				// Add the former item to the history
				self.history.append(_currentItem)
				return true
		}
		return false
	}

	private func followingPlayerItem() -> AudioPlayerItem? {
		let followingIndex = self.currentItemQueueIndex + 1
		if (followingIndex < self.queue.count) {
			return self.queue[followingIndex]
		}
		return nil
	}

	// MARK: Rewind

	func canRewind() -> Bool {
		return (self.previousItem() != nil)
	}

	func rewind() -> Bool {
		if (self.canRewind() == true),
			let _currentItem = self.currentItem {
				_currentItem.cleanupAfterPlaying()
				// Replace the current player item with the former one
				self.currentItem = self.previousItem()
				// Adjust the current item index
				self.currentItemQueueIndex -= 1
				return true
		}
		return false
	}

	private func previousItem() -> AudioPlayerItem? {
		let previousIndex = self.currentItemQueueIndex - 1
		if (previousIndex >= 0) {
			return self.queue[previousIndex]
		}
		return nil
	}

	// MARK: Get

	func currentPlayingItem() -> AudioPlayerItem? {
		return self.currentItem
	}

	func previousPlayingItem() -> AudioPlayerItem? {
		return self.previousItem()
	}

	func count() -> Int {
		return self.queue.count
	}

	// History

	private func appendCurrentPlayingItemToQueue() {
		if let _currentItem = self.currentItem {
			self.history.append(_currentItem)
		}
	}
}
