//
//  UIKitAnimator.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Foundation
import UIKit

enum UIKitAnimator {
    @MainActor
    static func spring(
        duration: TimeInterval = 0.26,
        damping: CGFloat = 0.72,
        velocity: CGFloat = 0.8,
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: animations
        ) { _ in
            completion?()
        }
    }

    @MainActor
    static func settle(
        duration: TimeInterval = 0.18,
        animations: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: animations
        )
    }
}
