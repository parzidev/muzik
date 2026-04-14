import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var viewModel: HomeViewModel
    @State private var randomSong: Song?
    @State private var showRandomSong = false

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(dataService: .shared))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {

                // MARK: - Quick Actions
                VStack(spacing: DS.Spacing.xs) {
                    HStack(spacing: DS.Spacing.s) {
                        // Random song
                        Button {
                            if let song = dataService.songs.randomElement() {
                                randomSong = song
                                showRandomSong = true
                            }
                        } label: {
                            quickActionCard(icon: "shuffle", title: "Rastgele", color: .purple)
                        }

                        // Can I Play
                        NavigationLink(destination: CanIPlayView()) {
                            quickActionCard(icon: "hand.raised.fingers.spread", title: "Çalabilir misin?", color: .orange)
                        }

                        // Practice
                        NavigationLink(destination: PracticeView()) {
                            quickActionCard(icon: "timer", title: "Pratik", color: .green)
                        }

                        // Capo calc
                        NavigationLink(destination: CapoCalculatorView()) {
                            quickActionCard(icon: "guitars", title: "Kapo", color: .blue)
                        }
                    }

                    HStack(spacing: DS.Spacing.s) {
                        // Metronome
                        NavigationLink(destination: MetronomeView()) {
                            quickActionCard(icon: "metronome", title: "Metronom", color: .red)
                        }

                        // Tuner
                        NavigationLink(destination: TunerView()) {
                            quickActionCard(icon: "tuningfork", title: "Akort", color: .cyan)
                        }

                        // Chord Detection
                        NavigationLink(destination: ChordDetectorView()) {
                            quickActionCard(icon: "waveform", title: "Akor Tespiti", color: .indigo)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.m)

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
                    SectionHeader(title: "Popüler", actionTitle: "Tümünü Gör", action: {})

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
            viewModel.loadData()
        }
        .navigationDestination(isPresented: $showRandomSong) {
            if let song = randomSong {
                SongDetailView(song: song)
            }
        }
    }

    // MARK: - Quick Action Card

    private func quickActionCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 11))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.medium)
    }
}
