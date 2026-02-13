//
//  MediaPersistenceStore.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import CoreData
import Foundation

actor MediaPersistenceStore {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func loadFavoriteIDs() async -> Set<String> {
        do {
            return try await performBackgroundTask { context in
                let request = NSFetchRequest<NSDictionary>(entityName: CoreDataSchema.Entity.favoriteTrack)
                request.resultType = .dictionaryResultType
                request.propertiesToFetch = [CoreDataSchema.FavoriteTrack.id]

                let rows = try context.fetch(request)
                return Set(rows.compactMap { $0[CoreDataSchema.FavoriteTrack.id] as? String })
            }
        } catch {
            return []
        }
    }

    func setFavorite(_ isFavorite: Bool, track: MediaTrack) async {
        do {
            _ = try await performBackgroundTask { context in
                let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataSchema.Entity.favoriteTrack)
                request.predicate = NSPredicate(format: "%K == %@", CoreDataSchema.FavoriteTrack.id, track.id)
                request.fetchLimit = 1

                let existing = try context.fetch(request).first

                if isFavorite {
                    let target = existing ?? NSEntityDescription.insertNewObject(
                        forEntityName: CoreDataSchema.Entity.favoriteTrack,
                        into: context
                    )

                    target.setValue(track.id, forKey: CoreDataSchema.FavoriteTrack.id)
                    target.setValue(track.title, forKey: CoreDataSchema.FavoriteTrack.title)
                    target.setValue(track.artistName, forKey: CoreDataSchema.FavoriteTrack.artistName)
                    target.setValue(track.albumTitle, forKey: CoreDataSchema.FavoriteTrack.albumTitle)
                    target.setValue(Date(), forKey: CoreDataSchema.FavoriteTrack.updatedAt)
                } else if let existing {
                    context.delete(existing)
                }

                if context.hasChanges {
                    try context.save()
                }
            }
        } catch {
            return
        }
    }

    func saveSelection(track: MediaTrack, source: RecommendationSource) async {
        do {
            _ = try await performBackgroundTask { context in
                let entry = NSEntityDescription.insertNewObject(
                    forEntityName: CoreDataSchema.Entity.selectionHistory,
                    into: context
                )

                entry.setValue(UUID(), forKey: CoreDataSchema.SelectionHistory.id)
                entry.setValue(track.id, forKey: CoreDataSchema.SelectionHistory.itemID)
                entry.setValue(track.title, forKey: CoreDataSchema.SelectionHistory.title)
                entry.setValue(track.subtitle, forKey: CoreDataSchema.SelectionHistory.subtitle)
                entry.setValue(source.rawValue, forKey: CoreDataSchema.SelectionHistory.source)
                entry.setValue(Date(), forKey: CoreDataSchema.SelectionHistory.selectedAt)

                try self.trimSelectionHistoryIfNeeded(in: context)

                if context.hasChanges {
                    try context.save()
                }
            }
        } catch {
            return
        }
    }

    func loadLatestSelectionID() async -> String? {
        do {
            return try await performBackgroundTask { context in
                let request = NSFetchRequest<NSDictionary>(entityName: CoreDataSchema.Entity.selectionHistory)
                request.resultType = .dictionaryResultType
                request.propertiesToFetch = [CoreDataSchema.SelectionHistory.itemID]
                request.sortDescriptors = [
                    NSSortDescriptor(key: CoreDataSchema.SelectionHistory.selectedAt, ascending: false)
                ]
                request.fetchLimit = 1

                return try context.fetch(request).first?[CoreDataSchema.SelectionHistory.itemID] as? String
            }
        } catch {
            return nil
        }
    }

    private func trimSelectionHistoryIfNeeded(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataSchema.Entity.selectionHistory)
        request.sortDescriptors = [
            NSSortDescriptor(key: CoreDataSchema.SelectionHistory.selectedAt, ascending: false)
        ]

        let entries = try context.fetch(request)
        guard entries.count > AppConstants.Library.historyCap else {
            return
        }

        for entry in entries.dropFirst(AppConstants.Library.historyCap) {
            context.delete(entry)
        }
    }

    private func performBackgroundTask<T: Sendable>(
        _ action: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let value = try action(context)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
