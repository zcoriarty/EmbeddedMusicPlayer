//
//  MarqueeTextView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

private struct MarqueeTextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MarqueeTextView: View {
    let text: String
    let font: Font
    let textColor: Color

    @ScaledMetric(relativeTo: .title3) private var lineHeight = 28

    private let pointsPerSecond: CGFloat = 36
    private let gapWidth: CGFloat = 30
    private let fadeWidth: CGFloat = 20

    @State private var textWidth: CGFloat = 0
    @State private var animationStartDate = Date()

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(proxy.size.width, 1)
            let shouldScroll = textWidth > availableWidth

            TimelineView(.animation(paused: !shouldScroll)) { timeline in
                let cycleDistance = max(textWidth + gapWidth, 1)
                let distance = CGFloat(timeline.date.timeIntervalSince(animationStartDate) * Double(pointsPerSecond))
                    .truncatingRemainder(dividingBy: cycleDistance)

                ZStack(alignment: .leading) {
                    if shouldScroll {
                        HStack(spacing: gapWidth) {
                            baseText
                            baseText
                        }
                        .offset(x: -distance)
                    } else {
                        baseText
                    }
                }
                .frame(width: availableWidth, alignment: .leading)
                .clipped()
                .mask(
                    Group {
                        if shouldScroll {
                            HStack(spacing: 0) {
                                LinearGradient(
                                    colors: [.clear, .black],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: fadeWidth)

                                Color.black

                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: fadeWidth)
                            }
                        } else {
                            Color.black
                        }
                    }
                )
            }
        }
        .frame(height: lineHeight)
        .background(measurementText)
        .onPreferenceChange(MarqueeTextWidthPreferenceKey.self) { width in
            textWidth = width
        }
        .onAppear {
            animationStartDate = Date()
        }
        .onChange(of: text) { _, _ in
            animationStartDate = Date()
        }
    }

    private var baseText: some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var measurementText: some View {
        baseText
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: MarqueeTextWidthPreferenceKey.self, value: proxy.size.width)
                }
            )
            .hidden()
    }
}
