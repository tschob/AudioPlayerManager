//
//  PlayerViewController.swift
//  Example
//
//  Created by Hans Seiffert on 04.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import AudioPlayer
import MediaPlayer

class PlayerViewController: UIViewController {

	@IBOutlet private weak var rewindButton: UIButton?
	@IBOutlet private weak var stopButton: UIButton?
	@IBOutlet private weak var playPauseButton: UIButton?
	@IBOutlet private weak var forwardButton: UIButton?

	@IBOutlet private weak var songLabel: UILabel?
	@IBOutlet private weak var albumLabel: UILabel?
	@IBOutlet private weak var artistLabel: UILabel?
	@IBOutlet private weak var positionLabel: UILabel?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.updateButtonStates()

		// Listen to the player state updates. This state is updated if the play, pause or queue state changed.
		AudioPlayer.sharedInstance.addPlayStateChangeCallback(self, callback: { [weak self] (playerItem: AudioPlayerItem?) in
			self?.updateButtonStates()
			self?.updateSongInformation(playerItem)
		})
		// Listen to the playback time changed. This event occurs every `AudioPlayer.PlayingTimeRefreshRate` seconds.
		AudioPlayer.sharedInstance.addPlaybackTimeChangeCallback(self, callback: { [weak self] (playerItem: AudioPlayerItem?) in
			self?.updatePlaybackTime(playerItem)
		})
	}

	deinit {
		// Stop listening to the callbacks
		AudioPlayer.sharedInstance.removePlayStateChangeCallback(self)
		AudioPlayer.sharedInstance.removePlaybackTimeChangeCallback(self)
	}

	func updateButtonStates() {
		self.rewindButton?.enabled = AudioPlayer.sharedInstance.canRewind()
		let imageName = (AudioPlayer.sharedInstance.isPlaying() == true ? "ic_pause" : "ic_play")
		self.playPauseButton?.setImage(UIImage(named: imageName), forState: .Normal)
		self.playPauseButton?.enabled = AudioPlayer.sharedInstance.canPlay()
		self.forwardButton?.enabled = AudioPlayer.sharedInstance.canForward()
	}

	func updateSongInformation(playerItem: AudioPlayerItem?) {
		self.songLabel?.text = "\((playerItem?.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String) ?? "-")"
		self.albumLabel?.text = "\((playerItem?.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as? String) ?? "-")"
		self.artistLabel?.text = "\((playerItem?.nowPlayingInfo?[MPMediaItemPropertyArtist] as? String) ?? "-")"
		self.updatePlaybackTime(playerItem)
	}

	func updatePlaybackTime(playerItem: AudioPlayerItem?) {
		self.positionLabel?.text = "\(playerItem?.displayablePlaybackTimeString() ?? "-")/\(playerItem?.displayableDurationString() ?? "-")"
	}
}

// MARK: - IBActions

extension PlayerViewController {

	@IBAction func didPressRewindButton(sender: AnyObject) {
		AudioPlayer.sharedInstance.rewind()
	}

	@IBAction func didPressStopButton(sender: AnyObject) {
		AudioPlayer.sharedInstance.stop()
	}

	@IBAction func didPressPlayPauseButton(sender: AnyObject) {
		AudioPlayer.sharedInstance.togglePlayPause()
	}

	@IBAction func didPressForwardButton(sender: AnyObject) {
		AudioPlayer.sharedInstance.forward()
	}
}
