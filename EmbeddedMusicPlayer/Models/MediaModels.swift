//
//  MediaModels.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Foundation
import MusicKit

enum RecommendationSource: String, Sendable {
    case song
    case playlist
    case initialLoad
}

enum RepeatCycle: String, Sendable {
    case off
    case all
    case one
}

struct MediaTrack: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let artistName: String
    let albumTitle: String
    let duration: TimeInterval
    let artworkURL: URL?
    let song: Song?

    var subtitle: String {
        "\(artistName), \(albumTitle)"
    }

    var loadableArtworkURL: URL? {
        artworkURL?.httpCompatibleURL
    }

    var musicKitArtwork: Artwork? {
        song?.artwork ?? song?.albums?.first?.artwork
    }
}

struct MediaPlaylist: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let caption: String
    let artwork: Artwork?
    let artworkURL: URL?
    let songCount: Int
    let tracks: [MediaTrack]

    var loadableArtworkURL: URL? {
        artworkURL?.httpCompatibleURL
    }

    var musicKitArtwork: Artwork? {
        artwork ?? tracks.first?.musicKitArtwork
    }
}

struct PlaybackSnapshot: Sendable {
    let currentTrackID: String?
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let repeatCycle: RepeatCycle

    static let empty = PlaybackSnapshot(
        currentTrackID: nil,
        currentTime: 0,
        duration: 0,
        isPlaying: false,
        repeatCycle: .off
    )
}

enum MockLibraryFactory {
    static func tracks() -> [MediaTrack] {
        [
            MediaTrack(
                id: "mock-1",
                title: "Night Build",
                artistName: "Lost Frequencies",
                albumTitle: "Code Sessions",
                duration: 303,
                artworkURL: nil,
                song: nil
            ),
            MediaTrack(
                id: "mock-2",
                title: "Quiet Momentum",
                artistName: "Tom Odell",
                albumTitle: "Focus Tape",
                duration: 261,
                artworkURL: nil,
                song: nil
            ),
            MediaTrack(
                id: "mock-3",
                title: "Sundown Compiler",
                artistName: "Poppy Baskcomb",
                albumTitle: "Late Iterations",
                duration: 287,
                artworkURL: nil,
                song: nil
            ),
            MediaTrack(
                id: "mock-4",
                title: "Parallel Dreams",
                artistName: "Nia Archives",
                albumTitle: "Ship It",
                duration: 239,
                artworkURL: nil,
                song: nil
            )
        ]
    }
}

enum PlaylistFactory {
    static func playlists(from tracks: [MediaTrack]) -> [MediaPlaylist] {
        guard !tracks.isEmpty else { return [] }

        let allTracks = tracks
        let focusSlice = Array(allTracks.prefix(min(4, allTracks.count)))
        let deepSlice = Array(allTracks.reversed().prefix(min(4, allTracks.count)))
        let sprintSlice = Array(allTracks.dropFirst(min(1, allTracks.count - 1)).prefix(min(4, allTracks.count)))

        return [
            MediaPlaylist(
                id: "playlist-focus",
                title: "Deep Focus",
                caption: "Lower tempo for long sessions",
                artwork: focusSlice.first?.musicKitArtwork,
                artworkURL: focusSlice.first?.artworkURL,
                songCount: (focusSlice.isEmpty ? allTracks : focusSlice).count,
                tracks: focusSlice.isEmpty ? allTracks : focusSlice
            ),
            MediaPlaylist(
                id: "playlist-sprint",
                title: "Build Sprint",
                caption: "Higher energy for fast execution",
                artwork: sprintSlice.first?.musicKitArtwork,
                artworkURL: sprintSlice.first?.artworkURL,
                songCount: (sprintSlice.isEmpty ? allTracks : sprintSlice).count,
                tracks: sprintSlice.isEmpty ? allTracks : sprintSlice
            ),
            MediaPlaylist(
                id: "playlist-late",
                title: "Late Night",
                caption: "Evening coding atmosphere",
                artwork: deepSlice.first?.musicKitArtwork,
                artworkURL: deepSlice.first?.artworkURL,
                songCount: (deepSlice.isEmpty ? allTracks : deepSlice).count,
                tracks: deepSlice.isEmpty ? allTracks : deepSlice
            )
        ]
    }
}

private extension URL {
    var httpCompatibleURL: URL? {
        guard let scheme = scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        return self
    }
}
