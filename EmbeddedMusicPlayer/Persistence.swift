//
//  Persistence.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext

        let favorite = NSEntityDescription.insertNewObject(
            forEntityName: CoreDataSchema.Entity.favoriteTrack,
            into: context
        )
        favorite.setValue("preview-track", forKey: CoreDataSchema.FavoriteTrack.id)
        favorite.setValue("Black Friday", forKey: CoreDataSchema.FavoriteTrack.title)
        favorite.setValue("Lost Frequencies", forKey: CoreDataSchema.FavoriteTrack.artistName)
        favorite.setValue("Work Session", forKey: CoreDataSchema.FavoriteTrack.albumTitle)
        favorite.setValue(Date(), forKey: CoreDataSchema.FavoriteTrack.updatedAt)

        let history = NSEntityDescription.insertNewObject(
            forEntityName: CoreDataSchema.Entity.selectionHistory,
            into: context
        )
        history.setValue(UUID(), forKey: CoreDataSchema.SelectionHistory.id)
        history.setValue("preview-track", forKey: CoreDataSchema.SelectionHistory.itemID)
        history.setValue("Black Friday", forKey: CoreDataSchema.SelectionHistory.title)
        history.setValue("Lost Frequencies, Work Session", forKey: CoreDataSchema.SelectionHistory.subtitle)
        history.setValue(RecommendationSource.initialLoad.rawValue, forKey: CoreDataSchema.SelectionHistory.source)
        history.setValue(Date(), forKey: CoreDataSchema.SelectionHistory.selectedAt)

        do {
            try context.save()
        } catch {
            assertionFailure("Preview Core Data save failed: \(error)")
        }

        return persistence
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "EmbeddedMusicPlayer")

        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true

            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Persistent store load failed: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
