//
//  EmbeddedMusicPlayerApp.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/26.
//

import SwiftUI
import CoreData

@main
struct EmbeddedMusicPlayerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
