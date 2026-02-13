//
//  MediaArtworkThumbnailView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI
import MusicKit

struct MediaArtworkThumbnailView: View {
    let track: MediaTrack?

    @ScaledMetric(relativeTo: .body) private var artworkSize = AppConstants.Layout.mediaArtworkSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppConstants.Palette.selected.opacity(0.25))

            if let artwork = track?.musicKitArtwork {
                ArtworkImage(artwork, width: artworkSize, height: artworkSize)
                    .scaledToFill()
            } else if let artworkURL = resolvedArtworkURL {
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
        .frame(width: artworkSize, height: artworkSize)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var fallbackArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppConstants.Palette.selected.opacity(0.8),
                    AppConstants.Palette.panelBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let symbol = trackTitleSymbol {
                Text(symbol)
                    .font(AppConstants.Typography.title(weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
            } else {
                Image(systemName: "music.note")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppConstants.Palette.textPrimary.opacity(0.9))
            }
        }
    }

    private var trackTitleSymbol: String? {
        guard let track else { return nil }
        guard let firstCharacter = track.title.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return nil
        }

        return String(firstCharacter).uppercased()
    }

    private var resolvedArtworkURL: URL? {
        track?.loadableArtworkURL
    }
}
