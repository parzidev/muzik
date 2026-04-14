import SwiftUI

struct SongDetailView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var viewModel: SongDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showAddToPlaylist = false
    @State private var showNotes = false
    @State private var showSetlist = false
    @State private var noteText = ""
    @State private var scrollOffset: CGFloat = 0

    // Auto-scroll
    @State private var autoScrollTimer: Timer?
    @State private var scrollProxy: ScrollViewProxy?

    init(song: Song) {
        _viewModel = StateObject(wrappedValue: SongDetailViewModel(song: song))
    }

    private var fontSize: CGFloat {
        CGFloat(dataService.fontSize)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 1).id("top")

                    // Header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Controls + Content
                    LazyVStack(pinnedViews: [.sectionHeaders]) {
                        Section(header: controlsHeader) {
                            // Display mode picker
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
                                .padding(.bottom, 100)
                        }
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
            }
            .onAppear {
                scrollProxy = proxy
                dataService.addToRecent(viewModel.song.id)
            }
            .onDisappear {
                stopAutoScroll()
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
                        .lineLimit(1)
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
            .sheet(isPresented: $showAddToPlaylist) {
                SelectPlaylistSheet(songId: viewModel.song.id)
            }
            .sheet(item: $viewModel.selectedChord) { chord in
                ChordPopupView(chordName: chord)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showNotes) {
                SongNotesSheet(songId: viewModel.song.id, noteText: $noteText)
                    .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $showSetlist) {
                SetlistView(songs: [viewModel.song])
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: ArtistDetailView(artistName: viewModel.song.sanatci)) {
                HStack(spacing: 4) {
                    Text(viewModel.song.sanatci)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            .buttonStyle(.plain)

            // Key / Capo / Easy Key chips
            HStack(spacing: 8) {
                if let key = viewModel.song.orjinal_ton, !key.isEmpty {
                    if viewModel.keyChanged, let currentKey = viewModel.currentKey {
                        ChipView(text: "\(key) → \(currentKey)", icon: "music.note", color: .orange.opacity(0.15), textColor: .orange)
                    } else {
                        ChipView(text: "Ton: \(key)", icon: "music.note")
                    }
                }
                if let capo = viewModel.song.kapo, capo != "0" {
                    ChipView(text: "Kapo: \(capo)", icon: "music.mic")
                }
                if let easyKey = viewModel.song.kolay_akor_ton, !easyKey.isEmpty {
                    ChipView(text: "Kolay: \(easyKey)", icon: "star.fill", color: .green.opacity(0.1), textColor: .green)
                }

                // Difficulty badge
                let diff = viewModel.song.difficulty
                if diff != .unknown {
                    let diffColor: Color = {
                        switch diff {
                        case .easy: return .green
                        case .medium: return .blue
                        case .hard: return .orange
                        case .expert: return .red
                        case .unknown: return .gray
                        }
                    }()
                    ChipView(text: diff.rawValue, icon: diff.icon, color: diffColor.opacity(0.1), textColor: diffColor)
                }
            }

            // Action buttons row
            HStack(spacing: 12) {
                // Concert mode
                Button {
                    showSetlist = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tv")
                        Text("Konser Modu")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(16)
                }

                // Notes
                Button {
                    noteText = dataService.getNote(for: viewModel.song.id)
                    showNotes = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: dataService.hasNote(for: viewModel.song.id) ? "note.text" : "note.text.badge.plus")
                        Text("Notlarım")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.teal.opacity(0.1))
                    .foregroundColor(.teal)
                    .cornerRadius(16)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Controls Header (sticky)

    private var controlsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                ControlStepper(
                    title: "Transpoze",
                    value: $viewModel.transposeAmount,
                    range: -12...12,
                    display: { val in val > 0 ? "+\(val)" : "\(val)" }
                )

                Spacer()

                ControlStepper(
                    title: "Kapo",
                    value: $viewModel.currentCapo,
                    range: 0...12,
                    display: { "\($0)" }
                )
            }

            // Auto Scroll
            HStack {
                Button(action: { toggleAutoScroll() }) {
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
                        .onChange(of: viewModel.scrollSpeed) { _, _ in
                            restartAutoScroll()
                        }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground).opacity(0.95))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
    }

    // MARK: - Auto Scroll

    private func toggleAutoScroll() {
        viewModel.isAutoScrolling.toggle()
        if viewModel.isAutoScrolling {
            startAutoScroll()
        } else {
            stopAutoScroll()
        }
    }

    private func startAutoScroll() {
        stopAutoScroll()
        // Scroll speed: 1 = very slow, 10 = fast
        // Timer fires every 0.05s, scrolls by (speed * 0.5) points
        let interval: TimeInterval = 0.05
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // We can't directly control ScrollView offset with a timer in SwiftUI easily,
            // so we use the single-shot animation approach but with a calculated duration
        }
        // Use a long linear animation based on speed
        let duration = max(300.0 / viewModel.scrollSpeed, 10.0)
        withAnimation(.linear(duration: duration)) {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func restartAutoScroll() {
        if viewModel.isAutoScrolling {
            startAutoScroll()
        }
    }

    // MARK: - Content

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

    // MARK: - Lyrics + Chords

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
            // Chord summary bar
            let chords = viewModel.transposedChords
            if !chords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chords, id: \.self) { chord in
                            Button {
                                viewModel.selectedChord = chord
                            } label: {
                                Text(chord)
                                    .font(.system(size: fontSize * 0.85, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DS.Color.accent.opacity(0.15))
                                    .foregroundColor(DS.Color.accent)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                    .padding(.bottom, 4)
            }

            // Grouped lyrics
            let groups = groupedBlocks
            if !groups.isEmpty {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    renderGroup(chord: group.chord, lyric: group.lyric)
                }
            } else {
                Text("Şarkı sözleri yüklenemedi.")
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
                    .font(.system(size: fontSize * 0.9, weight: .bold))
                    .foregroundColor(DS.Color.accent)
                Spacer()
            }
            .padding(.vertical, 10)
        } else {
            VStack(alignment: .leading, spacing: 1) {
                if let chord = chord, chord.type != .lyrics {
                    let chordText = chord.type == .block ? chord.chords : chord.content
                    if let chordStr = chordText, !chordStr.isEmpty {
                        tappableChordLine(chordStr)
                            .padding(.top, 14)
                    }
                }
                if let lyric = lyric {
                    let lyricsText = lyric.type == .block ? lyric.lyrics : lyric.content
                    if let lyricsStr = lyricsText, !lyricsStr.isEmpty {
                        Text(lyricsStr)
                            .font(.system(size: fontSize))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// Renders chord line with tappable chord names
    private func tappableChordLine(_ chordString: String) -> some View {
        let parts = parseChordLine(chordString)
        return HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if part.isChord {
                    Button {
                        viewModel.selectedChord = part.text.trimmingCharacters(in: .whitespaces)
                    } label: {
                        Text(part.text)
                            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(DS.Color.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(String(repeating: " ", count: part.text.count))
                        .font(.system(size: fontSize, design: .monospaced))
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

    // MARK: - Chord Cards

    private var cardsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Kullanılan Akorlar")
                .font(.headline)

            let chords = viewModel.transposedChords
            if chords.isEmpty {
                Text("Akor bilgisi bulunamadı.")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: DS.Spacing.m) {
                    ForEach(chords, id: \.self) { chord in
                        ChordDiagramView(chordName: chord, size: .medium)
                            .onTapGesture {
                                viewModel.selectedChord = chord
                            }
                    }
                }
            }
        }
    }

    // MARK: - Rhythm

    private var rhythmView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ritimler")
                .font(.headline)

            if let rhythms = viewModel.song.ritimler, !rhythms.isEmpty {
                let realRhythms = rhythms.filter { !$0.contains("Henüz") }
                if realRhythms.isEmpty {
                    Text("Bu şarkı için ritim bilgisi henüz eklenmemiş.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(realRhythms, id: \.self) { rhythm in
                        HStack {
                            Image(systemName: "metronome")
                                .foregroundColor(.orange)
                            Text(rhythm)
                                .font(.system(size: fontSize, design: .monospaced))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Bu şarkı için ritim bilgisi henüz eklenmemiş.")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - String Identifiable for sheet
extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Chord Popup View

struct ChordPopupView: View {
    let chordName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.l) {
                ChordDiagramView(chordName: chordName, size: .large)

                if ChordDatabase.lookup(chordName) == nil {
                    Text("Bu akor için diyagram henüz eklenmemiş.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, DS.Spacing.l)
            .navigationTitle(chordName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Helper Views (unchanged)

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
                            title: "Henüz Liste Yok",
                            message: "Önce bir çalma listesi oluşturun.",
                            actionTitle: "Yeni Liste Oluştur",
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
                                        Text("\(playlist.songIds.count) şarkı")
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
                TextField("Liste adı", text: $newPlaylistName)
                Button("Oluştur") {
                    let name = newPlaylistName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        dataService.createPlaylist(name: name)
                        newPlaylistName = ""
                    }
                }
                Button("İptal", role: .cancel) { newPlaylistName = "" }
            }
        }
    }
}

// MARK: - Song Notes Sheet

struct SongNotesSheet: View {
    @EnvironmentObject var dataService: SongDataService
    @Environment(\.dismiss) var dismiss
    let songId: Int
    @Binding var noteText: String

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.m) {
                Text("Bu şarkıya özel notlarınızı yazın.\nÖrn: \"2. nakarat öncesi yavaşlat\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(DS.CornerRadius.medium)

                    if noteText.isEmpty {
                        Text("Notunuzu buraya yazın...")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            .padding(.horizontal, 12)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Notlarım")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        dataService.setNote(for: songId, note: noteText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
