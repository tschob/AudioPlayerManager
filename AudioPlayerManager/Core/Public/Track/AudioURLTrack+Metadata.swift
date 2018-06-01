//
//  AudioURLTrack+Metadata.swift
//  AudioPlayerManager
//
//  Created by Kevin Delord on 31.05.18.
//

import AVFoundation
import MediaPlayer

// MARK: - Metadata

extension AudioURLTrack {

	internal func extractMetadata() {
		Log("Extracting meta data of player item with url: \(self.url)")
		self.playerItem?.asset.load(.commonMetadata, completion: { [weak self] (items: [AVMetadataItem]) in
			let parsedMetadata = self?.parseMetadataItems(items)
			self?.nowPlayingInfo?.merge((parsedMetadata ?? [:]), uniquingKeysWith: { (_, new) -> NSObject in
				return new
			})

			// Inform the player about the updated meta data
			AudioPlayerManager.shared.didUpdateMetadata()
		})
	}

	/// Extract necessary info from loaded metadata items.
	/// By default only the Title, AlbumName, Artist and Artwork values will be kept.
	/// Override to add any other metadata.
	///
	/// - Parameter items: Array of fully loaded metadata items.
	/// - Returns: Dictionary for metadata key values.
	open func parseMetadataItems(_ items: [AVMetadataItem]) -> [String: NSObject] {
		var info = [String: NSObject]()
		for metadataItem in items {
			if let key = metadataItem.commonKey {
				switch key {
				case AVMetadataCommonKeyTitle		: info[MPMediaItemPropertyTitle] = metadataItem.stringValue as NSObject?
				case AVMetadataCommonKeyAlbumName	: info[MPMediaItemPropertyAlbumTitle] = metadataItem.stringValue as NSObject?
				case AVMetadataCommonKeyArtist		: info[MPMediaItemPropertyArtist] = metadataItem.stringValue as NSObject?
				case AVMetadataCommonKeyArtwork		: info[MPMediaItemPropertyArtwork] = self.mediaItemArtwork(from: metadataItem.dataValue)
				default								: continue
				}
			}
		}

		return info
	}

	fileprivate func mediaItemArtwork(from data: Data?) -> MPMediaItemArtwork? {
		guard
			let data = data,
			let image = UIImage(data: data) else {
				return nil
		}

		if #available(iOS 10.0, *) {
			return MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (size: CGSize) -> UIImage in
				return image
			})
		} else {
			return MPMediaItemArtwork(image: image)
		}
	}
}
