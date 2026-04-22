import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataService: SongDataService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            } else {
                adaptiveRoot
            }
        }
    }

    @ViewBuilder
    private var adaptiveRoot: some View {
        if horizontalSizeClass == .regular {
            iPadSplitView
        } else {
            mainTabView
        }
    }

    // MARK: - iPhone / Compact Layout

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

    // MARK: - iPad / Regular Layout

    private var iPadSplitView: some View {
        iPadRootView()
            .environmentObject(dataService)
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

// MARK: - iPad Sidebar Layout

private enum SidebarSection: String, Hashable, CaseIterable, Identifiable {
    case home
    case songs
    case search
    case favorites
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Keşfet"
        case .songs: return "Şarkılar"
        case .search: return "Ara"
        case .favorites: return "Favoriler"
        case .settings: return "Ayarlar"
        }
    }

    var icon: String {
        switch self {
        case .home: return "music.note.house"
        case .songs: return "music.note.list"
        case .search: return "magnifyingglass"
        case .favorites: return "heart"
        case .settings: return "gearshape"
        }
    }
}

private struct iPadRootView: View {
    @State private var selection: SidebarSection? = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarSection.allCases, selection: $selection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.icon)
                }
            }
            .navigationTitle("SarkıSözü")
            .listStyle(.sidebar)
        } detail: {
            NavigationStack {
                detailView(for: selection ?? .home)
            }
        }
        .tint(DS.Color.accent)
    }

    @ViewBuilder
    private func detailView(for section: SidebarSection) -> some View {
        switch section {
        case .home: HomeView()
        case .songs: SongsView()
        case .search: SearchView()
        case .favorites: FavoritesView()
        case .settings: SettingsView()
        }
    }
}
