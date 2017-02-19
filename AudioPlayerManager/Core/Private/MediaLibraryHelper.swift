//
//  HSMediaLibraryHelper.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import MediaPlayer

class HSMediaLibraryHelper: NSObject {

	class func mediaItem(persistentID: MPMediaEntityPersistentID) -> MPMediaItem? {
		let predicate = MPMediaPropertyPredicate(value: NSNumber(value: persistentID as UInt64), forProperty: MPMediaItemPropertyPersistentID, comparisonType: .equalTo)
		let predicates : Set = [predicate]
		return MPMediaQuery(filterPredicates: predicates).items?.first
	}
}
