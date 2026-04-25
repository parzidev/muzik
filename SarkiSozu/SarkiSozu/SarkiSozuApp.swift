import SwiftUI

@main
struct SarkiSozuApp: App {
    @StateObject private var dataService = SongDataService.shared

    init() {
        MetricsService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .preferredColorScheme(dataService.darkMode ? .dark : nil)
        }
    }
}
