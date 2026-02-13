//
//  MediaPlaybackScrubberView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct MediaPlaybackScrubberView: View {
    @Binding var value: Double
    let onEditingChanged: (Bool) -> Void

    @State private var isDragging = false
    @State private var lastHapticBucket: Int?
    private let scrubberHapticBucketCount = 24

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = max(proxy.size.width, 1)
            let thumbSize = AppConstants.Layout.mediaScrubberThumbSize
            let thumbRadius = thumbSize / 2
            let progressX = CGFloat(value) * trackWidth

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppConstants.Palette.barSecondary)
                    .frame(height: AppConstants.Layout.mediaScrubberHeight)

                Rectangle()
                    .fill(AppConstants.Palette.textPrimary)
                    .frame(width: progressX, height: AppConstants.Layout.mediaScrubberHeight)

                Circle()
                    .fill(AppConstants.Palette.textPrimary)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: progressX - thumbRadius)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            Haptics.shared.impact(.soft, intensity: 0.75)
                            onEditingChanged(true)
                        }

                        value = clampedValue(for: drag.location.x, width: trackWidth)
                        emitScrubTickIfNeeded(for: value)
                    }
                    .onEnded { drag in
                        value = clampedValue(for: drag.location.x, width: trackWidth)
                        Haptics.shared.impact(.light, intensity: 0.8)
                        isDragging = false
                        lastHapticBucket = nil
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: max(AppConstants.Layout.mediaScrubberThumbSize, 28))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback progress")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + 0.05, 1)
                Haptics.shared.selectionChanged()
            case .decrement:
                value = max(value - 0.05, 0)
                Haptics.shared.selectionChanged()
            @unknown default:
                break
            }

            onEditingChanged(false)
        }
    }

    private func clampedValue(for x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        let clampedX = min(max(x, 0), width)
        return clampedX / width
    }

    private func emitScrubTickIfNeeded(for progress: Double) {
        let bucket = Int((progress * Double(scrubberHapticBucketCount)).rounded(.down))
        guard lastHapticBucket != bucket else { return }
        lastHapticBucket = bucket
        Haptics.shared.selectionChanged()
    }
}
