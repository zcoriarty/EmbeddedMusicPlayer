//
//  MusicPlaybackService.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Combine
import Foundation
import MusicKit

@MainActor
final class MusicPlaybackService: ObservableObject {
    @Published private(set) var snapshot: PlaybackSnapshot = .empty

    private var player: ApplicationMusicPlayer?
    private var queue: [MediaTrack] = []
    private var systemNowPlayingTrack: MediaTrack?
    private var currentIndex: Int = 0
    private var isUsingSystemPlayer: Bool = false
    private var systemPlaybackUnavailable = false

    private var simulatedIsPlaying = false
    private var simulatedCurrentTime: TimeInterval = 0
    private var simulatedRepeatCycle: RepeatCycle = .off

    private var playbackTimer: Timer?
    private var hasRegisteredPlayerObserver = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timing.playbackUpdateInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    deinit {
        playbackTimer?.invalidate()
    }

    func loadQueue(_ tracks: [MediaTrack], startAtID: String, autoplay: Bool) async {
        guard !tracks.isEmpty else {
            queue = []
            snapshot = .empty
            return
        }

        queue = tracks
        currentIndex = tracks.firstIndex(where: { $0.id == startAtID }) ?? 0
        simulatedCurrentTime = 0

        let songs = tracks.compactMap(\.song)
        if songs.count == tracks.count, let startSong = tracks[currentIndex].song {
            let systemPlayerStarted = await configureSystemPlayback(
                songs: songs,
                startSong: startSong,
                autoplay: autoplay
            )

            if !systemPlayerStarted {
                switchToSimulationPlayback(autoplay: autoplay)
            }
        } else {
            switchToSimulationPlayback(autoplay: autoplay)
        }

        refreshSnapshot()
        scheduleDeferredSnapshotRefresh()
    }

    func togglePlayback() async {
        if isUsingSystemPlayer {
            guard let player else {
                switchToSimulationPlayback(autoplay: true)
                refreshSnapshot()
                return
            }

            if player.state.playbackStatus == .playing {
                player.pause()
            } else {
                do {
                    try await player.play()
                } catch {
                    markSystemPlaybackUnavailable(after: error)
                    switchToSimulationPlayback(autoplay: true)
                }
            }
        } else {
            simulatedIsPlaying.toggle()
        }

        refreshSnapshot()
        scheduleDeferredSnapshotRefresh()
    }

    func next() async {
        guard !queue.isEmpty else { return }

        if isUsingSystemPlayer {
            guard let player else {
                switchToSimulationPlayback(autoplay: snapshot.isPlaying)
                moveForwardInSimulation()
                refreshSnapshot()
                return
            }

            do {
                try await player.skipToNextEntry()
                applySuccessfulNextCommand(using: player.state.repeatMode)
            } catch {
                // Ignore system-player edge errors (for example, no next entry).
            }
        } else {
            moveForwardInSimulation()
        }

        refreshSnapshot()
        scheduleDeferredSnapshotRefresh()
    }

    func previous() async {
        guard !queue.isEmpty else { return }

        if isUsingSystemPlayer {
            guard let player else {
                switchToSimulationPlayback(autoplay: snapshot.isPlaying)
                moveBackwardInSimulation()
                refreshSnapshot()
                return
            }

            do {
                try await player.skipToPreviousEntry()
                applySuccessfulPreviousCommand(using: player.state.repeatMode)
            } catch {
                // Ignore system-player edge errors (for example, no previous entry).
            }
        } else {
            moveBackwardInSimulation()
        }

        refreshSnapshot()
        scheduleDeferredSnapshotRefresh()
    }

    func seek(to progress: Double) {
        let clampedProgress = min(max(progress, 0), 1)

        if isUsingSystemPlayer, let player {
            let duration = currentSystemSongDuration() ?? currentTrack()?.duration ?? snapshot.duration
            guard duration > 0 else {
                refreshSnapshot()
                return
            }

            player.playbackTime = min(max(duration * clampedProgress, 0), duration)
        } else {
            let duration = currentTrack()?.duration ?? snapshot.duration
            guard duration > 0 else {
                refreshSnapshot()
                return
            }

            simulatedCurrentTime = min(max(duration * clampedProgress, 0), duration)
        }

        refreshSnapshot()
    }

