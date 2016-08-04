//
//  HSAudioPlayerLogSettings.swift
//  HSAudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit

// MARK: - HSAudioPlayerLogSettings

/**
	Holds the settings of `HSAudioPlayer` log.
*/
public class HSAudioPlayerLogSettings {

	/**
	Set this to true if the `HSAudioPlayer` log should be enabled. The default is `false`.
	*/
	public static var Verbose			= true

	/**
	Set this to true if the `HSAudioPlayer` log should containt detailed information about the calling class, function and line. The default is `true`.
	*/
	public static var DetailedLog		= true
}
