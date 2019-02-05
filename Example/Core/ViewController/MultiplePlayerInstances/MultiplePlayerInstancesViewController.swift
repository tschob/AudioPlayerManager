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

	fileprivate var data						: [(mediaItem: MPMediaItem, audioPlayerManager: AudioPlayerManager?)] = []

	@IBOutlet fileprivate weak var tableView: UITableView?

	override func viewDidLoad() {
		super.viewDidLoad()

		let tempData = MPMediaQuery.songs().items ?? []

		self.data = []

		for mediaItem in tempData {
			if (mediaItem.isCloudItem == false && mediaItem.assetURL != nil) {
				self.data.append((mediaItem: mediaItem, audioPlayerManager: nil))
				if (self.data.count >= 20) {
					break
				}
			}
		}

		Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTableView), userInfo: nil, repeats: true).fire()
	}

	@objc
	func updateTableView() {
		self.tableView?.reloadData()
	}
}

// MARK: - UITableView delegates

extension MultiplePlayerInstancesViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.data.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if let cell = tableView.dequeueReusableCell(withIdentifier: "multiplePlayerInstancesCell", for: indexPath) as? MultiplePlayerInstancesTableViewCell {

			let mediaItem = self.data[indexPath.row].mediaItem
			let audioPlayerManager = self.data[indexPath.row].audioPlayerManager

			cell.setup(with: mediaItem, isPlaying: (audioPlayerManager?.isPlaying() ?? false))
			return cell
		}

		return UITableViewCell()
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		var audioPlayerManager = self.data[indexPath.row].audioPlayerManager

		if (audioPlayerManager == nil) {
			audioPlayerManager = AudioPlayerManager.makeStandalonePlayer()
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
