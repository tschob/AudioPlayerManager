//
//  HSAudioPlayer+URL.swift
//  HSAudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//
import MediaPlayer

extension HSAudioPlayer {

	// MARK: - Play

	public func play(urlString urlString: String) {
		self.play(url: NSURL(string: urlString))
	}

	public func play(urlStrings urlStrings: [String], startPosition: Int) {
		self.play(urls: HSURLAudioPlayerItem.convertToURLs(urlStrings), startPosition: startPosition)
	}

	public func play(url url: NSURL?) {
		if let _playerItem = HSURLAudioPlayerItem(url: url) {
			self.play(_playerItem)
		}
	}

	public func play(urls urls: [NSURL?], startPosition: Int) {
		// Play the first item directly and add the other items to the queue in the background
		if let firstPlayableItem = HSURLAudioPlayerItem.firstPlayableItem(urls, startPosition: startPosition) {
			// Play the first item directly
			self.play(firstPlayableItem.playerItem)
			// Split the items into array which contain the ones which have to be prepended and appended to queue
			var urlsToPrepend = Array(urls)
			if (firstPlayableItem.index > 0) {
				// If the index of the first playable item is greater than 0 there are items to prepend
				urlsToPrepend.removeRange(firstPlayableItem.index..<urlsToPrepend.count)
			}
			var urlsToAppend = Array(urls)
			urlsToAppend.removeRange(0..<(firstPlayableItem.index + 1))
			// Append the remaining urls to queue in the background
			// As the creation of the player items takes some time, we avoid a blocked UI
			self.addToQueueInBackground(prepend: urlsToPrepend, append: urlsToAppend, queueGeneration: self.queueGeneration)
		}
	}

	private func addToQueueInBackground(prepend urlsToPrepend: [NSURL?], append urlsToAppend: [NSURL?], queueGeneration: Int) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let itemsToPrepend = HSURLAudioPlayerItem.playerItems(urlsToPrepend, startPosition: 0)
			let itemsToAppend = HSURLAudioPlayerItem.playerItems(urlsToAppend, startPosition: 0)
			dispatch_async(dispatch_get_main_queue()) {
				self.prepend(itemsToPrepend.playerItems, queueGeneration: queueGeneration)
				self.append(itemsToAppend.playerItems, queueGeneration: queueGeneration)
			}
		}
	}

	// MARK: - Helper

	public func isPlaying(urlString urlString: String) -> Bool {
		return self.isPlaying(url: NSURL(string: urlString))
	}

	public func isPlaying(url url: NSURL?) -> Bool {
		return (self.isPlaying() == true && self.currentPlayerItem()?.identifier() == url?.absoluteString)
	}
}
