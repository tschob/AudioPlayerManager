//
//  Log.swift
//  AudioPlayerManager
//
//  Created by Hans Seiffert on 02.08.16.
//  Copyright © 2016 Hans Seiffert. All rights reserved.
//

import UIKit

// MARK: - Log

func log(_ message: String = "", file: String = #file, function: String = #function, line: Int = #line) {
	if (AudioPlayerManager.verbose == true) {
		if (AudioPlayerManager.detailedLog == true),
			let className = URL(string: file)?.lastPathComponent.components(separatedBy: ".").first {
			let log = "\(Date()) - [\(className)].\(function)[\(line)]: \(message)"
			print(log)
		} else {
			print(message)
		}
	}
}
