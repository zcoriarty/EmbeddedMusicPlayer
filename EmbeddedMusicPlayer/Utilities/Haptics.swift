//
//  Haptics.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import UIKit

enum HapticImpactStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
}

enum HapticNotificationType {
    case success
    case warning
    case error
}

@MainActor
final class Haptics {
    static let shared = Haptics()

    private var impactGenerators: [HapticImpactStyle: UIImpactFeedbackGenerator] = [:]
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    func impact(_ style: HapticImpactStyle, intensity: CGFloat = 1) {
        let generator = impactGenerator(for: style)
        generator.impactOccurred(intensity: intensity)
        generator.prepare()
    }

    func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func notify(_ type: HapticNotificationType) {
        notificationGenerator.notificationOccurred(notificationType(for: type))
        notificationGenerator.prepare()
    }

    private func impactGenerator(for style: HapticImpactStyle) -> UIImpactFeedbackGenerator {
        if let generator = impactGenerators[style] {
            return generator
        }

        let generator = UIImpactFeedbackGenerator(style: impactStyle(for: style))
        generator.prepare()
        impactGenerators[style] = generator
        return generator
    }

    private func impactStyle(for style: HapticImpactStyle) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch style {
        case .light:
            return .light
        case .medium:
            return .medium
        case .heavy:
            return .heavy
        case .soft:
            return .soft
        case .rigid:
            return .rigid
        }
    }

    private func notificationType(for type: HapticNotificationType) -> UINotificationFeedbackGenerator.FeedbackType {
        switch type {
        case .success:
            return .success
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
}
