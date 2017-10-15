//
//  MusicLibraryViewController.swift
//  Example
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import AudioPlayerManager
import MediaPlayer

class MusicLibraryViewController: UIViewController {

	var data = [MPMediaItem]()

	override func viewDidLoad() {
		super.viewDidLoad()

		AudioPlayerManager.shared.setup()

		let tempData = MPMediaQuery.songs().items ?? []
		self.data = []
		for mediaItem in tempData {
			if (mediaItem.isCloudItem == false && mediaItem.assetURL != nil) {
				self.data.append(mediaItem)
				if (self.data.count >= 20) {
					break
				}
			}
		}
	}
}

// MARK: - UITableView delegates

extension MusicLibraryViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.data.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "musicLibraryCell", for: indexPath)
		cell.textLabel?.text = self.data[indexPath.row].title
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		AudioPlayerManager.shared.play(mediaItems: self.data, at: indexPath.row)
	}
}
