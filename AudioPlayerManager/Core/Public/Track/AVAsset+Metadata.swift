//
//  AVAsset+Metadata.swift
//  AudioPlayerManager
//
//  Created by Kevin Delord on 31.05.18.
//

import AVFoundation
import MediaPlayer

public extension AVAsset {

	private enum DynamicAttribute: String {

		case duration = "duration"
		case metadata = "commonMetadata"
	}

	private func loadAttributeAsynchronously(_ attribute: DynamicAttribute, completion: (() -> Void)?) {
		self.loadValuesAsynchronously(forKeys: [attribute.rawValue], completionHandler: completion)
	}

	private func loadedAttributeValue<T>(for attribute: DynamicAttribute) -> T? {
		var error : NSError? = nil
		let status = self.statusOfValue(forKey: attribute.rawValue, error: &error)
		if let error = error {
			Log("Error loading asset value for key '\(attribute.rawValue)': \(error)")
		}

		guard (status == .loaded) else {
			return nil
		}

		return self.value(forKey: attribute.rawValue) as? T
	}

	open func loadDuration(completion: @escaping ((NSNumber?) -> Void)) {
		self.loadAttributeAsynchronously(.duration) {
			guard let durationInSeconds = self.loadedAttributeValue(for: .duration) as CMTime? else {
				DispatchQueue.main.async {
					completion(nil)
				}
				return
			}

			// Read duration from asset
			let timeInSeconds = CMTimeGetSeconds(durationInSeconds)
			// Check ig the time isn't NaN. This can happen eg. for podcasts
			let duration = ((timeInSeconds.isNaN == false) ? NSNumber(value: Float(timeInSeconds)) : nil)
			DispatchQueue.main.async {
				completion(duration)
			}
		}
	}

	open func loadMetadata(completion: @escaping (([AVMetadataItem]) -> Void)) {
		self.loadAttributeAsynchronously(.metadata) {
			let metadataItems = self.loadedAttributeValue(for: .metadata) as [AVMetadataItem]?
			DispatchQueue.main.async {
				completion(metadataItems ?? [])
			}
		}
	}
}
