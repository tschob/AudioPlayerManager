//
//  HSAudioPlayer+MPMediaItem.swift
//  HSAudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//
import MediaPlayer

extension HSAudioPlayer {

	// MARK: - Play

	public func play(mediaItem mediaItem: MPMediaItem) {
		if let _playerItem = HSMediaItemAudioPlayerItem(mediaItem: mediaItem) {
			self.play(_playerItem)
		}
	}

	public func play(mediaItems mediaItems: [MPMediaItem], startPosition: Int) {
		// Play first item directly and add the other items to the queue in the background
		if let firstPlayableItem = HSMediaItemAudioPlayerItem.firstPlayableItem(mediaItems, startPosition: startPosition) {
			// Play the first player item directly
			self.play(firstPlayableItem.playerItem)
			// Split the items into array which contain the ones which have to be prepended and appended them to the queue
			var mediaItemsToPrepend = Array(mediaItems)
			mediaItemsToPrepend.removeRange(firstPlayableItem.index..<mediaItemsToPrepend.count)
			var mediaItemsToAppend = Array(mediaItems)
			mediaItemsToAppend.removeRange(0..<(firstPlayableItem.index + 1))
			// Append the remaining items to queue in the background
			// As we creation of the items takes some time, we avoid a blocked UI
			self.addToQueueInBackground(prepend: mediaItemsToPrepend, append: mediaItemsToAppend, queueGeneration: self.queueGeneration)

		}
	}

	private func addToQueueInBackground(prepend mediaItemsToPrepend: [MPMediaItem], append mediaItemsToAppend: [MPMediaItem], queueGeneration: Int) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let itemsToPrepend = HSMediaItemAudioPlayerItem.playerItems(mediaItemsToPrepend, startPosition: 0)
			let tiemsToAppend = HSMediaItemAudioPlayerItem.playerItems(mediaItemsToAppend, startPosition: 0)
			dispatch_async(dispatch_get_main_queue()) {
				self.prepend(itemsToPrepend.items, queueGeneration: queueGeneration)
				self.append(tiemsToAppend.items, queueGeneration: queueGeneration)
			}
		}
	}

	// MARK: - Helper

	public func isPlaying(mediaItem mediaItem: MPMediaItem) -> Bool {
		return self.isPlaying(persistentID: mediaItem.persistentID)
	}

	public func isPlaying(mediaItemCollection: MPMediaItemCollection) -> Bool {
		for mediaItem in mediaItemCollection.items {
			if (self.isPlaying(mediaItem: mediaItem) == true) {
				return true
			}
		}
		return false
	}

	public func isPlaying(persistentID persistentID: MPMediaEntityPersistentID) -> Bool {
		if (self.isPlaying() == true),
			let _currentMediaItem = self.currentPlayerItem() as? HSMediaItemAudioPlayerItem {
			return ("\(persistentID)" == _currentMediaItem.identifier())
		}
		return false
	}
}
