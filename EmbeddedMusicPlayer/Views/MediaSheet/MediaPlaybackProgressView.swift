//
//  MediaPlaybackProgressView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct MediaPlaybackProgressView: View {
    let playbackSnapshot: PlaybackSnapshot
    let progressValue: Double
    let onSeek: (Double) -> Void

    @State private var sliderValue: Double = 0
    @State private var isEditingSlider = false

    var body: some View {
        VStack(spacing: 6) {
            MediaPlaybackScrubberView(
                value: Binding(
                    get: { sliderValue },
                    set: { sliderValue = $0 }
                ),
                onEditingChanged: { isEditing in
                    isEditingSlider = isEditing
                    if !isEditing {
                        onSeek(sliderValue)
                    }
                }
            )

            HStack {
                Text(playbackSnapshot.currentTime.minuteSecondString)
                Spacer()
                Text(playbackSnapshot.duration.minuteSecondString)
            }
            .font(AppConstants.Typography.caption())
            .foregroundStyle(AppConstants.Palette.textSecondary)
        }
        .padding(.top)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity)
        .onAppear {
            sliderValue = progressValue
        }
        .onChange(of: sliderValue) { _, newValue in
            if isEditingSlider {
                onSeek(newValue)
            }
        }
        .onChange(of: progressValue) { _, newValue in
            if !isEditingSlider {
                sliderValue = newValue
            }
        }
    }
}
