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

	public func play(urlString string: String) {
		self.play(url: URL(string: string))
	}

	public func play(urlStrings strings: [String], at startIndex: Int) {
		self.play(urls: AudioURLTrack.convertToURLs(strings), at: startIndex)
	}

	public func play(url urlToPlay: URL?) {
		if let _track = AudioURLTrack(url: urlToPlay) {
			self.play(_track)
		}
	}

	public func play(urls urlsToPlay: [URL?], at startIndex: Int) {
		// Play the first track directly and add the other tracks to the queue in the background
		if let firstPlayableItem = AudioURLTrack.firstPlayableItem(urlsToPlay, at: startIndex) {
			// Play the first track directly
			self.play(firstPlayableItem.track)
			// Split the tracks into an array which contain the ones which have to be prepended and appended to queue
			var urlsToPrepend = Array(urlsToPlay)
			if (firstPlayableItem.index > 0) {
				// If the index of the first playable URL is greater than 0 there are URL to prepend
				urlsToPrepend.removeSubrange(firstPlayableItem.index..<urlsToPrepend.count)
			}
			var urlsToAppend = Array(urlsToPlay)
			urlsToAppend.removeSubrange(0..<(firstPlayableItem.index + 1))
			// Append the remaining URL to the queue in the background
			// As the creation of the tracks takes some time, we avoid a blocked UI
			self.addToQueueInBackground(prepend: urlsToPrepend, append: urlsToAppend, to: self.queueGeneration)
		}
	}

	fileprivate func addToQueueInBackground(prepend urlsToPrepend: [URL?], append urlsToAppend: [URL?], to queueGeneration: Int) {
		DispatchQueue.global().async {
			let itemsToPrepend = AudioURLTrack.makeTracks(of: urlsToPrepend, withStartIndex: 0)
			let itemsToAppend = AudioURLTrack.makeTracks(of: urlsToAppend, withStartIndex: 0)
			DispatchQueue.main.async {
				self.prepend(itemsToPrepend.tracks, toQueue: queueGeneration)
				self.append(itemsToAppend.tracks, toQueue: queueGeneration)
			}
		}
	}

	// MARK: - Helper

	public func isPlaying(urlString string: String) -> Bool {
		return self.isPlaying(url: URL(string: string))
	}

	public func isPlaying(url urlToCheck: URL?) -> Bool {
		return (self.isPlaying() == true && self.currentTrack?.identifier() == urlToCheck?.absoluteString)
	}
}
