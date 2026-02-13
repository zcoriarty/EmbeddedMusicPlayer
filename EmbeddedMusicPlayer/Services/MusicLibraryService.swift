//
//  MusicLibraryService.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Foundation
import MusicKit

actor MusicLibraryService {
    private let requestRetryCount = 3
    private var libraryAccessUnavailable = false
    private static let artworkPointSize = 240

    func requestAuthorizationIfNeeded() async -> MusicAuthorization.Status {
        let currentStatus = MusicAuthorization.currentStatus
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await MusicAuthorization.request()
    }

    func fetchLibraryTracks(limit: Int) async -> [MediaTrack] {
        guard !libraryAccessUnavailable else {
            return []
        }

        let songs = await fetchSongs(limit: limit)
        let songsWithArtwork = await enrichSongsWithAlbumMetadata(songs)
        return songsWithArtwork.map(Self.makeTrack)
    }

    func fetchLibraryPlaylists(limit: Int) async -> [MediaPlaylist] {
        guard !libraryAccessUnavailable else {
            return []
        }

        let playlists = await fetchPlaylists(limit: limit)
        return playlists.map { playlist in
            let artworkURL = Self.resolvedArtworkURL(from: playlist.artwork)

            return MediaPlaylist(
                id: playlist.id.rawValue,
                title: playlist.name,
                caption: "From your library",
                artwork: playlist.artwork,
                artworkURL: artworkURL,
                songCount: 0,
                tracks: []
            )
        }
    }

    private func fetchSongs(limit: Int) async -> [Song] {
        for attempt in 0..<requestRetryCount {
            do {
                var request = MusicLibraryRequest<Song>()
                request.limit = limit
                let response = try await request.response()
                return Array(response.items)
            } catch {
                if shouldFailFast(for: error) {
                    libraryAccessUnavailable = true
                    print("MusicLibraryService: library access unavailable due to missing entitlement.")
                    return []
                }

                print("MusicLibraryService: song fetch attempt \(attempt + 1) failed: \(error)")
                guard attempt < requestRetryCount - 1 else {
                    return []
                }

                let backoff = UInt64((attempt + 1) * 300_000_000)
                try? await Task.sleep(nanoseconds: backoff)
            }
        }

        return []
    }

    private func fetchPlaylists(limit: Int) async -> [Playlist] {
        for attempt in 0..<requestRetryCount {
            do {
                var request = MusicLibraryRequest<Playlist>()
                request.limit = limit
                let response = try await request.response()
                return Array(response.items)
            } catch {
                if shouldFailFast(for: error) {
                    libraryAccessUnavailable = true
                    print("MusicLibraryService: playlist access unavailable due to missing entitlement.")
                    return []
                }

                print("MusicLibraryService: playlist fetch attempt \(attempt + 1) failed: \(error)")
                guard attempt < requestRetryCount - 1 else {
                    return []
                }

                let backoff = UInt64((attempt + 1) * 300_000_000)
                try? await Task.sleep(nanoseconds: backoff)
            }
        }

        return []
    }

    private static func makeTrack(from song: Song) -> MediaTrack {
        let artworkURL = resolvedArtworkURL(from: song.artwork)
            ?? resolvedArtworkURL(from: song.albums?.first?.artwork)

        return MediaTrack(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            albumTitle: song.albumTitle ?? "Unknown Album",
            duration: song.duration ?? 0,
            artworkURL: artworkURL,
            song: song
        )
    }

    private func enrichSongsWithAlbumMetadata(_ songs: [Song]) async -> [Song] {
        guard !songs.isEmpty else {
            return songs
        }

        var enrichedSongs: [Song] = []
        enrichedSongs.reserveCapacity(songs.count)

        for song in songs {
            if song.artwork != nil || song.albums?.first?.artwork != nil {
                enrichedSongs.append(song)
                continue
            }

            do {
                let songWithAlbums = try await song.with([.albums])
                enrichedSongs.append(songWithAlbums)
            } catch {
                enrichedSongs.append(song)
            }
        }

        return enrichedSongs
    }

    private func shouldFailFast(for error: Error) -> Bool {
        containsAccountStoreEntitlementError(in: error as NSError)
    }

    private func containsAccountStoreEntitlementError(in error: NSError) -> Bool {
        if error.domain == "ICError", error.code == -7013 {
            return true
        }

        if error.localizedDescription.localizedCaseInsensitiveContains("not entitled to access account store") {
            return true
        }

        if let debugDescription = error.userInfo["NSDebugDescription"] as? String,
           debugDescription.localizedCaseInsensitiveContains("not entitled to access account store") {
            return true
        }

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           containsAccountStoreEntitlementError(in: underlyingError) {
            return true
        }

        if let underlyingErrors = error.userInfo[NSMultipleUnderlyingErrorsKey] as? [NSError] {
            return underlyingErrors.contains(where: containsAccountStoreEntitlementError(in:))
        }

        return false
    }

    private static func resolvedArtworkURL(from artwork: Artwork?) -> URL? {
        guard let url = artwork?.url(
            width: artworkPointSize,
            height: artworkPointSize
        ) else {
            return nil
        }

        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        return url
    }
}
