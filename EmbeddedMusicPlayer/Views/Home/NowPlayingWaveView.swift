//
//  NowPlayingWaveView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI Wrapper

struct NowPlayingWaveView: View {
    let isAnimating: Bool

    var body: some View {
        NowPlayingWaveRepresentable(isAnimating: isAnimating)
            .frame(width: 20, height: 18)
            .accessibilityHidden(true)
    }
}

// MARK: - UIKit Representable

private struct NowPlayingWaveRepresentable: UIViewRepresentable {
    let isAnimating: Bool

    func makeUIView(context: Context) -> NowPlayingWaveUIView {
        NowPlayingWaveUIView()
    }

    func updateUIView(_ uiView: NowPlayingWaveUIView, context: Context) {
        uiView.setAnimating(isAnimating)
    }
}

// MARK: - UIKit View (CADisplayLink driven)

private final class NowPlayingWaveUIView: UIView {
    private let barCount = 4
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private let minHeight: CGFloat = 6
    private let maxHeight: CGFloat = 16
    private let speed: Double = 1.4

    private var barLayers: [CALayer] = []
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var animating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }

    private func setupBars() {
        for _ in 0..<barCount {
            let layer = CALayer()
            layer.backgroundColor = UIColor.white.cgColor
            layer.cornerRadius = barWidth / 2
            self.layer.addSublayer(layer)
            barLayers.append(layer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarFrames(timestamp: CACurrentMediaTime())
    }

    func setAnimating(_ value: Bool) {
        guard value != animating else { return }
        animating = value

        if animating {
            startDisplayLink()
        } else {
            stopDisplayLink()
            updateBarFrames(timestamp: 0)
        }
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        startTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        updateBarFrames(timestamp: CACurrentMediaTime())
    }

    private func updateBarFrames(timestamp: CFTimeInterval) {
        let totalWidth = (CGFloat(barCount) * barWidth) + (CGFloat(barCount - 1) * barSpacing)
        let originX = (bounds.width - totalWidth) / 2

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for i in 0..<barCount {
            let height: CGFloat
            if animating {
                let elapsed = timestamp - startTime
                let oscillation = abs(sin((elapsed * speed) + (Double(i) * 0.7)))
                height = minHeight + CGFloat(oscillation) * (maxHeight - minHeight)
            } else {
                height = minHeight
            }

            let x = originX + CGFloat(i) * (barWidth + barSpacing)
            let y = bounds.height - height
            barLayers[i].frame = CGRect(x: x, y: y, width: barWidth, height: height)
        }

        CATransaction.commit()
    }

    override func removeFromSuperview() {
        stopDisplayLink()
        super.removeFromSuperview()
    }
}
