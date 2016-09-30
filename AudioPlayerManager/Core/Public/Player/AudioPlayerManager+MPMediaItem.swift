//
//  AudioPlayerManager+MPMediaItem.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//
import MediaPlayer

extension AudioPlayerManager {

	// MARK: - Play

	public func play(mediaItem mediaItem: MPMediaItem) {
		if let _track = MediaPlayerTrack(mediaItem: mediaItem) {
			self.play(_track)
		}
	}

	public func play(mediaItems mediaItems: [MPMediaItem], startIndex: Int) {
		// Play first track directly and add the other tracks to the queue in the background
		if let firstPlayableItem = MediaPlayerTrack.firstPlayable(mediaItems, startIndex: startIndex) {
			// Play the first track directly
			self.play(firstPlayableItem.track)
			// Split the tracks into array which contain the ones which have to be prepended and appended them to the queue
			var tracksToPrepend = Array(mediaItems)
			tracksToPrepend.removeRange(firstPlayableItem.index..<tracksToPrepend.count)
			var tracksToAppend = Array(mediaItems)
			tracksToAppend.removeRange(0..<(firstPlayableItem.index + 1))
			// Append the remaining tracks to the queue in the background
			// As the creation of the tracks takes some time, we avoid a blocked UI
			self.addToQueueInBackground(prepend: tracksToPrepend, append: tracksToAppend, queueGeneration: self.queueGeneration)
		}
	}

	private func addToQueueInBackground(prepend mediaItemsToPrepend: [MPMediaItem], append mediaItemsToAppend: [MPMediaItem], queueGeneration: Int) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let itemsToPrepend = MediaPlayerTrack.items(mediaItemsToPrepend, startIndex: 0)
			let itemsToAppend = MediaPlayerTrack.items(mediaItemsToAppend, startIndex: 0)
			dispatch_async(dispatch_get_main_queue()) {
				self.prepend(itemsToPrepend.tracks, queueGeneration: queueGeneration)
				self.append(itemsToAppend.tracks, queueGeneration: queueGeneration)
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
			let _currentTrack = self.currentTrack as? MediaPlayerTrack {
			return ("\(persistentID)" == _currentTrack.identifier())
		}
		return false
	}
}
