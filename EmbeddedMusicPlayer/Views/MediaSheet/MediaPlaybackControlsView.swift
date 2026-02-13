//
//  MediaPlaybackControlsView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct MediaPlaybackControlsView: View {
    let playbackSnapshot: PlaybackSnapshot
    let isFavorite: Bool
    let onToggleRepeat: () -> Void
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onToggleFavorite: () -> Void

    @ScaledMetric(relativeTo: .body) private var playControlSize = AppConstants.Layout.mediaPlayControlSize
    @ScaledMetric(relativeTo: .body) private var smallControlSize = AppConstants.Layout.mediaActionSize
    @State private var playButtonScale: CGFloat = 1

    var body: some View {
        HStack(spacing: 24) {
            iconButton(
                systemName: repeatSystemName,
                isHighlighted: playbackSnapshot.repeatCycle != .off,
                action: {
                    Haptics.shared.selectionChanged()
                    onToggleRepeat()
                },
                accessibilityLabel: repeatAccessibilityLabel
            )

            iconButton(
                systemName: "backward.end.fill",
                action: {
                    Haptics.shared.impact(.rigid, intensity: 0.82)
                    onPrevious()
                },
                accessibilityLabel: "Previous"
            )

            playButton

            iconButton(
                systemName: "forward.end.fill",
                action: {
                    Haptics.shared.impact(.rigid, intensity: 0.82)
                    onNext()
                },
                accessibilityLabel: "Next"
            )

            iconButton(
                systemName: isFavorite ? "heart.fill" : "heart",
                isHighlighted: isFavorite,
                action: {
                    if isFavorite {
                        Haptics.shared.impact(.light, intensity: 0.7)
                    } else {
                        Haptics.shared.notify(.success)
                    }
                    onToggleFavorite()
                },
                accessibilityLabel: isFavorite ? "Remove favorite" : "Add favorite"
            )
        }
        .frame(maxWidth: AppConstants.Layout.mediaControlsRowMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private var playButton: some View {
        Button {
            Haptics.shared.impact(.medium, intensity: 0.95)
            UIKitAnimator.spring {
                playButtonScale = 0.9
            } completion: {
                UIKitAnimator.settle {
                    playButtonScale = 1
                }
            }
            onPlayPause()
        } label: {
            Image(systemName: playbackSnapshot.isPlaying ? "pause.fill" : "play.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: playControlSize, height: playControlSize)
                .background(AppConstants.Palette.selected)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(playButtonScale)
        .accessibilityLabel(playbackSnapshot.isPlaying ? "Pause" : "Play")
    }

    private func iconButton(
        systemName: String,
        isHighlighted: Bool = false,
        action: @escaping () -> Void,
        accessibilityLabel: String
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppConstants.Palette.textPrimary.opacity(isHighlighted ? 1 : 0.9))
                .frame(width: smallControlSize, height: smallControlSize)
                .background(
                    Circle()
                        .fill(AppConstants.Palette.panelBackground.opacity(0.38))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }

    private var repeatSystemName: String {
        switch playbackSnapshot.repeatCycle {
        case .one:
            return "repeat.1"
        default:
            return "repeat"
        }
    }

    private var repeatAccessibilityLabel: String {
        switch playbackSnapshot.repeatCycle {
        case .off:
            return "Repeat off"
        case .all:
            return "Repeat all"
        case .one:
            return "Repeat one"
        }
    }
}
