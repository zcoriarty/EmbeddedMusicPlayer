//
//  AppConstants.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

enum AppConstants {
    enum Typography {
        private static let regularName = "GoogleSans-Regular"
        private static let mediumName = "GoogleSans-Medium"
        private static let semiboldName = "GoogleSans-SemiBold"
        private static let boldName = "GoogleSans-Bold"

        static func font(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            Font.custom(resolvedName(for: weight), size: baseSize(for: textStyle), relativeTo: textStyle)
        }

        static func body(weight: Font.Weight = .regular) -> Font {
            font(.body, weight: weight)
        }

        static func subheadline(weight: Font.Weight = .regular) -> Font {
            font(.subheadline, weight: weight)
        }

        static func headline(weight: Font.Weight = .semibold) -> Font {
            font(.headline, weight: weight)
        }

        static func title(weight: Font.Weight = .regular) -> Font {
            font(.title, weight: weight)
        }

        static func title2(weight: Font.Weight = .regular) -> Font {
            font(.title2, weight: weight)
        }

        static func title3(weight: Font.Weight = .regular) -> Font {
            font(.title3, weight: weight)
        }

        static func caption(weight: Font.Weight = .regular) -> Font {
            font(.caption, weight: weight)
        }

        static func caption2(weight: Font.Weight = .regular) -> Font {
            font(.caption2, weight: weight)
        }
        
        static func callout(weight: Font.Weight = .regular) -> Font {
            font(.callout, weight: weight)
        }

        private static func resolvedName(for weight: Font.Weight) -> String {
            if weight == .bold || weight == .heavy || weight == .black {
                return boldName
            }

            if weight == .semibold {
                return semiboldName
            }

            if weight == .medium {
                return mediumName
            }

            return regularName
        }

        private static func baseSize(for textStyle: Font.TextStyle) -> CGFloat {
            switch textStyle {
            case .largeTitle:
                return 34
            case .title:
                return 28
            case .title2:
                return 22
            case .title3:
                return 20
            case .headline:
                return 17
            case .subheadline:
                return 15
            case .body:
                return 17
            case .callout:
                return 16
            case .footnote:
                return 13
            case .caption:
                return 12
            case .caption2:
                return 11
            @unknown default:
                return 17
            }
        }
    }

    enum Layout {
        static let cornerRadius: CGFloat = 20
        static let compactCornerRadius: CGFloat = 12
        static let basePadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 28
        static let mediaSheetHeight: CGFloat = 297
        static let mediaContentMaxWidth: CGFloat = 416
        static let mediaControlsRowMaxWidth: CGFloat = 312
        static let mediaCardVerticalPadding: CGFloat = 22
        static let mediaArtworkSize: CGFloat = 88
        static let mediaActionSize: CGFloat = 36
        static let mediaPlayControlSize: CGFloat = 72
        static let mediaSliderHeight: CGFloat = 3
        static let mediaScrubberHeight: CGFloat = 3
        static let mediaScrubberThumbSize: CGFloat = 14
        static let geminiResponseTopPadding: CGFloat = 26
        static let playlistCardWidth: CGFloat = 196
        static let playlistCardHeight: CGFloat = 196
        static let songRowMinHeight: CGFloat = 58
        static let songsPagerHeight: CGFloat = 212
        static let songsPageRowCount: Int = 3
        static let songsPageSpacing: CGFloat = 10
        static let visualIconSize: CGFloat = 22
        static let askGeminiBarHeight: CGFloat = 100
        static let appleMusicCardCornerRadius: CGFloat = 16
        static let musicCardArtworkSize: CGFloat = 56
    }

    enum Timing {
        static let animationDuration: TimeInterval = 0.26
        static let animationSettleDuration: TimeInterval = 0.18
        static let springDamping: CGFloat = 0.72
        static let springVelocity: CGFloat = 0.8
        static let playbackUpdateInterval: TimeInterval = 0.5
        static let simulatedPlaybackStep: TimeInterval = 0.5
    }

    enum Library {
        static let recommendationLimit: Int = 18
        static let playlistLimit: Int = 10
        static let historyCap: Int = 80
        static let artworkPointSize: Int = 240
    }

    enum Copy {
        static let geminiTitle = "Gemini"
        static let promptText = "Play me some cool jams to work to please!"
        static let responseText = "Sure, I can help with that."
        static let songsHeader = "Songs"
        static let playlistsHeader = "Playlists"
        static let openPlayer = "Open Player"
        static let musicPermissionMessage = "Allow Apple Music access to load songs from your library."
        static let appleMusicLabel = "Apple Music"
        static let geminiDisclaimer = "Gemini is AI and can make mistakes."
        static let askGeminiPlaceholder = "Ask Gemini"
        static let fastLabel = "Fast"
    }

    enum Palette {
        static let appBackgroundTop = Color(hex: "101318")
        static let appBackgroundBottom = Color(hex: "171A22")
        static let panelBackground = Color(hex: "2E3240")
        static let selected = Color(hex: "004A77")
        static let barPrimary = Color(hex: "96989F")
        static let barSecondary = Color(hex: "585B66")
        static let shellBubble = Color(hex: "32353E")
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.62)
        static let surfaceOutline = Color.white.opacity(0.08)
        static let reactionIcon = Color.white.opacity(0.72)
        static let inputBarBackground = Color(hex: "1E2028")
        static let inputBarBorder = Color.white.opacity(0.12)
        static let cardBackground = Color(hex: "262A34")
        static let appleMusicPink = Color(hex: "FA2D48")
    }
}
