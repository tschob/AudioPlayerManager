//
//  URLViewController.swift
//  Example
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import AudioPlayerManager

class URLViewController: UIViewController {

	let data = ["http://a155.phobos.apple.com/us/r2000/020/Music/v4/44/b7/4c/44b74c29-2324-a848-22dc-7c7af6d205ea/mzaf_66571212866397411.plus.aac.p.m4a",
				"http://a522.phobos.apple.com/us/r2000/019/Music4/v4/5a/3f/2e/5a3f2eaa-1f25-8507-9ca3-1671b5ed7b01/mzaf_1140962615185522552.plus.aac.p.m4a",
				"http://a1498.phobos.apple.com/us/r2000/009/Music/v4/54/8d/fb/548dfbb4-1a8c-ade9-d0cc-96381447082d/mzaf_5164804325176265340.plus.aac.p.m4a",
				"http://a1689.phobos.apple.com/us/r2000/017/Music4/v4/bd/c7/52/bdc75276-6630-5c6a-dff6-951861e066b0/mzaf_3753984811868634891.plus.aac.p.m4a",
				"http://streams.fluxfm.de/live/mp3-128/audio/play.m3u"]
}

// MARK: - UITableViewDelegate, UITableViewDatasource

extension URLViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "urlLibraryCell", for: indexPath)

		cell.textLabel?.text = self.data[indexPath.row]
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		AudioPlayerManager.shared.play(urlStrings: self.data, at: indexPath.row)
	}
}
