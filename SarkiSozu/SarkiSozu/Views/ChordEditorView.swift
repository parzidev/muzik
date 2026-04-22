import SwiftUI

struct ChordEditorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var store = CustomChordStore.shared

    let existing: CustomChord?

    @State private var name: String
    @State private var frets: [Int]
    @State private var baseFret: Int
    @State private var barreFret: Int?
    @State private var barreFromString: Int?
    @State private var barreToString: Int?
    @State private var showDeleteConfirm = false

    private let visibleFrets = 5
    private let stringCount = 6

    init(existing: CustomChord? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _frets = State(initialValue: existing?.frets ?? Array(repeating: -1, count: 6))
        _baseFret = State(initialValue: existing?.baseFret ?? 1)
        _barreFret = State(initialValue: existing?.barreFret)
        _barreFromString = State(initialValue: existing?.barreFromString)
        _barreToString = State(initialValue: existing?.barreToString)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.m) {
                    nameField
                    fretboardEditor
                    baseFretControl
                    barreControl
                    stringMuteRow
                    tips
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "Yeni Akor" : "Akoru Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if existing != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
            .alert("Akoru sil?", isPresented: $showDeleteConfirm) {
                Button("Sil", role: .destructive) {
                    if let chord = existing {
                        store.delete(chord)
                        HapticManager.notify(.warning)
                        dismiss()
                    }
                }
                Button("İptal", role: .cancel) {}
            }
        }
    }

    // MARK: - Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Akor Adı")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Örn: Cadd9", text: $name)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
        }
    }

    // MARK: - Fretboard

    private var fretboardEditor: some View {
        VStack(spacing: DS.Spacing.s) {
            HStack {
                Text("Parmak Pozisyonları")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Button {
                    HapticManager.tap()
                    frets = Array(repeating: -1, count: 6)
                    barreFret = nil
                    barreFromString = nil
                    barreToString = nil
                } label: {
                    Label("Temizle", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
            }
            // Preview
            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                ChordFretboardView(data: currentData(), width: 140)
                    .frame(maxWidth: .infinity)
            }
            // Interactive grid
            fretboardGrid
                .padding(.vertical, 4)
        }
        .padding(DS.Spacing.m)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.medium)
    }

    private var fretboardGrid: some View {
        VStack(spacing: 4) {
            // String labels header (low E → high E)
            HStack(spacing: 0) {
                ForEach(0..<stringCount, id: \.self) { s in
                    Text(stringLabel(s))
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            // Grid
            ForEach(0..<visibleFrets, id: \.self) { fretRow in
                let fret = fretRow + 1
                HStack(spacing: 0) {
                    ForEach(0..<stringCount, id: \.self) { s in
                        fretCell(string: s, fret: fret)
                    }
                }
            }
        }
    }

    private func fretCell(string: Int, fret: Int) -> some View {
        let active = frets[string] == fret
        let muted = frets[string] == -1
        let inBarre: Bool = {
            guard let bf = barreFret, let from = barreFromString, let to = barreToString else { return false }
            return fret == bf && string >= from && string <= to
        }()
        return Button {
            HapticManager.selection()
            if active {
                frets[string] = -1
            } else {
                frets[string] = fret
            }
        } label: {
            ZStack {
                Rectangle()
                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                if inBarre {
                    Circle()
                        .fill(DS.Color.accent.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
                if active {
                    Circle()
                        .fill(DS.Color.accent)
                        .frame(width: 28, height: 28)
                    Text("\(fret + baseFret - 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else if muted && fret == 1 {
                    // Show X on top row for muted strings
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }

    private func stringLabel(_ s: Int) -> String {
        let v = frets[s]
        if v == -1 { return "✕" }
        if v == 0 { return "○" }
        return "\(v + baseFret - 1)"
    }

    // MARK: - Base fret

    private var baseFretControl: some View {
        HStack {
            Text("Başlangıç Perdesi")
                .font(.subheadline)
            Spacer()
            Stepper("\(baseFret). perde", value: $baseFret, in: 1...15)
                .labelsHidden()
            Text("\(baseFret).").font(.subheadline).monospacedDigit()
        }
        .padding(.horizontal, DS.Spacing.s)
    }

    // MARK: - Barre

    private var barreControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Barre")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { barreFret != nil },
                    set: { on in
                        if on {
                            barreFret = 1
                            barreFromString = 0
                            barreToString = 5
                        } else {
                            barreFret = nil
                            barreFromString = nil
                            barreToString = nil
                        }
                    }
                ))
                .labelsHidden()
            }
            if barreFret != nil {
                HStack {
                    Text("Perde")
                    Stepper("", value: Binding(
                        get: { barreFret ?? 1 },
                        set: { barreFret = $0 }
                    ), in: 1...visibleFrets)
                    .labelsHidden()
                    Text("\(barreFret ?? 1)").monospacedDigit()
                    Spacer()
                }
                .font(.caption)

                HStack {
                    Text("Teller")
                    Picker("", selection: Binding(
                        get: { barreFromString ?? 0 },
                        set: { barreFromString = $0 }
                    )) {
                        ForEach(0..<6) { Text("\($0 + 1)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text("-")
                    Picker("", selection: Binding(
                        get: { barreToString ?? 5 },
                        set: { barreToString = $0 }
                    )) {
                        ForEach(0..<6) { Text("\($0 + 1)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .font(.caption)
            }
        }
        .padding(DS.Spacing.s)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.small)
    }

    // MARK: - Mute/Open row

    private var stringMuteRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Açık / Susturulmuş Teller")
                .font(.caption).foregroundColor(.secondary)
            HStack(spacing: 6) {
                ForEach(0..<stringCount, id: \.self) { s in
                    Menu {
                        Button("Susturulmuş ✕") { frets[s] = -1 }
                        Button("Açık ○") { frets[s] = 0 }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Tel \(s + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(frets[s] == -1 ? "✕" : (frets[s] == 0 ? "○" : "\(frets[s] + baseFret - 1)"))
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .cornerRadius(DS.CornerRadius.small)
                    }
                }
            }
        }
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("İpucu").font(.caption).fontWeight(.semibold)
            Text("• Perdeye dokunarak parmak ekle, tekrar dokunarak sustur")
            Text("• Başlangıç perdesi ile yüksek pozisyonlu akorlar çizebilirsin")
            Text("• Barre toggle'ı ile birden fazla teli tek parmakla bastır")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func currentData() -> ChordData {
        let mapped: [Int?] = frets.map { $0 < 0 ? nil : $0 }
        var barRange: ClosedRange<Int>? = nil
        if let from = barreFromString, let to = barreToString, from <= to {
            barRange = from...to
        }
        return ChordData(
            frets: mapped,
            baseFret: baseFret,
            barFret: barreFret,
            barStrings: barRange
        )
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var chord = existing ?? CustomChord(name: trimmed)
        chord.name = trimmed
        chord.frets = frets
        chord.baseFret = baseFret
        chord.barreFret = barreFret
        chord.barreFromString = barreFromString
        chord.barreToString = barreToString
        if existing == nil {
            store.add(chord)
        } else {
            store.update(chord)
        }
        HapticManager.success()
        dismiss()
    }
}