    func cycleRepeatMode() {
        let nextMode: RepeatCycle

        switch snapshot.repeatCycle {
        case .off:
            nextMode = .all
        case .all:
            nextMode = .one
        case .one:
            nextMode = .off
        }

        simulatedRepeatCycle = nextMode

        if isUsingSystemPlayer {
            applyRepeatModeToSystemPlayer(nextMode)
        }

        refreshSnapshot()
    }

    private func applyRepeatModeToSystemPlayer(_ mode: RepeatCycle) {
        guard let player else { return }

        switch mode {
        case .off:
            player.state.repeatMode = MusicPlayer.RepeatMode.none
        case .all:
            player.state.repeatMode = .all
        case .one:
            player.state.repeatMode = .one
        }
    }

    private func tick() {
        if isUsingSystemPlayer {
            refreshSnapshot()
            return
        }

        guard simulatedIsPlaying, let activeTrack = currentTrack() else {
            refreshSnapshot()
            return
        }

        simulatedCurrentTime += AppConstants.Timing.simulatedPlaybackStep

        if simulatedCurrentTime >= activeTrack.duration {
            simulatedCurrentTime = activeTrack.duration
            handleSimulationTrackEnd()
        }

        refreshSnapshot()
    }

    private func handleSimulationTrackEnd() {
        switch simulatedRepeatCycle {
        case .one:
            simulatedCurrentTime = 0
        case .all:
            if currentIndex + 1 < queue.count {
                currentIndex += 1
            } else {
                currentIndex = 0
            }
            simulatedCurrentTime = 0
        case .off:
            if currentIndex + 1 < queue.count {
                currentIndex += 1
                simulatedCurrentTime = 0
            } else {
                simulatedIsPlaying = false
            }
        }
    }

    private func moveForwardInSimulation() {
        guard !queue.isEmpty else { return }

        if currentIndex + 1 < queue.count {
            currentIndex += 1
            simulatedCurrentTime = 0
            return
        }

        if simulatedRepeatCycle == .all {
            currentIndex = 0
            simulatedCurrentTime = 0
        }
    }

    private func moveBackwardInSimulation() {
        guard !queue.isEmpty else { return }

        if simulatedCurrentTime > 5 {
            simulatedCurrentTime = 0
            return
        }

        if currentIndex > 0 {
            currentIndex -= 1
            simulatedCurrentTime = 0
        } else {
            simulatedCurrentTime = 0
        }
    }

    private func refreshSnapshot() {
        if isUsingSystemPlayer, let player {
            let currentSong = player.queue.currentEntry?.item as? Song
            let matchedTrackFromSong: MediaTrack?
            if let queueIndex = queueIndex(for: currentSong), queue.indices.contains(queueIndex) {
                currentIndex = queueIndex
                matchedTrackFromSong = queue[queueIndex]
            } else {
                matchedTrackFromSong = nil
            }

            let activeQueueTrack = currentTrack()
            let fallbackTrack = matchedTrackFromSong ?? activeQueueTrack
            systemNowPlayingTrack = mergedNowPlayingTrack(song: currentSong, fallbackTrack: fallbackTrack)
            let trackID = fallbackTrack?.id ?? systemNowPlayingTrack?.id
            let duration = currentSong?.duration ?? fallbackTrack?.duration ?? snapshot.duration
            let repeatCycle = repeatCycle(for: player.state.repeatMode)

            simulatedRepeatCycle = repeatCycle

            snapshot = PlaybackSnapshot(
                currentTrackID: trackID,
                currentTime: max(0, min(player.playbackTime, duration)),
                duration: duration,
                isPlaying: player.state.playbackStatus == .playing,
                repeatCycle: repeatCycle
            )
            return
        }

        if isUsingSystemPlayer {
            isUsingSystemPlayer = false
        }

        systemNowPlayingTrack = nil

        snapshot = PlaybackSnapshot(
            currentTrackID: currentTrack()?.id,
            currentTime: min(simulatedCurrentTime, currentTrack()?.duration ?? 0),
            duration: currentTrack()?.duration ?? 0,
            isPlaying: simulatedIsPlaying,
            repeatCycle: simulatedRepeatCycle
        )
    }

