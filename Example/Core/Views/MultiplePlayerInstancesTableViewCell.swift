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

	@IBOutlet fileprivate weak var titleLabel			: UILabel?
	@IBOutlet fileprivate weak var playIconImageView	: UIImageView?
	@IBOutlet fileprivate weak var stopIconImageView	: UIImageView?

	func setup(with mediaItem: MPMediaItem, isPlaying: Bool) {
		self.titleLabel?.text = mediaItem.title
		self.playIconImageView?.isHidden = (isPlaying == true)
		self.stopIconImageView?.isHidden = (isPlaying == false)
	}
}
