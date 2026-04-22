import SwiftUI

@main
struct SarkiSozuApp: App {
    @StateObject private var dataService = SongDataService.shared
    @StateObject private var proManager = ProManager.shared
    @StateObject private var syncManager = SyncManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .environmentObject(proManager)
                .environmentObject(syncManager)
                .preferredColorScheme(dataService.darkMode ? .dark : nil)
                .onAppear {
                    if syncManager.iCloudEnabled {
                        syncManager.pullAll()
                    }
                }
        }
    }
}
