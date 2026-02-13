//
//  ContentView.swift
//  EmbeddedMusicPlayer
//
//  Created by Zachary Coriarty on 2/11/27.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeminiHomeView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistence = PersistenceController.preview
        let viewModel = AppViewModel(
            musicLibraryService: MusicLibraryService(),
            playbackService: MusicPlaybackService(),
            persistenceStore: MediaPersistenceStore(container: persistence.container)
        )

        return ContentView()
            .environmentObject(viewModel)
    }
}
