//
//  GeminiHomeView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI
import MusicKit

struct GeminiHomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        promptBubble
                        iconRow
                        responseText
                        appleMusicCard
                        reactionRow
                        disclaimerText
                    }
                    .padding(.horizontal, AppConstants.Layout.basePadding)
                    .padding(.top, AppConstants.Layout.basePadding)
                    .padding(.bottom, AppConstants.Layout.askGeminiBarHeight + 80)
                }

                // Bottom pinned area
                VStack(spacing: 0) {
                    if !viewModel.isMediaSheetPresented {
                        openPlayerButton
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    askGeminiBar
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.isMediaSheetPresented)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("Menu")
                }

                ToolbarItem(placement: .principal) {
                    Text(AppConstants.Copy.geminiTitle)
                        .font(AppConstants.Typography.subheadline(weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Compose")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                viewModel.loadIfNeeded()
            }
            .sheet(isPresented: $viewModel.isMediaSheetPresented) {
                MediaSheetView()
                    .environmentObject(viewModel)
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(AppConstants.Palette.panelBackground.opacity(0.98))
                    .presentationBackgroundInteraction(
                        .enabled(upThrough: .height(AppConstants.Layout.mediaSheetHeight))
                    )
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                AppConstants.Palette.appBackgroundTop,
                AppConstants.Palette.appBackgroundBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Prompt Bubble

    private var promptBubble: some View {
        Text(AppConstants.Copy.promptText)
            .font(AppConstants.Typography.subheadline())
            .foregroundStyle(AppConstants.Palette.textPrimary)
            .multilineTextAlignment(.trailing)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppConstants.Palette.shellBubble)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 28,
                        bottomLeading: 28,
                        bottomTrailing: 28,
                        topTrailing: 6
                    ),
                    style: .continuous
                )
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("Prompt")
    }

    // MARK: - Gemini Model Picker Row

    private var iconRow: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "2F6BFF"),
                                Color(hex: "8FD8FF")
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )

                Text(AppConstants.Copy.geminiTitle)
                    .font(AppConstants.Typography.subheadline(weight: .medium))
                    .foregroundStyle(AppConstants.Palette.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppConstants.Palette.textSecondary)
            }

            Spacer()

            Image(systemName: "speaker.wave.2")
                .font(.body)
                .foregroundStyle(AppConstants.Palette.textPrimary.opacity(0.8))
        }
    }

    // MARK: - Response Text

    private var responseText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppConstants.Copy.responseText)
                .font(AppConstants.Typography.body())
                .foregroundStyle(AppConstants.Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.shouldShowPermissionMessage {
                Text(AppConstants.Copy.musicPermissionMessage)
                    .font(AppConstants.Typography.caption())
                    .foregroundStyle(AppConstants.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Apple Music Card

    private var appleMusicCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Apple Music header
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.body)
                    .foregroundStyle(AppConstants.Palette.appleMusicPink)

                Text(AppConstants.Copy.appleMusicLabel)
                    .font(AppConstants.Typography.subheadline(weight: .medium))
                    .foregroundStyle(AppConstants.Palette.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Separator under header
            Rectangle()
                .fill(AppConstants.Palette.appBackgroundBottom)
                .frame(height: 2)
                .padding(.bottom, 8)

            // Track info sub-card
            if let track = viewModel.currentTrack ?? viewModel.recommendedTracks.first {
                Button {
                    Haptics.shared.impact(.soft, intensity: 0.8)
                    viewModel.selectSong(track)
                } label: {
                    HStack(spacing: 12) {
                        appleMusicArtwork(for: track)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(track.title)
                                .font(AppConstants.Typography.subheadline(weight: .semibold))
                                .foregroundStyle(AppConstants.Palette.textPrimary)
                                .lineLimit(1)

                            Text(trackSubtitle(for: track))
                                .font(AppConstants.Typography.caption())
                                .foregroundStyle(AppConstants.Palette.textSecondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.appleMusicCardCornerRadius, style: .continuous)
                .fill(AppConstants.Palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.appleMusicCardCornerRadius, style: .continuous)
                .stroke(AppConstants.Palette.surfaceOutline, lineWidth: 1)
        )
    }

    private func appleMusicArtwork(for track: MediaTrack) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppConstants.Palette.panelBackground)

            if let artwork = track.musicKitArtwork {
                ArtworkImage(artwork, width: AppConstants.Layout.musicCardArtworkSize, height: AppConstants.Layout.musicCardArtworkSize)
                    .scaledToFill()
            } else if let artworkURL = track.loadableArtworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "music.note")
                            .foregroundStyle(AppConstants.Palette.textSecondary)
                    }
                }
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(AppConstants.Palette.textSecondary)
            }
        }
        .frame(width: AppConstants.Layout.musicCardArtworkSize, height: AppConstants.Layout.musicCardArtworkSize)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func trackSubtitle(for track: MediaTrack) -> String {
        var parts: [String] = []
        if !track.albumTitle.isEmpty {
            parts.append("Album")
        }
        parts.append(track.subtitle)
        return parts.joined(separator: " · ")
    }

    // MARK: - Reaction Row

    private var reactionRow: some View {
        HStack(spacing: 20) {
            reactionButton(icon: "hand.thumbsup", label: "Like")
            reactionButton(icon: "hand.thumbsdown", label: "Dislike")
            reactionButton(icon: "square.and.arrow.up", label: "Share")
            reactionButton(icon: "doc.on.doc", label: "Copy")

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(AppConstants.Palette.reactionIcon)
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    Haptics.shared.selectionChanged()
                }
            )
            .accessibilityLabel("More options")
        }
    }

    private func reactionButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(AppConstants.Palette.reactionIcon)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                Haptics.shared.selectionChanged()
            }
        )
        .accessibilityLabel(label)
    }

    // MARK: - Disclaimer

    private var disclaimerText: some View {
        Text(AppConstants.Copy.geminiDisclaimer)
            .font(AppConstants.Typography.caption())
            .foregroundStyle(AppConstants.Palette.textSecondary)
    }

    // MARK: - Open Player Button

    private var openPlayerButton: some View {
        Button {
            Haptics.shared.impact(.medium, intensity: 0.9)
            viewModel.isMediaSheetPresented = true
        } label: {
            Text(AppConstants.Copy.openPlayer)
                .font(AppConstants.Typography.subheadline(weight: .semibold))
                .foregroundStyle(AppConstants.Palette.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppConstants.Palette.selected)
                .clipShape(Capsule())
        }
        .padding(.bottom, 12)
        .accessibilityLabel("Open media player")
    }

    // MARK: - Ask Gemini Bar

    private var askGeminiBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Input field placeholder
                HStack {
                    Text(AppConstants.Copy.askGeminiPlaceholder)
                        .font(AppConstants.Typography.body())
                        .foregroundStyle(AppConstants.Palette.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)

                // Bottom action row
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppConstants.Palette.reactionIcon)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Haptics.shared.selectionChanged()
                        }
                    )
                    .accessibilityLabel("Add attachment")

                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(AppConstants.Palette.reactionIcon)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Haptics.shared.selectionChanged()
                        }
                    )
                    .accessibilityLabel("Settings")

                    Spacer()

                    // "Fast" pill
                    Text(AppConstants.Copy.fastLabel)
                        .font(AppConstants.Typography.caption(weight: .semibold))
                        .foregroundStyle(AppConstants.Palette.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(AppConstants.Palette.inputBarBorder, lineWidth: 1)
                        )

                    Button(action: {}) {
                        Image(systemName: "mic")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppConstants.Palette.reactionIcon)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Haptics.shared.selectionChanged()
                        }
                    )
                    .accessibilityLabel("Voice input")

                    Button(action: {}) {
                        Image(systemName: "waveform")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppConstants.Palette.reactionIcon)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Haptics.shared.selectionChanged()
                        }
                    )
                    .accessibilityLabel("Audio")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .padding(.bottom, 34)
        .background(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 20,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 20
                ),
                style: .continuous
            )
            .fill(AppConstants.Palette.inputBarBackground)
            .ignoresSafeArea(.all, edges: .bottom)
        )
    }
}
