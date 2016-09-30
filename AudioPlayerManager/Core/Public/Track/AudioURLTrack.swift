//
//  AudioURLTrack.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public class AudioURLTrack: AudioTrack {

	// MARK: - Properties

	public var url		: NSURL?

	// MARK: - Initialization

	public convenience init?(urlString: String) {
		self.init(url: NSURL(string: urlString))
	}

	public convenience init?(url: NSURL?) {
		guard url != nil else {
			return nil
		}
		self.init()
		self.url = url
	}

	public class func items(urlStrings: [String], startIndex: Int) -> (tracks: [AudioURLTrack], startIndex: Int) {
		return self.items(AudioURLTrack.convertToURLs(urlStrings), startIndex: startIndex)
	}

	public class func items(urls: [NSURL?], startIndex: Int) -> (tracks: [AudioURLTrack], startIndex: Int) {
		var reducedTracks = [AudioURLTrack]()
		var reducedStartIndex = startIndex
		// Iterate through all given URLs and create the tracks
		for index in 0..<urls.count {
			let _url = urls[index]
			if let _playerItem = AudioURLTrack(url: _url) {
				reducedTracks.append(_playerItem)
			} else if (index <= startIndex && reducedStartIndex > 0) {
				// There is a problem with the URL. Ignore the URL and shift the start index if it is higher than the current index
				reducedStartIndex -= 1
			}
		}
		return (tracks: reducedTracks, startIndex: reducedStartIndex)
	}

	// MARK: - Lifecycle

	override func prepareForPlaying(avPlayerItem: AVPlayerItem) {
		super.prepareForPlaying(avPlayerItem)
		// Listen to the timedMetadata initialization. We can extract the meta data then
		self.playerItem?.addObserver(self, forKeyPath: Keys.TimedMetadata, options: NSKeyValueObservingOptions.Initial, context: nil)
	}

	override func cleanupAfterPlaying() {
		// Remove the timedMetadata observer as the AVPlayerItem will be released now
		self.playerItem?.removeObserver(self, forKeyPath: Keys.TimedMetadata, context: nil)
		super.cleanupAfterPlaying()
	}

	public override func getPlayerItem() -> AVPlayerItem? {
		if let _url = self.url {
			return AVPlayerItem(URL: _url)
		}
		return nil
	}

	// MARK: - Now playing info

	public override func initNowPlayingInfo() {
		super.initNowPlayingInfo()

		self.nowPlayingInfo?[MPMediaItemPropertyTitle] = self.url?.lastPathComponent
	}

	// MARK: - Helper

	public override func identifier() -> String? {
		if let _urlAbsoluteString = self.url?.absoluteString {
			return _urlAbsoluteString
		}
		return super.identifier()
	}

	public class func convertToURLs(strings: [String]) -> [NSURL?] {
		var urls: [NSURL?] = []
		for string in strings {
			urls.append(NSURL(string: string))
		}
		return urls
	}

	public class func firstPlayableItem(urls: [NSURL?], startIndex: Int) -> (track: AudioURLTrack, index: Int)? {
		// Iterate through all URLs and check whether it's not nil
		for index in startIndex..<urls.count {
			if let _track = AudioURLTrack(url: urls[index]) {
				// Create the track from the first playable URL and return it.
				return (track: _track, index: index)
			}
		}
		// There is no playable URL -> reuturn nil then
		return nil
	}

	// MARK: - PRIVATE -

	private struct Keys {
		static let TimedMetadata		= "timedMetadata"
	}

	private func extractMetadata() {
		Log("Extracting meta data of player item with url: \(url)")
		for metadataItem in (self.playerItem?.asset.commonMetadata ?? []) {
			if let _key = metadataItem.commonKey {
				switch _key {
				case AVMetadataCommonKeyTitle		: self.nowPlayingInfo?[MPMediaItemPropertyTitle] = metadataItem.stringValue
				case AVMetadataCommonKeyAlbumName	: self.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = metadataItem.stringValue
				case AVMetadataCommonKeyArtist		: self.nowPlayingInfo?[MPMediaItemPropertyArtist] = metadataItem.stringValue
				case AVMetadataCommonKeyArtwork		:
					if let
						_data = metadataItem.dataValue,
						_image = UIImage(data: _data) {
						self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: _image)
					}
				default								: continue
				}
			}
		}
		// Inform the player about the updated meta data
		AudioPlayerManager.sharedInstance.didUpdateMetadata()
	}
}

// MARK: - KVO

extension AudioURLTrack {

	override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if (keyPath == Keys.TimedMetadata) {
			// Extract the meta data if the timedMetadata changed
			self.extractMetadata()
		}
	}

}
