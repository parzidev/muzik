import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var viewModel: HomeViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(dataService: .shared))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                // MARK: - Son Açılanlar Section
                if !viewModel.recentSongs.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        SectionHeader(title: "Son Açılanlar", actionTitle: nil, action: nil)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DS.Spacing.m) {
                                ForEach(viewModel.recentSongs) { song in
                                    NavigationLink(destination: SongDetailView(song: song)) {
                                        SongCardView(
                                            title: song.displayName,
                                            artist: song.displayArtist,
                                            footnote: song.displayKey
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            dataService.toggleFavorite(song.id)
                                        } label: {
                                            Label(dataService.isFavorite(song.id) ? "Favorilerden Çıkar" : "Favorilere Ekle", systemImage: dataService.isFavorite(song.id) ? "heart.fill" : "heart")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, DS.Spacing.m)
                        }
                    }
                }
                
                // MARK: - Popüler Section
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    SectionHeader(title: "Popüler", actionTitle: "Tümünü Gör", action: {
                        // Navigate to full list (optional)
                    })
                    
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.popularSongs.prefix(15)) { song in
                            NavigationLink(destination: SongDetailView(song: song)) {
                                SongRowView(song: song)
                                .padding(.horizontal, DS.Spacing.m)
                            }
                            .buttonStyle(.plain)
                            
                            if song.id != viewModel.popularSongs.prefix(15).last?.id {
                                Divider()
                                    .padding(.leading, DS.Spacing.xxl + DS.Spacing.m)
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(DS.CornerRadius.large)
                    .padding(.horizontal, DS.Spacing.m)
                }
            }
            .padding(.vertical, DS.Spacing.m)
        }
        .navigationTitle("Keşfet")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            // Sync the view model with the shared data service
            // This is a bridge between the old Service pattern and new ViewModel
            // In a refactor, we might pass dataService into init more cleaner.
            // For now, we manually reload.
            // Note: HomeViewModel.loadData() pulls from its internal 'dataService' property.
            // We need to make sure 'viewModel.dataService' is the SAME instance as 'dataService' environment object?
            // Actually, because SongDataService is a class (singleton-ish usage here), if we passed a new instance in init, it might be empty if data isn't static.
            // SongDataService loads JSON on init. So a new instance *will* have data, but it won't share state (favorites/recents) unless those are persisted to UserDefaults (which they are!).
            // So: new instance is fine for reading data.
            // Sharing state: Favorites/Recents are backed by UserDefaults in SongDataService.
            // So separate instances will sync via UserDefaults (mostly).
            // However, in-memory updates won't reflect immediately if we don't share the instance.
            // HACK: Re-assign the environment service to the VM.
            // But we can't easily assign to 'private var dataService' inside StateObject from outside.
            // We will just rely on loadData() fetching from UserDefaults/JSON which is fine.
            viewModel.loadData()
        }
    }
}
