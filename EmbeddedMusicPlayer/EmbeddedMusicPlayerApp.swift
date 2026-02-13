//
//  EmbeddedMusicPlayerApp.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI
import CoreData

@main
struct EmbeddedMusicPlayerApp: App {
    private let persistenceController: PersistenceController

    @StateObject private var viewModel: AppViewModel

    init() {
        let persistence = PersistenceController.shared
        persistenceController = persistence

        let musicLibraryService = MusicLibraryService()
        let playbackService = MusicPlaybackService()
        let persistenceStore = MediaPersistenceStore(container: persistence.container)

        _viewModel = StateObject(
            wrappedValue: AppViewModel(
                musicLibraryService: musicLibraryService,
                playbackService: playbackService,
                persistenceStore: persistenceStore
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.font, AppConstants.Typography.body())
                .preferredColorScheme(.dark)
        }
    }
}
