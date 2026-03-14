import SwiftUI

struct SongDetailView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var viewModel: SongDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showAddToPlaylist = false

    // Auto-scroll state
    @Namespace private var topID
    @Namespace private var bottomID

    init(song: Song) {
        _viewModel = StateObject(wrappedValue: SongDetailViewModel(song: song))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Marker for auto-scroll top
                    Color.clear.frame(height: 1).id(topID)
                    
                    // Header Info
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Controls (Sticky-ish behavior via pinned views if using Section, but here just part of scroll for simplicity or we can use safe area inset)
                    // For better UX, let's put controls in a pinned section header or floating bottom bar.
                    // The prompt asked for "sticky" transpose/capo.
                    // Sticky headers work best in LazyVStack with pinnedViews.
                    LazyVStack(pinnedViews: [.sectionHeaders]) {
                        Section(header: controlsHeader) {
                            
                            // Segmented Control
                            Picker("Mod", selection: $viewModel.mode) {
                                ForEach(SongDetailViewModel.DisplayMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            
                            // Content
                            contentView
                                .padding(.horizontal)
                                .padding(.bottom, 100) // Space for bottom
                        }
                    }
                    
                    // Marker for auto-scroll bottom
                    Color.clear.frame(height: 1).id(bottomID)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.song.sarkiadi)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showAddToPlaylist = true }) {
                            Image(systemName: "text.badge.plus")
                                .foregroundColor(.primary)
                        }
                        Button(action: {
                            dataService.toggleFavorite(viewModel.song.id)
                        }) {
                            Image(systemName: dataService.isFavorite(viewModel.song.id) ? "heart.fill" : "heart")
                                .foregroundColor(dataService.isFavorite(viewModel.song.id) ? .red : .primary)
                        }
                    }
                }
            }
            // Auto-scroll logic
            .onChange(of: viewModel.isAutoScrolling) { isScrolling in
                if isScrolling {
                    withAnimation(.linear(duration: 200 / viewModel.scrollSpeed)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                } else {
                    withAnimation {
                        proxy.scrollTo(topID, anchor: .top)
                    }
                }
            }
            .sheet(isPresented: $showAddToPlaylist) {
                SelectPlaylistSheet(songId: viewModel.song.id)
            }
        }
    }

    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.song.sanatci)
                .font(.title3)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // Key Chip
                if let key = viewModel.song.orjinal_ton, !key.isEmpty {
                    ChipView(text: "Ton: \(key)", icon: "music.note")
                }
                // Capo Chip
                if let capo = viewModel.song.kapo, capo != "0" {
                    ChipView(text: "Kapo: \(capo)", icon: "music.mic")
                }
                // Easy Key
                if let easyKey = viewModel.song.kolay_akor_ton, !easyKey.isEmpty {
                    ChipView(text: "Kolay: \(easyKey)", icon: "star.fill", color: .green.opacity(0.1), textColor: .green)
                }
            }
        }
    }
    
    private var controlsHeader: some View {
        VStack(spacing: 12) {
            // Transpose & Capo
            HStack {
                // Transpose
                ControlStepper(
                    title: "Transpoze",
                    value: $viewModel.transposeAmount,
                    range: -12...12,
                    display: { val in val > 0 ? "+\(val)" : "\(val)" }
                )
                
                Spacer()
                
                // Capo
                ControlStepper(
                    title: "Kapo",
                    value: $viewModel.currentCapo,
                    range: 0...12,
                    display: { "\($0)" }
                )
            }
            
            // Auto Scroll
            HStack {
                Button(action: { viewModel.toggleAutoScroll() }) {
                    HStack {
                        Image(systemName: viewModel.isAutoScrolling ? "pause.fill" : "play.fill")
                        Text(viewModel.isAutoScrolling ? "Durdur" : "Otomatik Kaydır")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(viewModel.isAutoScrolling ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .foregroundColor(viewModel.isAutoScrolling ? .red : .blue)
                    .cornerRadius(8)
                }
                
                if viewModel.isAutoScrolling {
                    Slider(value: $viewModel.scrollSpeed, in: 1...10, step: 0.5)
                        .frame(width: 100)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground).opacity(0.95))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.mode {
        case .lyricsAndChords:
            lyricsView
        case .cards:
            cardsView
        case .rhythm:
            rhythmView
        }
    }

    // MARK: - Repertuarim.com Style Lyrics + Chords

    /// Groups consecutive chord+lyrics blocks into pairs for proper rendering
    private var groupedBlocks: [(chord: RenderBlock?, lyric: RenderBlock?)] {
        let blocks = viewModel.transposedBlocks
        var groups: [(chord: RenderBlock?, lyric: RenderBlock?)] = []
        var i = 0
        while i < blocks.count {
            let block = blocks[i]
            switch block.type {
            case .chords:
                if i + 1 < blocks.count && blocks[i + 1].type == .lyrics {
                    groups.append((chord: block, lyric: blocks[i + 1]))
                    i += 2
                } else {
                    groups.append((chord: block, lyric: nil))
                    i += 1
                }
            case .block:
                groups.append((chord: block, lyric: block))
                i += 1
            default:
                groups.append((chord: nil, lyric: block))
                i += 1
            }
        }
        return groups
    }

    private var lyricsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Used chords summary at top
            let chords = viewModel.song.chords
            if !chords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chords, id: \.self) { chord in
                            let transposed = MusicTheory.transposeChord(chord, semitones: viewModel.transposeAmount)
                            Text(transposed)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DS.Color.accent.opacity(0.15))
                                .foregroundColor(DS.Color.accent)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 12)
                }

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                    .padding(.bottom, 4)
            }

            // Lyrics with chords
            let groups = groupedBlocks
            if !groups.isEmpty {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    renderGroup(chord: group.chord, lyric: group.lyric)
                }
            } else {
                Text("Sarki sozleri yuklenemedi.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func renderGroup(chord: RenderBlock?, lyric: RenderBlock?) -> some View {
        if let lyric = lyric, lyric.type == .empty || lyric.type == .spacer {
            Color.clear.frame(height: 20)
        } else if let lyric = lyric, lyric.type == .meta, let content = lyric.content {
            HStack {
                Rectangle()
                    .fill(DS.Color.accent)
                    .frame(width: 3, height: 20)
                    .cornerRadius(1.5)
                Text(content)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DS.Color.accent)
                Spacer()
            }
            .padding(.vertical, 10)
        } else {
            VStack(alignment: .leading, spacing: 1) {
                // Chord line
                if let chord = chord, chord.type != .lyrics {
                    let chordText = chord.type == .block ? chord.chords : chord.content
                    if let chordStr = chordText, !chordStr.isEmpty {
                        styledChordLine(chordStr)
                            .padding(.top, 14)
                    }
                }
                // Lyrics line
                if let lyric = lyric {
                    let lyricsText = lyric.type == .block ? lyric.lyrics : lyric.content
                    if let lyricsStr = lyricsText, !lyricsStr.isEmpty {
                        Text(lyricsStr)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// Renders chord line with each chord name highlighted
    private func styledChordLine(_ chordString: String) -> some View {
        let parts = parseChordLine(chordString)
        return HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if part.isChord {
                    Text(part.text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(DS.Color.accent)
                } else {
                    // Use a fixed-width space to maintain alignment
                    Text(String(repeating: " ", count: part.text.count))
                        .font(.system(size: 15))
                }
            }
        }
    }

    private struct ChordPart {
        let text: String
        let isChord: Bool
    }

    private func parseChordLine(_ line: String) -> [ChordPart] {
        var parts: [ChordPart] = []
        var current = ""
        var inChord = false

        for char in line {
            if char == " " {
                if inChord && !current.isEmpty {
                    parts.append(ChordPart(text: current, isChord: true))
                    current = ""
                    inChord = false
                }
                current += String(char)
            } else {
                if !inChord && !current.isEmpty {
                    parts.append(ChordPart(text: current, isChord: false))
                    current = ""
                }
                inChord = true
                current += String(char)
            }
        }
        if !current.isEmpty {
            parts.append(ChordPart(text: current, isChord: inChord))
        }
        return parts
    }
    
    private var cardsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Kullanilan Akorlar")
                .font(.headline)

            let chords = viewModel.song.chords

            if chords.isEmpty {
                Text("Akor bilgisi bulunamadi.")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: DS.Spacing.m) {
                    ForEach(chords, id: \.self) { chord in
                        let transposed = MusicTheory.transposeChord(chord, semitones: viewModel.transposeAmount)
                        ChordDiagramView(chordName: transposed, size: .medium)
                    }
                }
            }
        }
    }
    
    private var rhythmView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ritimler")
                .font(.headline)
            
            if let rhythms = viewModel.song.ritimler, !rhythms.isEmpty {
                ForEach(rhythms, id: \.self) { rhythm in
                    HStack {
                        Image(systemName: "metronome")
                            .foregroundColor(.orange)
                        Text(rhythm)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
                }
            } else {
                Text("Bu şarkı için ritim bilgisi eklenmemiş.")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Simple Helper Components for SongDetailView
struct ChipView: View {
    let text: String
    let icon: String
    var color: Color = .blue.opacity(0.1)
    var textColor: Color = .blue
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color)
        .foregroundColor(textColor)
        .cornerRadius(16)
    }
}

struct ControlStepper<T: Numeric & Comparable & Strideable>: View {
    let title: String
    @Binding var value: T
    let range: ClosedRange<T>
    let display: (T) -> String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                Button(action: { if value > range.lowerBound { value -= 1 } }) {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .background(Color(uiColor: .secondarySystemBackground))
                }
                
                Text(display(value))
                    .font(.headline)
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                
                Button(action: { if value < range.upperBound { value += 1 } }) {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .background(Color(uiColor: .secondarySystemBackground))
                }
            }
            .cornerRadius(8)
        }
    }
}

