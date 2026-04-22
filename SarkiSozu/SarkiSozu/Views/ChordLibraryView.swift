import SwiftUI

struct ChordLibraryView: View {
    @StateObject private var customStore = CustomChordStore.shared
    @State private var showEditor = false
    @State private var editingChord: CustomChord?

    let chordGroups: [(String, [String])] = [
        ("Majör", ["A", "B", "C", "D", "E", "F", "G"]),
        ("Minör", ["Am", "Bm", "Cm", "Dm", "Em", "Fm", "F#m", "Gm"]),
        ("Yedili", ["A7", "B7", "C7", "D7", "E7", "F7", "G7"]),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.l) {
                // Custom chords section
                customChordsSection

                ForEach(chordGroups, id: \.0) { group in
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text(group.0)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal, DS.Spacing.m)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: DS.Spacing.m) {
                            ForEach(group.1, id: \.self) { chord in
                                ChordDiagramView(chordName: chord, size: .large)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.m)
                    }
                }
            }
            .padding(.vertical, DS.Spacing.m)
        }
        .navigationTitle("Akor Kutuphanesi")
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.tap()
                    editingChord = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            ChordEditorView(existing: editingChord)
        }
    }

    @ViewBuilder
    private var customChordsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack {
                Text("Özel Akorlarım")
                    .font(.title3).fontWeight(.semibold)
                Spacer()
                Text("\(customStore.chords.count)")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DS.Spacing.m)

            if customStore.chords.isEmpty {
                HStack(spacing: DS.Spacing.s) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.title3)
                        .foregroundColor(DS.Color.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kendi akorlarını ekle")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Üst sağdaki + tuşuna bas ve parmak pozisyonunu çiz.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(DS.Color.accent.opacity(0.08))
                .cornerRadius(DS.CornerRadius.medium)
                .padding(.horizontal, DS.Spacing.m)
                .onTapGesture {
                    editingChord = nil
                    showEditor = true
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: DS.Spacing.m) {
                    ForEach(customStore.chords) { chord in
                        ChordDiagramView(chordName: chord.name, size: .large)
                            .onTapGesture {
                                editingChord = chord
                                showEditor = true
                            }
                            .contextMenu {
                                Button {
                                    editingChord = chord
                                    showEditor = true
                                } label: {
                                    Label("Düzenle", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    customStore.delete(chord)
                                    HapticManager.notify(.warning)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, DS.Spacing.m)
            }
        }
    }
}
