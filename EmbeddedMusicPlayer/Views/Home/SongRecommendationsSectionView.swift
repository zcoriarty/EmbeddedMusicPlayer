//
//  SongRecommendationsSectionView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI
import MusicKit

struct SongRecommendationsSectionView: View {
    let tracks: [MediaTrack]
    let currentTrackID: String?
    let isCurrentTrackPlaying: Bool
    let favoriteTrackIDs: Set<String>
    let onSelectTrack: (MediaTrack) -> Void

    private var visibleTracks: [MediaTrack] {
        Array(tracks.prefix(AppConstants.Library.recommendationLimit))
    }

    private var pagedTracks: [[MediaTrack]] {
        visibleTracks.chunked(into: AppConstants.Layout.songsPageRowCount)
    }

    private var showsPageControl: Bool {
        pagedTracks.count > 1
    }

    private var pageControlReservedHeight: CGFloat {
        showsPageControl ? 20 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppConstants.Copy.songsHeader)
                .font(AppConstants.Typography.subheadline(weight: .bold))
                .foregroundStyle(AppConstants.Palette.textPrimary)

            TabView {
                ForEach(Array(pagedTracks.enumerated()), id: \.offset) { _, pageTracks in
                    VStack(spacing: 0) {
                        ForEach(Array(pageTracks.enumerated()), id: \.element.id) { index, track in
                            SongRecommendationRowView(
                                track: track,
                                isCurrentTrack: track.id == currentTrackID,
                                isPlaying: isCurrentTrackPlaying,
                                isFavorite: favoriteTrackIDs.contains(track.id),
                                action: { onSelectTrack(track) }
                            )

                            if index < pageTracks.count - 1 {
                                Divider()
                                    .overlay(AppConstants.Palette.surfaceOutline)
                                    .padding(.leading, 32)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, pageControlReservedHeight)
                }
            }
            .frame(height: AppConstants.Layout.songsPagerHeight + pageControlReservedHeight)
            .tabViewStyle(.page(indexDisplayMode: showsPageControl ? .automatic : .never))
        }
    }
}

private struct SongRecommendationRowView: View {
    let track: MediaTrack
    let isCurrentTrack: Bool
    let isPlaying: Bool
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.impact(.soft, intensity: 0.8)
            action()
        } label: {
            HStack(spacing: 12) {
                SongRowArtworkView(track: track)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(AppConstants.Typography.subheadline(weight: .semibold))
                        .lineLimit(1)
                    Text(track.subtitle)
                        .font(AppConstants.Typography.caption())
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingIndicator
            }
            .foregroundStyle(AppConstants.Palette.textPrimary)
            .padding(.vertical, 8)
            .frame(minHeight: AppConstants.Layout.songRowMinHeight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(track.title), \(track.artistName)")
    }

    @ViewBuilder
    private var trailingIndicator: some View {
        if isCurrentTrack {
            NowPlayingWaveView(isAnimating: isPlaying)
        } else if isFavorite {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
        }
    }
}

private struct SongRowArtworkView: View {
    let track: MediaTrack

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppConstants.Palette.panelBackground.opacity(0.85))

            if let artwork = track.musicKitArtwork {
                ArtworkImage(artwork, width: 40, height: 40)
                    .scaledToFill()
            } else if let artworkURL = track.loadableArtworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackArtwork
                    }
                }
            } else {
                fallbackArtwork
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var fallbackArtwork: some View {
        Image(systemName: "music.note")
            .foregroundStyle(AppConstants.Palette.textSecondary)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }

        return stride(from: 0, to: count, by: size).map { index in
            Array(self[index..<Swift.min(index + size, count)])
        }
    }
}
