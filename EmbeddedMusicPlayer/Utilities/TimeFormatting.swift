//
//  TimeFormatting.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Foundation

extension TimeInterval {
    var minuteSecondString: String {
        guard isFinite, self > 0 else { return "0:00" }
        let totalSeconds = Int(self.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
