//
//  HSEMultiplePlayerInstancesViewController.swift
//  Example
//
//  Created by Hans Seiffert on 20.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import HSAudioPlayer
import MediaPlayer

class HSEMultiplePlayerInstancesViewController: UIViewController {

	private var data						: [(mediaItem: MPMediaItem, audioPlayer: HSAudioPlayer?)] = []

	@IBOutlet private weak var tableView	: UITableView?

	override func viewDidLoad() {
		super.viewDidLoad()

		let tempData = MPMediaQuery.songsQuery().items ?? []
		self.data = []
		for mediaItem in tempData {
			if (mediaItem.cloudItem == false && mediaItem.assetURL != nil) {
				self.data.append((mediaItem: mediaItem, audioPlayer: nil))
				if (self.data.count >= 20) {
					break
				}
			}
		}

		NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(updateTableView), userInfo: nil, repeats: true).fire()
	}

	func updateTableView() {
		self.tableView?.reloadData()
	}
}

// MARK: - UITableView delegates

extension HSEMultiplePlayerInstancesViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.data.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

		if let _cell = tableView.dequeueReusableCellWithIdentifier("multiplePlayerInstancesCell", forIndexPath: indexPath) as? HSEMultiplePlayerInstancesTableViewCell {
			let _mediItem = self.data[indexPath.row].mediaItem
			let audioPlayer = self.data[indexPath.row].audioPlayer
			_cell.setup(_mediItem, isPlaying: (audioPlayer?.isPlaying() ?? false))
			return _cell
		}
		return UITableViewCell()
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		var audioPlayer = self.data[indexPath.row].audioPlayer
		if (audioPlayer == nil) {
			audioPlayer = HSAudioPlayer.audioPlayer()
			audioPlayer?.useRemoteControlEvents = false
			audioPlayer?.useNowPlayingInfoCenter = false
			self.data[indexPath.row].audioPlayer = audioPlayer
		}
		if (audioPlayer?.isPlaying() == true) {
			audioPlayer?.stop()
		} else {
			audioPlayer?.play(mediaItem: self.data[indexPath.row].mediaItem)
		}
	}
}
