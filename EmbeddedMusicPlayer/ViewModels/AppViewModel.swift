//
//  AppViewModel.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Combine
import Foundation
import MusicKit

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var recommendedTracks: [MediaTrack] = []
    @Published private(set) var playlists: [MediaPlaylist] = []
    @Published private(set) var playbackSnapshot: PlaybackSnapshot = .empty
    @Published private(set) var currentTrack: MediaTrack?
    @Published private(set) var favoriteTrackIDs: Set<String> = []
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isMediaSheetPresented = true

    private let musicLibraryService: MusicLibraryService
    private let playbackService: MusicPlaybackService
    private let persistenceStore: MediaPersistenceStore

    private var cancellables: Set<AnyCancellable> = []
    private var hasLoaded = false

    init(
        musicLibraryService: MusicLibraryService,
        playbackService: MusicPlaybackService,
        persistenceStore: MediaPersistenceStore
    ) {
        self.musicLibraryService = musicLibraryService
        self.playbackService = playbackService
        self.persistenceStore = persistenceStore

        playbackService.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                guard let self else { return }
                playbackSnapshot = snapshot
                currentTrack = playbackService.activeSystemTrack
                    ?? findTrack(id: snapshot.currentTrackID)
                    ?? playbackService.activeQueueTrack
            }
            .store(in: &cancellables)
    }

    var shouldShowPermissionMessage: Bool {
        authorizationStatus != .authorized
    }

    var progressValue: Double {
        guard playbackSnapshot.duration > 0 else {
            return 0
        }

        return min(max(playbackSnapshot.currentTime / playbackSnapshot.duration, 0), 1)
    }

    var isCurrentTrackFavorite: Bool {
        guard let currentTrack else {
            return false
        }

        return favoriteTrackIDs.contains(currentTrack.id)
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        Task {
            await loadInitialContent()
        }
    }

    func selectSong(_ track: MediaTrack) {
        isMediaSheetPresented = true

        Task {
            await playbackService.loadQueue(recommendedTracks, startAtID: track.id, autoplay: true)
            await persistenceStore.saveSelection(track: track, source: .song)
        }
    }

    func selectPlaylist(_ playlist: MediaPlaylist) {
        guard let firstTrack = playlist.tracks.first else { return }
        isMediaSheetPresented = true

        Task {
            await playbackService.loadQueue(playlist.tracks, startAtID: firstTrack.id, autoplay: true)
            await persistenceStore.saveSelection(track: firstTrack, source: .playlist)
        }
    }

    func togglePlayback() {
        Task {
            await playbackService.togglePlayback()
        }
    }

    func playNext() {
        Task {
            await playbackService.next()
        }
    }

    func playPrevious() {
        Task {
            await playbackService.previous()
        }
    }

    func seek(to progress: Double) {
        playbackService.seek(to: progress)
    }

    func cycleRepeatMode() {
        playbackService.cycleRepeatMode()
    }

    func toggleFavoriteForCurrentTrack() {
        guard let currentTrack else { return }
        let shouldFavorite = !favoriteTrackIDs.contains(currentTrack.id)

        if shouldFavorite {
            favoriteTrackIDs.insert(currentTrack.id)
        } else {
            favoriteTrackIDs.remove(currentTrack.id)
        }

        Task {
            await persistenceStore.setFavorite(shouldFavorite, track: currentTrack)
        }
    }

    private func loadInitialContent() async {
        authorizationStatus = await musicLibraryService.requestAuthorizationIfNeeded()

        let favoriteIDs = await persistenceStore.loadFavoriteIDs()
        favoriteTrackIDs = favoriteIDs

        let fetchedTracks: [MediaTrack]
        let fetchedPlaylists: [MediaPlaylist]
        if authorizationStatus == .authorized {
            fetchedTracks = await musicLibraryService.fetchLibraryTracks(limit: AppConstants.Library.recommendationLimit)
            fetchedPlaylists = await musicLibraryService.fetchLibraryPlaylists(limit: AppConstants.Library.playlistLimit)
        } else {
            fetchedTracks = []
            fetchedPlaylists = []
        }

        let tracks = fetchedTracks.isEmpty ? MockLibraryFactory.tracks() : fetchedTracks
        recommendedTracks = tracks
        playlists = fetchedPlaylists.isEmpty ? PlaylistFactory.playlists(from: tracks) : fetchedPlaylists

        guard !tracks.isEmpty else {
            currentTrack = nil
            playbackSnapshot = .empty
            return
        }

        let latestSelectionID = await persistenceStore.loadLatestSelectionID()
        let initialTrackID = tracks.contains(where: { $0.id == latestSelectionID }) ? latestSelectionID ?? tracks[0].id : tracks[0].id

        await playbackService.loadQueue(tracks, startAtID: initialTrackID, autoplay: false)
        currentTrack = findTrack(id: initialTrackID)
    }

    private func findTrack(id: String?) -> MediaTrack? {
        guard let id else { return nil }

        if let track = recommendedTracks.first(where: { $0.id == id }) {
            return track
        }

        for playlist in playlists {
            if let track = playlist.tracks.first(where: { $0.id == id }) {
                return track
            }
        }

        return nil
    }
}
