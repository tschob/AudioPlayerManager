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

	@IBOutlet fileprivate weak var rewindButton: UIButton?
	@IBOutlet fileprivate weak var stopButton: UIButton?
	@IBOutlet fileprivate weak var playPauseButton: UIButton?
	@IBOutlet fileprivate weak var forwardButton: UIButton?

	@IBOutlet fileprivate weak var songLabel: UILabel?
	@IBOutlet fileprivate weak var albumLabel: UILabel?
	@IBOutlet fileprivate weak var artistLabel: UILabel?
	@IBOutlet fileprivate weak var positionLabel: UILabel?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.updateButtonStates()

		// Listen to the player state updates. This state is updated if the play, pause or queue state changed.
		AudioPlayerManager.shared.addPlayStateChangeCallback(self, callback: { [weak self] (track: AudioTrack?) in
			self?.updateButtonStates()
			self?.updateSongInformation(with: track)
		})
		// Listen to the playback time changed. This event occurs every `AudioPlayerManager.PlayingTimeRefreshRate` seconds.
		AudioPlayerManager.shared.addPlaybackTimeChangeCallback(self, callback: { [weak self] (track: AudioTrack?) in
			self?.updatePlaybackTime(track)
		})
	}

	deinit {
		// Stop listening to the callbacks
		AudioPlayerManager.shared.removePlayStateChangeCallback(self)
		AudioPlayerManager.shared.removePlaybackTimeChangeCallback(self)
	}

	func updateButtonStates() {
		self.rewindButton?.isEnabled = AudioPlayerManager.shared.canRewind()
		let imageName = (AudioPlayerManager.shared.isPlaying() == true ? "ic_pause" : "ic_play")
		self.playPauseButton?.setImage(UIImage(named: imageName), for: UIControlState())
		self.playPauseButton?.isEnabled = AudioPlayerManager.shared.canPlay()
		self.forwardButton?.isEnabled = AudioPlayerManager.shared.canForward()
	}

	func updateSongInformation(with track: AudioTrack?) {
		self.songLabel?.text = "\((track?.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String) ?? "-")"
		self.albumLabel?.text = "\((track?.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as? String) ?? "-")"
		self.artistLabel?.text = "\((track?.nowPlayingInfo?[MPMediaItemPropertyArtist] as? String) ?? "-")"
		self.updatePlaybackTime(track)
	}

	func updatePlaybackTime(_ track: AudioTrack?) {
		self.positionLabel?.text = "\(track?.displayablePlaybackTimeString() ?? "-")/\(track?.displayableDurationString() ?? "-")"
	}
}

// MARK: - IBActions

extension PlayerViewController {

	@IBAction func didPressRewindButton(_ sender: AnyObject) {
		AudioPlayerManager.shared.rewind()
	}

	@IBAction func didPressStopButton(_ sender: AnyObject) {
		AudioPlayerManager.shared.stop()
	}

	@IBAction func didPressPlayPauseButton(_ sender: AnyObject) {
		AudioPlayerManager.shared.togglePlayPause()
	}

	@IBAction func didPressForwardButton(_ sender: AnyObject) {
		AudioPlayerManager.shared.forward()
	}
}