// MARK: - Select Playlist Sheet
struct SelectPlaylistSheet: View {
    @EnvironmentObject var dataService: SongDataService
    @Environment(\.dismiss) var dismiss
    let songId: Int
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""

    var body: some View {
        NavigationStack {
            Group {
                if dataService.playlists.isEmpty {
                    VStack(spacing: DS.Spacing.m) {
                        Spacer()
                        EmptyStateView(
                            icon: "music.note.list",
                            title: "Henuz Liste Yok",
                            message: "Once bir calma listesi olusturun.",
                            actionTitle: "Yeni Liste Olustur",
                            action: { showNewPlaylistAlert = true }
                        )
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(dataService.playlists) { playlist in
                            let isInPlaylist = playlist.songIds.contains(songId)
                            Button {
                                if isInPlaylist {
                                    dataService.removeSongFromPlaylist(songId: songId, playlistId: playlist.id)
                                } else {
                                    dataService.addSongToPlaylist(songId: songId, playlistId: playlist.id)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.name)
                                            .font(.body)
                                        Text("\(playlist.songIds.count) sarki")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: isInPlaylist ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isInPlaylist ? DS.Color.accent : .secondary)
                                        .font(.title3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Listeye Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewPlaylistAlert = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Yeni Liste", isPresented: $showNewPlaylistAlert) {
                TextField("Liste adi", text: $newPlaylistName)
                Button("Olustur") {
                    let name = newPlaylistName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        dataService.createPlaylist(name: name)
                        newPlaylistName = ""
                    }
                }
                Button("Iptal", role: .cancel) { newPlaylistName = "" }
            }
        }
    }
}
