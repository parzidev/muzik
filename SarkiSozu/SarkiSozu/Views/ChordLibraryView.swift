import SwiftUI

struct ChordLibraryView: View {
    let chordGroups: [(String, [String])] = [
        ("Majör", ["A", "B", "C", "D", "E", "F", "G"]),
        ("Minör", ["Am", "Bm", "Cm", "Dm", "Em", "Fm", "F#m", "Gm"]),
        ("Yedili", ["A7", "B7", "C7", "D7", "E7", "F7", "G7"]),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.l) {
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
    }
}
