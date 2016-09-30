//
//  MultiplePlayerInstancesViewController.swift
//  Example
//
//  Created by Hans Seiffert on 20.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import AudioPlayerManager
import MediaPlayer

class MultiplePlayerInstancesViewController: UIViewController {

	private var data						: [(mediaItem: MPMediaItem, audioPlayerManager: AudioPlayerManager?)] = []

	@IBOutlet private weak var tableView: UITableView?

	override func viewDidLoad() {
		super.viewDidLoad()

		let tempData = MPMediaQuery.songsQuery().items ?? []
		self.data = []
		for mediaItem in tempData {
			if (mediaItem.cloudItem == false && mediaItem.assetURL != nil) {
				self.data.append((mediaItem: mediaItem, audioPlayerManager: nil))
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

extension MultiplePlayerInstancesViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.data.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

		if let _cell = tableView.dequeueReusableCellWithIdentifier("multiplePlayerInstancesCell", forIndexPath: indexPath) as? MultiplePlayerInstancesTableViewCell {
			let _mediItem = self.data[indexPath.row].mediaItem
			let audioPlayerManager = self.data[indexPath.row].audioPlayerManager
			_cell.setup(_mediItem, isPlaying: (audioPlayerManager?.isPlaying() ?? false))
			return _cell
		}
		return UITableViewCell()
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		var audioPlayerManager = self.data[indexPath.row].audioPlayerManager
		if (audioPlayerManager == nil) {
			audioPlayerManager = AudioPlayerManager.standaloneInstance()
			audioPlayerManager?.setup()
			audioPlayerManager?.useRemoteControlEvents = false
			audioPlayerManager?.useNowPlayingInfoCenter = false
			self.data[indexPath.row].audioPlayerManager = audioPlayerManager
		}
		if (audioPlayerManager?.isPlaying() == true) {
			audioPlayerManager?.stop()
		} else {
			audioPlayerManager?.play(mediaItem: self.data[indexPath.row].mediaItem)
		}
	}
}
