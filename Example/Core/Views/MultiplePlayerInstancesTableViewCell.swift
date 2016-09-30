//
//  MultiplePlayerInstancesTableViewCell.swift
//  Example
//
//  Created by Hans Seiffert on 20.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import AudioPlayerManager
import MediaPlayer

class MultiplePlayerInstancesTableViewCell: UITableViewCell {

	@IBOutlet private weak var titleLabel: UILabel?
	@IBOutlet weak var playIconImageView: UIImageView?
	@IBOutlet weak var stopIconImageView: UIImageView?

	func setup(mediaItem: MPMediaItem, isPlaying: Bool) {
		self.titleLabel?.text = mediaItem.title
		self.playIconImageView?.hidden = (isPlaying == true)
		self.stopIconImageView?.hidden = (isPlaying == false)
	}
}