    private func scheduleDeferredSnapshotRefresh() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            self?.refreshSnapshot()
        }
    }

    private func mergedNowPlayingTrack(song: Song?, fallbackTrack: MediaTrack?) -> MediaTrack? {
        guard let song else {
            return fallbackTrack
        }

        return MediaTrack(
            id: fallbackTrack?.id ?? song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            albumTitle: song.albumTitle ?? fallbackTrack?.albumTitle ?? "Unknown Album",
            duration: song.duration ?? fallbackTrack?.duration ?? 0,
            artworkURL: artworkURL(from: song.artwork)
                ?? artworkURL(from: song.albums?.first?.artwork)
                ?? fallbackTrack?.artworkURL,
            song: song
        )
    }

    private func applySuccessfulNextCommand(using repeatMode: MusicPlayer.RepeatMode?) {
        guard !queue.isEmpty else { return }

        if currentIndex + 1 < queue.count {
            currentIndex += 1
            return
        }

        if repeatCycle(for: repeatMode) == .all {
            currentIndex = 0
        }
    }

    private func applySuccessfulPreviousCommand(using repeatMode: MusicPlayer.RepeatMode?) {
        guard !queue.isEmpty else { return }

        // Mirror standard player behavior: previous restarts current track when sufficiently progressed.
        if snapshot.currentTime > 5 {
            return
        }

        if currentIndex > 0 {
            currentIndex -= 1
            return
        }

        if repeatCycle(for: repeatMode) == .all {
            currentIndex = queue.count - 1
        }
    }

    private func artworkURL(from artwork: Artwork?) -> URL? {
        guard let artwork else { return nil }
        guard let url = artwork.url(
            width: AppConstants.Library.artworkPointSize,
            height: AppConstants.Library.artworkPointSize
        ) else {
            return nil
        }

        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        return url
    }

    private func repeatCycle(for mode: MusicPlayer.RepeatMode?) -> RepeatCycle {
        switch mode {
        case .all:
            return .all
        case .one:
            return .one
        default:
            return .off
        }
    }

    private func currentSystemSongDuration() -> TimeInterval? {
        (player?.queue.currentEntry?.item as? Song)?.duration
    }

    private func configureSystemPlayback(
        songs: [Song],
        startSong: Song,
        autoplay: Bool
    ) async -> Bool {
        guard let player = resolvedSystemPlayer() else {
            return false
        }

        isUsingSystemPlayer = true
        player.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: startSong)
        applyRepeatModeToSystemPlayer(simulatedRepeatCycle)

        if autoplay {
            do {
                try await player.play()
            } catch {
                markSystemPlaybackUnavailable(after: error)
                return false
            }

            return true
        }

        player.pause()
        return true
    }

    private func switchToSimulationPlayback(autoplay: Bool) {
        player?.pause()
        isUsingSystemPlayer = false
        simulatedIsPlaying = autoplay
    }

    private func resolvedSystemPlayer() -> ApplicationMusicPlayer? {
        guard !systemPlaybackUnavailable else {
            return nil
        }

        if let player {
            return player
        }

        let sharedPlayer = ApplicationMusicPlayer.shared
        player = sharedPlayer
        registerForSystemPlayerUpdates(using: sharedPlayer)
        return sharedPlayer
    }

    private func registerForSystemPlayerUpdates(using player: ApplicationMusicPlayer) {
        guard !hasRegisteredPlayerObserver else {
            return
        }

        hasRegisteredPlayerObserver = true
        player.state.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshSnapshot()
            }
            .store(in: &cancellables)
    }

    private func markSystemPlaybackUnavailable(after error: Error) {
        systemPlaybackUnavailable = true
        isUsingSystemPlayer = false
        player?.pause()
        let message = (error as NSError).localizedDescription
        print("MusicPlaybackService: system playback unavailable, falling back to simulation (\(message)).")
    }

    private func queueIndex(for song: Song?) -> Int? {
        guard let song else { return nil }

        if let idMatch = queue.firstIndex(where: { $0.id == song.id.rawValue }) {
            return idMatch
        }

        if let songIDMatch = queue.firstIndex(where: { $0.song?.id.rawValue == song.id.rawValue }) {
            return songIDMatch
        }

        return queue.firstIndex(where: {
            $0.title == song.title && $0.artistName == song.artistName
        })
    }

    private func currentTrack() -> MediaTrack? {
        guard queue.indices.contains(currentIndex) else {
            return nil
        }

        return queue[currentIndex]
    }

    var activeQueueTrack: MediaTrack? {
        currentTrack()
    }

    var activeSystemTrack: MediaTrack? {
        systemNowPlayingTrack
    }
}
