import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataService: SongDataService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Keşfet", systemImage: "music.note.house")
            }

            NavigationStack {
                SongsView()
            }
            .tabItem {
                Label("Şarkılar", systemImage: "music.note.list")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Ara", systemImage: "magnifyingglass")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favoriler", systemImage: "heart")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Ayarlar", systemImage: "gearshape")
            }
        }
        .tint(DS.Color.accent)
        .overlay {
            if dataService.isLoading {
                ZStack {
                    Color(uiColor: .systemBackground)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Şarkılar yükleniyor...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
