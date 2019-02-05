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

	public func play(mediaItem item: MPMediaItem) {
		if let track = MediaPlayerTrack(mediaItem: item) {
			self.play(track)
		}
	}

	public func play(mediaItems items: [MPMediaItem], at startIndex: Int) {
		// Play first track directly and add the other tracks to the queue in the background
		if let firstPlayableItem = MediaPlayerTrack.firstPlayable(items, startIndex: startIndex) {
			// Play the first track directly
			self.play(firstPlayableItem.track)
			// Split the tracks into array which contain the ones which have to be prepended and appended them to the queue
			var tracksToPrepend = Array(items)
			tracksToPrepend.removeSubrange(firstPlayableItem.index..<tracksToPrepend.count)
			var tracksToAppend = Array(items)
			tracksToAppend.removeSubrange(0..<(firstPlayableItem.index + 1))
			// Append the remaining tracks to the queue in the background
			// As the creation of the tracks takes some time, we avoid a blocked UI
			self.addToQueueInBackground(prepend: tracksToPrepend, append: tracksToAppend, queueGeneration: self.queueGeneration)
		}
	}

	fileprivate func addToQueueInBackground(prepend mediaItemsToPrepend: [MPMediaItem], append mediaItemsToAppend: [MPMediaItem], queueGeneration: Int) {
		DispatchQueue.global().async {
			let itemsToPrepend = MediaPlayerTrack.makeTracks(of: mediaItemsToPrepend, withStartIndex: 0)
			let itemsToAppend = MediaPlayerTrack.makeTracks(of: mediaItemsToAppend, withStartIndex: 0)
			DispatchQueue.main.async {
				self.prepend(itemsToPrepend.tracks, toQueue: queueGeneration)
				self.append(itemsToAppend.tracks, toQueue: queueGeneration)
			}
		}
	}

	// MARK: - Helper

	public func isPlaying(mediaItem item: MPMediaItem) -> Bool {
		return self.isPlaying(persistentID: item.persistentID)
	}

	public func isPlaying(mediaItemCollection collection: MPMediaItemCollection) -> Bool {
		for mediaItem in collection.items {
			if (self.isPlaying(mediaItem: mediaItem) == true) {
				return true
			}
		}
		return false
	}

	public func isPlaying(persistentID pid: MPMediaEntityPersistentID) -> Bool {
		if (self.isPlaying() == true),
			let currentTrack = self.currentTrack as? MediaPlayerTrack {
			return ("\(pid)" == currentTrack.identifier())
		}
		return false
	}
}
