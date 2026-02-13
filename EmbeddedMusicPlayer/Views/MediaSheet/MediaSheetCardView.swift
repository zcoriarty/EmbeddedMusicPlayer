//
//  MediaSheetCardView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct MediaSheetCardView: View {
    let track: MediaTrack?
    let playbackSnapshot: PlaybackSnapshot
    let progressValue: Double
    let isFavorite: Bool
    let onSeek: (Double) -> Void
    let onToggleRepeat: () -> Void
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            MediaSheetHeaderView(track: track)
            MediaPlaybackProgressView(
                playbackSnapshot: playbackSnapshot,
                progressValue: progressValue,
                onSeek: onSeek
            )
            MediaPlaybackControlsView(
                playbackSnapshot: playbackSnapshot,
                isFavorite: isFavorite,
                onToggleRepeat: onToggleRepeat,
                onPrevious: onPrevious,
                onPlayPause: onPlayPause,
                onNext: onNext,
                onToggleFavorite: onToggleFavorite
            )
        }
        .frame(maxWidth: AppConstants.Layout.mediaContentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Layout.mediaCardVerticalPadding)
        .padding(.top, 32)
        .padding(.horizontal, 32)
    }
}
