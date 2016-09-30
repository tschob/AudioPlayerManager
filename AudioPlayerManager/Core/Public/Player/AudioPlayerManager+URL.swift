//
//  AudioPlayerManager+URL.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//
import MediaPlayer

extension AudioPlayerManager {

	// MARK: - Play

	public func play(urlString urlString: String) {
		self.play(url: NSURL(string: urlString))
	}

	public func play(urlStrings urlStrings: [String], startIndex: Int) {
		self.play(urls: AudioURLTrack.convertToURLs(urlStrings), startIndex: startIndex)
	}

	public func play(url url: NSURL?) {
		if let _track = AudioURLTrack(url: url) {
			self.play(_track)
		}
	}

	public func play(urls urls: [NSURL?], startIndex: Int) {
		// Play the first track directly and add the other tracks to the queue in the background
		if let firstPlayableItem = AudioURLTrack.firstPlayableItem(urls, startIndex: startIndex) {
			// Play the first track directly
			self.play(firstPlayableItem.track)
			// Split the tracks into an array which contain the ones which have to be prepended and appended to queue
			var urlsToPrepend = Array(urls)
			if (firstPlayableItem.index > 0) {
				// If the index of the first playable URL is greater than 0 there are URL to prepend
				urlsToPrepend.removeRange(firstPlayableItem.index..<urlsToPrepend.count)
			}
			var urlsToAppend = Array(urls)
			urlsToAppend.removeRange(0..<(firstPlayableItem.index + 1))
			// Append the remaining URL to the queue in the background
			// As the creation of the tracks takes some time, we avoid a blocked UI
			self.addToQueueInBackground(prepend: urlsToPrepend, append: urlsToAppend, queueGeneration: self.queueGeneration)
		}
	}

	private func addToQueueInBackground(prepend urlsToPrepend: [NSURL?], append urlsToAppend: [NSURL?], queueGeneration: Int) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let itemsToPrepend = AudioURLTrack.items(urlsToPrepend, startIndex: 0)
			let itemsToAppend = AudioURLTrack.items(urlsToAppend, startIndex: 0)
			dispatch_async(dispatch_get_main_queue()) {
				self.prepend(itemsToPrepend.tracks, queueGeneration: queueGeneration)
				self.append(itemsToAppend.tracks, queueGeneration: queueGeneration)
			}
		}
	}

	// MARK: - Helper

	public func isPlaying(urlString urlString: String) -> Bool {
		return self.isPlaying(url: NSURL(string: urlString))
	}

	public func isPlaying(url url: NSURL?) -> Bool {
		return (self.isPlaying() == true && self.currentTrack?.identifier() == url?.absoluteString)
	}
}
