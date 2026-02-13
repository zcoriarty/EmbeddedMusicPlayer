//
//  LibraryPlaylistsSectionView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI
import MusicKit

struct LibraryPlaylistsSectionView: View {
    let playlists: [MediaPlaylist]
    let onSelectPlaylist: (MediaPlaylist) -> Void

    private var visiblePlaylists: [MediaPlaylist] {
        Array(playlists.prefix(AppConstants.Library.playlistLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppConstants.Copy.playlistsHeader)
                .font(AppConstants.Typography.subheadline(weight: .bold))
                .foregroundStyle(AppConstants.Palette.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(visiblePlaylists) { playlist in
                        LibraryPlaylistCardView(playlist: playlist) {
                            onSelectPlaylist(playlist)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct LibraryPlaylistCardView: View {
    let playlist: MediaPlaylist
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.impact(.soft, intensity: 0.85)
            action()
        } label: {
            ZStack(alignment: .bottomLeading) {
                artworkLayer

                overlayLayer

                VStack(alignment: .leading, spacing: 3) {
                    Text(playlist.title)
                        .font(AppConstants.Typography.subheadline(weight: .semibold))
                        .lineLimit(2)

                    Text(playlistSubtitle)
                        .font(AppConstants.Typography.caption2(weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(Color.white.opacity(0.78))
                }
                .padding(12)
                .foregroundStyle(Color.white)
            }
            .frame(width: AppConstants.Layout.playlistCardWidth, height: AppConstants.Layout.playlistCardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppConstants.Palette.surfaceOutline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Playlist \(playlist.title)")
    }

    private var overlayLayer: some View {
        ZStack {
            // Overall tonal shaping so text remains readable without a harsh black cut.
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.03), location: 0.0),
                    .init(color: Color.black.opacity(0.09), location: 0.38),
                    .init(color: Color.black.opacity(0.26), location: 0.68),
                    .init(color: Color.black.opacity(0.52), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Adds a soft, glassy blur toward the bottom to improve legibility.
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.42),
                            .init(color: .white.opacity(0.52), location: 0.78),
                            .init(color: .white, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    @ViewBuilder
    private var artworkLayer: some View {
        if let artwork = playlist.musicKitArtwork {
            ArtworkImage(
                artwork,
                width: AppConstants.Layout.playlistCardWidth,
                height: AppConstants.Layout.playlistCardHeight
            )
            .scaledToFill()
        } else if let artworkURL = playlist.loadableArtworkURL {
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

    private var fallbackArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppConstants.Palette.selected.opacity(0.95),
                    AppConstants.Palette.panelBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note.list")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }

    private var playlistSubtitle: String {
        if playlist.songCount > 0 {
            return "\(playlist.songCount) songs"
        }

        return playlist.caption
    }
}
