//
//  HSEPlayerViewController.swift
//  Example
//
//  Created by Hans Seiffert on 04.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import HSAudioPlayer
import MediaPlayer

class HSEPlayerViewController: UIViewController {

	@IBOutlet private weak var rewindButton		: UIButton?
	@IBOutlet private weak var stopButton		: UIButton?
	@IBOutlet private weak var playPauseButton	: UIButton?
	@IBOutlet private weak var forwardButton	: UIButton?

	@IBOutlet private weak var songLabel		: UILabel?
	@IBOutlet private weak var albumLabel		: UILabel?
	@IBOutlet private weak var artistLabel		: UILabel?
	@IBOutlet private weak var positionLabel	: UILabel?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.updateButtonStates()

		// Listen to the player state updates. This state is updated if the play, pause or queue state changed.
		HSAudioPlayer.sharedInstance.addPlayStateChangeCallback(self, callback: { [weak self] (playerItem: HSAudioPlayerItem?) in
			self?.updateButtonStates()
			self?.updateSongInformation(playerItem)
		})
		// Listen to the playback time changed. This event occurs every `HSAudioPlayer.PlayingTimeRefreshRate` seconds.
		HSAudioPlayer.sharedInstance.addPlaybackTimeChangeCallback(self, callback: { [weak self] (playerItem: HSAudioPlayerItem?) in
			self?.updatePlaybackTime(playerItem)
		})
	}

	deinit {
		// Stop listening to the callbacks
		HSAudioPlayer.sharedInstance.removePlayStateChangeCallback(self)
		HSAudioPlayer.sharedInstance.removePlaybackTimeChangeCallback(self)
	}

	func updateButtonStates() {
		self.rewindButton?.enabled = HSAudioPlayer.sharedInstance.canRewind()
		let imageName = (HSAudioPlayer.sharedInstance.isPlaying() == true ? "ic_pause" : "ic_play")
		self.playPauseButton?.setImage(UIImage(named: imageName), forState: .Normal)
		self.playPauseButton?.enabled = HSAudioPlayer.sharedInstance.canPlay()
		self.forwardButton?.enabled = HSAudioPlayer.sharedInstance.canForward()
	}

	func updateSongInformation(playerItem: HSAudioPlayerItem?) {
		self.songLabel?.text = "\((playerItem?.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String) ?? "-")"
		self.albumLabel?.text = "\((playerItem?.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as? String) ?? "-")"
		self.artistLabel?.text = "\((playerItem?.nowPlayingInfo?[MPMediaItemPropertyArtist] as? String) ?? "-")"
		self.updatePlaybackTime(playerItem)
	}

	func updatePlaybackTime(playerItem: HSAudioPlayerItem?) {
		self.positionLabel?.text = "\(playerItem?.displayablePlaybackTimeString() ?? "-")/\(playerItem?.displayableDurationString() ?? "-")"
	}
}

// MARK: - IBActions

extension HSEPlayerViewController {

	@IBAction func didPressRewindButton(sender: AnyObject) {
		HSAudioPlayer.sharedInstance.rewind()
	}

	@IBAction func didPressStopButton(sender: AnyObject) {
		HSAudioPlayer.sharedInstance.stop()
	}

	@IBAction func didPressPlayPauseButton(sender: AnyObject) {
		HSAudioPlayer.sharedInstance.togglePlayPause()
	}

	@IBAction func didPressForwardButton(sender: AnyObject) {
		HSAudioPlayer.sharedInstance.forward()
	}
}
