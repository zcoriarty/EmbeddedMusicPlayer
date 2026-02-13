//
//  CoreDataSchema.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import Foundation

enum CoreDataSchema {
    enum Entity {
        static let favoriteTrack = "FavoriteTrack"
        static let selectionHistory = "SelectionHistory"
    }

    enum FavoriteTrack {
        static let id = "id"
        static let title = "title"
        static let artistName = "artistName"
        static let albumTitle = "albumTitle"
        static let updatedAt = "updatedAt"
    }

    enum SelectionHistory {
        static let id = "id"
        static let itemID = "itemID"
        static let title = "title"
        static let subtitle = "subtitle"
        static let source = "source"
        static let selectedAt = "selectedAt"
    }
}
