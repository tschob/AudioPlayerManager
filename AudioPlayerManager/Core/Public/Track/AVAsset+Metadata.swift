//
//  AVAsset+Metadata.swift
//  AudioPlayerManager
//
//  Created by Kevin Delord on 31.05.18.
//

import AVFoundation

public enum DynamicAttribute {

	case duration
	case commonMetadata
	case metadata

	var key: String {
		switch self {
		case .duration			: return "duration"
		case .commonMetadata	: return "commonMetadata"
		case .metadata			: return "metadata"
		}
	}
}

public extension AVAsset {

	private func loadAttributeAsynchronously(_ attribute: DynamicAttribute, completion: (() -> Void)?) {
		self.loadValuesAsynchronously(forKeys: [attribute.key], completionHandler: completion)
	}

	private func loadedAttributeValue<T>(for attribute: DynamicAttribute) -> T? {
		var error : NSError?
		let status = self.statusOfValue(forKey: attribute.key, error: &error)
		if let error = error {
			log("Error loading asset value for key '\(attribute.key)': \(error)")
		}

		guard (status == .loaded) else {
			return nil
		}

		return self.value(forKey: attribute.key) as? T
	}

	public func loadDuration(completion: @escaping ((_ duration: NSNumber?) -> Void)) {
		self.loadAttributeAsynchronously(.duration) {
			guard let durationInSeconds = self.loadedAttributeValue(for: .duration) as CMTime? else {
				DispatchQueue.main.async {
					completion(nil)
				}
				return
			}

			// Read duration from asset
			let timeInSeconds = CMTimeGetSeconds(durationInSeconds)
			// Check if the time isn't NaN. This can happen eg. for podcasts
			let duration = ((timeInSeconds.isNaN == false) ? NSNumber(value: Float(timeInSeconds)) : nil)
			DispatchQueue.main.async {
				completion(duration)
			}
		}
	}

	public func load(_ attribute: DynamicAttribute, completion: @escaping ((_ items: [AVMetadataItem]) -> Void)) {
		self.loadAttributeAsynchronously(attribute) {
			let metadataItems = self.loadedAttributeValue(for: attribute) as [AVMetadataItem]?
			DispatchQueue.main.async {
				completion(metadataItems ?? [])
			}
		}
	}
}
