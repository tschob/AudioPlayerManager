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

	class func mediaItem(persistentID persistentID: MPMediaEntityPersistentID) -> MPMediaItem? {
		let predicate = MPMediaPropertyPredicate(value: NSNumber(unsignedLongLong: persistentID), forProperty: MPMediaItemPropertyPersistentID, comparisonType: .EqualTo)
		return MPMediaQuery(filterPredicates: Set(arrayLiteral: predicate)).items?.first
	}
}
