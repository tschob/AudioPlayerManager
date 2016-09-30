//
//  PlayerViewController.swift
//  Example
//
//  Created by Hans Seiffert on 04.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit
import AudioPlayerManager
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
		AudioPlayerManager.sharedInstance.addPlayStateChangeCallback(self, callback: { [weak self] (track: AudioTrack?) in
			self?.updateButtonStates()
			self?.updateSongInformation(track)
		})
		// Listen to the playback time changed. This event occurs every `AudioPlayerManager.PlayingTimeRefreshRate` seconds.
		AudioPlayerManager.sharedInstance.addPlaybackTimeChangeCallback(self, callback: { [weak self] (track: AudioTrack?) in
			self?.updatePlaybackTime(track)
		})
	}

	deinit {
		// Stop listening to the callbacks
		AudioPlayerManager.sharedInstance.removePlayStateChangeCallback(self)
		AudioPlayerManager.sharedInstance.removePlaybackTimeChangeCallback(self)
	}

	func updateButtonStates() {
		self.rewindButton?.enabled = AudioPlayerManager.sharedInstance.canRewind()
		let imageName = (AudioPlayerManager.sharedInstance.isPlaying() == true ? "ic_pause" : "ic_play")
		self.playPauseButton?.setImage(UIImage(named: imageName), forState: .Normal)
		self.playPauseButton?.enabled = AudioPlayerManager.sharedInstance.canPlay()
		self.forwardButton?.enabled = AudioPlayerManager.sharedInstance.canForward()
	}

	func updateSongInformation(track: AudioTrack?) {
		self.songLabel?.text = "\((track?.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String) ?? "-")"
		self.albumLabel?.text = "\((track?.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as? String) ?? "-")"
		self.artistLabel?.text = "\((track?.nowPlayingInfo?[MPMediaItemPropertyArtist] as? String) ?? "-")"
		self.updatePlaybackTime(track)
	}

	func updatePlaybackTime(track: AudioTrack?) {
		self.positionLabel?.text = "\(track?.displayablePlaybackTimeString() ?? "-")/\(track?.displayableDurationString() ?? "-")"
	}
}

// MARK: - IBActions

extension PlayerViewController {

	@IBAction func didPressRewindButton(sender: AnyObject) {
		AudioPlayerManager.sharedInstance.rewind()
	}

	@IBAction func didPressStopButton(sender: AnyObject) {
		AudioPlayerManager.sharedInstance.stop()
	}

	@IBAction func didPressPlayPauseButton(sender: AnyObject) {
		AudioPlayerManager.sharedInstance.togglePlayPause()
	}

	@IBAction func didPressForwardButton(sender: AnyObject) {
		AudioPlayerManager.sharedInstance.forward()
	}
}
