//
//  AudioPlayerManager+RemoteControl.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit

extension AudioPlayerManager {

	public func remoteControlReceivedWithEvent(_ event: UIEvent?) {
		if let event = event {
			switch event.subtype {
			case UIEvent.EventSubtype.remoteControlPlay:
				self.play()
			case UIEvent.EventSubtype.remoteControlPause:
				self.pause()
			case UIEvent.EventSubtype.remoteControlNextTrack:
				self.forward()
			case UIEvent.EventSubtype.remoteControlPreviousTrack:
				self.rewind()
			case UIEvent.EventSubtype.remoteControlTogglePlayPause:
				self.togglePlayPause()
			default:
				break
			}
		}
	}
}
