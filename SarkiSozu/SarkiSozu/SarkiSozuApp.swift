import SwiftUI

@main
struct SarkiSozuApp: App {
    @StateObject private var dataService = SongDataService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .preferredColorScheme(dataService.darkMode ? .dark : nil)
        }
    }
}
