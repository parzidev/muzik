import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataService: SongDataService
    @State private var selectedTab: Tab? = .home
    @State private var visibility: NavigationSplitViewVisibility = .all
    
    enum Tab: String, CaseIterable, Identifiable {
        case home, songs, favorites, playlists, settings
        var id: String { self.rawValue }
    }
    
    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadLayout
        } else {
            iPhoneLayout
        }
        #else
        iPadLayout // Mac Catalyst
        #endif
    }
    
    // MARK: - iPhone Layout (Tab Bar)
    var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Keşfet", systemImage: "music.note.house")
            }
            .tag(Tab.home)
            
            NavigationStack {
                SongsView()
            }
            .tabItem {
                Label("Şarkılar", systemImage: "music.mic")
            }
            .tag(Tab.songs)
            
            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favoriler", systemImage: "heart")
            }
            .tag(Tab.favorites)
            
            NavigationStack {
                PlaylistsView()
            }
            .tabItem {
                Label("Listeler", systemImage: "music.note.list")
            }
            .tag(Tab.playlists)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Ayarlar", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .accentColor(DS.Color.accent)
    }
    
    // MARK: - iPad/Mac Layout (Sidebar)
    var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            List(selection: $selectedTab) {
                NavigationLink(value: Tab.home) {
                    Label("Keşfet", systemImage: "music.note.house")
                }
                NavigationLink(value: Tab.songs) {
                    Label("Şarkılar", systemImage: "music.mic")
                }
                NavigationLink(value: Tab.favorites) {
                    Label("Favoriler", systemImage: "heart")
                }
                NavigationLink(value: Tab.playlists) {
                    Label("Listeler", systemImage: "music.note.list")
                }
                NavigationLink(value: Tab.settings) {
                    Label("Ayarlar", systemImage: "gearshape")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ŞarkıSözÜ")
        } detail: {
            if let tab = selectedTab {
                switch tab {
                case .home:
                    NavigationStack { HomeView() }
                case .songs:
                    NavigationStack { SongsView() }
                case .favorites:
                    NavigationStack { FavoritesView() }
                case .playlists:
                    NavigationStack { PlaylistsView() }
                case .settings:
                    NavigationStack { SettingsView() }
                }
            } else {
                Text("Select a tab")
            }
        }
        .accentColor(DS.Color.accent)
    }
}
