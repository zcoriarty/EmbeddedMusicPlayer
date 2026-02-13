//
//  MediaSheetView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct MediaSheetView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedDetent: PresentationDetent = .height(AppConstants.Layout.mediaSheetHeight)

    private static let expandedDetent: PresentationDetent = .large

    private var isExpanded: Bool {
        selectedDetent == Self.expandedDetent
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                MediaSheetCardView(
                    track: viewModel.currentTrack,
                    playbackSnapshot: viewModel.playbackSnapshot,
                    progressValue: viewModel.progressValue,
                    isFavorite: viewModel.isCurrentTrackFavorite,
                    onSeek: viewModel.seek(to:),
                    onToggleRepeat: viewModel.cycleRepeatMode,
                    onPrevious: viewModel.playPrevious,
                    onPlayPause: viewModel.togglePlayback,
                    onNext: viewModel.playNext,
                    onToggleFavorite: viewModel.toggleFavoriteForCurrentTrack
                )
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.Layout.mediaSheetHeight)

                expandedContent
            }
        }
        .scrollDisabled(!isExpanded)
        .presentationDetents(
            [.height(AppConstants.Layout.mediaSheetHeight), Self.expandedDetent],
            selection: $selectedDetent
        )
        .onChange(of: selectedDetent) { oldValue, newValue in
            guard oldValue != newValue else { return }
            Haptics.shared.impact(.soft, intensity: 0.72)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: AppConstants.Layout.sectionSpacing) {
            SongRecommendationsSectionView(
                tracks: viewModel.recommendedTracks,
                currentTrackID: viewModel.currentTrack?.id,
                isCurrentTrackPlaying: viewModel.playbackSnapshot.isPlaying,
                favoriteTrackIDs: viewModel.favoriteTrackIDs,
                onSelectTrack: viewModel.selectSong
            )
            .padding(.horizontal, AppConstants.Layout.basePadding)
            .padding(.top, 32)

            LibraryPlaylistsSectionView(
                playlists: viewModel.playlists,
                onSelectPlaylist: viewModel.selectPlaylist
            )
            .padding(.horizontal, AppConstants.Layout.basePadding)
        }
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}
