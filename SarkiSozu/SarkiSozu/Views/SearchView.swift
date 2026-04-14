import SwiftUI

struct SearchView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var viewModel: SearchViewModel
    @State private var showingFilters = false
    
    init() {
        _viewModel = StateObject(wrappedValue: SearchViewModel(service: SongDataService.shared))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.m) {
                // MARK: - Search Bar (Custom or .searchable)
                // We use .searchable below, so this content is the "Results" or "Empty State"
                
                if viewModel.searchText.isEmpty {
                    // MARK: - Recent Searches
                    if !viewModel.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            HStack {
                                DS.Typography.headline("Son Aramalar")
                                Spacer()
                                Button("Temizle") {
                                    viewModel.clearRecentSearches()
                                }
                                .font(.subheadline)
                                .foregroundColor(DS.Color.accent)
                            }
                            .padding(.horizontal, DS.Spacing.m)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Spacing.s) {
                                    ForEach(viewModel.recentSearches, id: \.self) { term in
                                        FilterChip(title: term, isSelected: false) {
                                            viewModel.searchText = term
                                        }
                                    }
                                }
                                .padding(.horizontal, DS.Spacing.m)
                            }
                        }
                        .padding(.top, DS.Spacing.s)
                    } else {
                        // Empty Start State
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "Şarkı Ara",
                            message: "Şarkı adı veya sanatçı arayarak başlayın.",
                            actionTitle: nil,
                            action: nil
                        )
                    }
                } else {
                    // MARK: - Results List
                    if viewModel.searchResults.isEmpty {
                        EmptyStateView(
                            icon: "doc.text.magnifyingglass",
                            title: "Sonuç Bulunamadı",
                            message: "\"\(viewModel.searchText)\" için sonuç yok.",
                            actionTitle: "Filtreleri Temizle",
                            action: {
                                viewModel.selectedKey = "Tümü"
                                viewModel.selectedCapo = 0
                                viewModel.favoritesOnly = false
                                viewModel.performSearch(query: viewModel.searchText)
                            }
                        )
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.searchResults) { song in
                                NavigationLink(destination: SongDetailView(song: song)) {
                                    SongRowView(song: song)
                                    .padding(.horizontal, DS.Spacing.m)
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    viewModel.addRecentSearch(viewModel.searchText)
                                })
                                
                                Divider()
                                    .padding(.leading, DS.Spacing.xxl + DS.Spacing.m)
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(DS.CornerRadius.large)
                        .padding(.horizontal, DS.Spacing.m)
                    }
                }
            }
            .padding(.vertical, DS.Spacing.m)
        }
        .searchable(text: $viewModel.searchText, prompt: "Şarkı veya sanatçı ara")
        .navigationTitle("Ara")
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .symbolVariant(viewModel.isFiltering ? .fill : .none)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFilterSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Filter Sheet
struct SearchFilterSheet: View {
    @ObservedObject var viewModel: SearchViewModel // Shared VM
    @Environment(\.dismiss) var dismiss
    
    let keys = ["Tümü", "Am", "Em", "C", "G", "D", "A", "E", "Bm", "F#m"] // Sample
    
    var body: some View {
        NavigationView {
            Form {
                Section("Ton (Key)") {
                    Picker("Ton", selection: $viewModel.selectedKey) {
                        ForEach(keys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Kapo") {
                    Stepper("Kapo: \(viewModel.selectedCapo)", value: $viewModel.selectedCapo, in: 0...12)
                }
                
                Section {
                    Toggle("Sadece Favorilerim", isOn: $viewModel.favoritesOnly)
                }
                
                Section {
                    Button("Filtreleri Sıfırla") {
                        viewModel.selectedKey = "Tümü"
                        viewModel.selectedCapo = 0
                        viewModel.favoritesOnly = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uygula") {
                        viewModel.performSearch(query: viewModel.searchText)
                        dismiss()
                    }
                }
            }
        }
    }
}
