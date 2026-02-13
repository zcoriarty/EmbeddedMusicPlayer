//
//  MediaSheetHeaderView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct MediaSheetHeaderView: View {
    let track: MediaTrack?

    var body: some View {
        HStack(spacing: 12) {
            MediaArtworkThumbnailView(track: track)

            VStack(alignment: .leading, spacing: 8) {
                MarqueeTextView(
                    text: track?.title ?? "No Track Selected",
                    font: AppConstants.Typography.title3(weight: .semibold),
                    textColor: AppConstants.Palette.textPrimary
                )

                Text(track?.subtitle ?? "Pick a song or playlist")
                    .font(AppConstants.Typography.subheadline())
                    .foregroundStyle(AppConstants.Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
