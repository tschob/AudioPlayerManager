//
//  AudioPlayerLog.swift
//  AudioPlayer
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit

// MARK: - AudioPlayerLog

func AudioPlayerLog(message: AnyObject = "", file: String = #file, function: String = #function, line: Int = #line) {
	#if DEBUG
		if (AudioPlayerLogSettings.Verbose == true) {
			if (AudioPlayerLogSettings.DetailedLog == true),
				let className = NSURL(string: file)?.lastPathComponent?.componentsSeparatedByString(".").first {
					let log = "\(NSDate()) - [\(className)].\(function)[\(line)]: \(message)"
					print(log)
			} else {
				print(message)
			}
		}
	#endif
}
