//
//  MPMediaItem+HSAudioPlayer.swift
//  HSAudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import MediaPlayer

extension MPMediaItem {

	/**
	Checks whether the item is a cloud item and if the asset URL is existing.

	- returns: A `Bool` which is true if the item is playable (the item isn't a cloud item and the asset URL exists.)
	*/
	public func isPlayable() -> Bool {
		return (self.cloudItem == false && self.assetURL != nil)
	}
}
