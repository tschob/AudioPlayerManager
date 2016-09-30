//
//  HSMediaItemAudioPlayerItem.swift
//  AudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public class HSMediaItemAudioPlayerItem: AudioPlayerItem {

	// MARK: - Properties

	public var mediaItem					: MPMediaItem?

	public var mediaItemPersitentID			: MPMediaEntityPersistentID?

	// MARK: - Initialization

	public convenience init?(mediaItemPersitentID: UInt64) {
		self.init()
		self.mediaItemPersitentID = mediaItemPersitentID
	}

	public convenience init?(mediaItem: MPMediaItem) {
		guard mediaItem.isPlayable() == true else {
			return nil
		}
		self.init(mediaItemPersitentID: mediaItem.persistentID)
		self.mediaItem = mediaItem
	}

	public class func playerItems(mediaItems: [MPMediaItem], startPosition: Int) -> (items: [HSMediaItemAudioPlayerItem], startPosition: Int) {
		var reducedPlayerItems = [HSMediaItemAudioPlayerItem]()
		var updatedPosition = startPosition
		for index in 0..<mediaItems.count {
			let mediaItem = mediaItems[index]
			if let _playerItem = HSMediaItemAudioPlayerItem(mediaItem: mediaItem) {
				reducedPlayerItems.append(_playerItem)
			} else if (index <= startPosition && updatedPosition > 0) {
				updatedPosition -= 1
			}
		}
		return (items: reducedPlayerItems, startPosition: updatedPosition)
	}

	// MARK: - Lifecycle

	public override func loadResource() {
		if let _mediaItemPersitentID = self.mediaItemPersitentID {
			self.mediaItem = HSMediaLibraryHelper.mediaItem(persistentID: _mediaItemPersitentID)
		}
	}

	public override func getAVPlayerItem() -> AVPlayerItem? {
		if let _url = self.mediaItem?.assetURL {
			return AVPlayerItem(URL: _url)
		}
		return nil
	}

	// MARK: - Now playing info

	public override func initNowPlayingInfo() {
		super.initNowPlayingInfo()

		if let title = self.mediaItem?.title {
			self.nowPlayingInfo?[MPMediaItemPropertyTitle] = title
		}
		if let artistName = self.mediaItem?.artist {
			self.nowPlayingInfo?[MPMediaItemPropertyArtist] = artistName
		}
		if let albumTitle = self.mediaItem?.albumTitle {
			self.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = albumTitle
		}
		if let albumCover = self.mediaItem?.artwork {
			self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = albumCover
		}
	}

	// MARK: - Helper

	public override func isPlayable() -> Bool {
		return self.mediaItem?.isPlayable() ?? true
	}

	public class func firstPlayableItem(mediaItems: [MPMediaItem], startPosition: Int) -> (playerItem: HSMediaItemAudioPlayerItem, index: Int)? {
		// Iterate through all media items
		for index in startPosition..<mediaItems.count {
			let mediaItem = mediaItems[index]
			// Check whether it's playable
			if (mediaItem.isPlayable() == true) {
				// Create the player item from the first playable item and return it.
				if let _playerItem = HSMediaItemAudioPlayerItem(mediaItem: mediaItem) {
					return (playerItem: _playerItem, index: index)
				}
			}
		}
		// There is no playable media item -> reuturn nil then
		return nil
	}

	public override func identifier() -> String? {
		if let _mediaItemPersitentID = self.mediaItemPersitentID {
			return "\(_mediaItemPersitentID)"
		}
		return super.identifier()
	}
}
