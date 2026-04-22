import SwiftUI
import AVFoundation

struct SongRecordingSheet: View {
    let song: Song
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = RecordingManager.shared
    @EnvironmentObject var pro: ProManager

    @State private var selectedRecording: Recording?
    @State private var showDeleteConfirm: Recording?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                recordingCard
                    .padding(DS.Spacing.m)

                Divider()

                if manager.recordings(for: song.id).isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "mic.slash",
                        title: "Kayıt Yok",
                        message: "Bu şarkı için henüz kayıt yapılmamış. Yukarıdan mikrofon tuşuna bas ve çalışını kaydet.",
                        actionTitle: nil,
                        action: {}
                    )
                    Spacer()
                } else {
                    recordingsList
                }
            }
            .navigationTitle("Ses Kaydı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        HapticManager.tap()
                        manager.stopPlayback()
                        if manager.isRecording { manager.cancelRecording() }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: nil)
            }
            .alert(item: $showDeleteConfirm) { rec in
                Alert(
                    title: Text("Kaydı sil?"),
                    message: Text("\(rec.formattedDate) tarihli kayıt silinecek."),
                    primaryButton: .destructive(Text("Sil")) {
                        manager.delete(rec)
                        HapticManager.notify(.warning)
                        if selectedRecording?.id == rec.id { selectedRecording = nil }
                    },
                    secondaryButton: .cancel(Text("İptal"))
                )
            }
        }
    }

    // MARK: - Recording Card

    private var recordingCard: some View {
        VStack(spacing: DS.Spacing.m) {
            if manager.isRecording {
                recordingActiveView
            } else if let rec = selectedRecording {
                playbackView(for: rec)
            } else {
                idleView
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.m)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.large)
    }

    private var idleView: some View {
        VStack(spacing: DS.Spacing.m) {
            Text(song.sarkiadi)
                .font(.headline)
                .lineLimit(1)
            Text(song.sanatci)
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                HapticManager.impact(.medium)
                guard pro.hasProAccess else {
                    showPaywall = true
                    return
                }
                manager.startRecording(songId: song.id)
            } label: {
                ZStack {
                    Circle()
                        .fill(DS.Color.accentGradient)
                        .frame(width: 72, height: 72)
                    if pro.hasProAccess {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: DS.Color.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            }

            if pro.hasProAccess {
                Text("Kaydı Başlat")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill").foregroundColor(.orange)
                    Text("Pro özelliği")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var recordingActiveView: some View {
        VStack(spacing: DS.Spacing.m) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .opacity(manager.recordingElapsed.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : 0.3)
                Text("Kayıt Ediliyor")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            Text(formatTime(manager.recordingElapsed))
                .font(.system(size: 40, weight: .bold, design: .monospaced))

            HStack(spacing: DS.Spacing.m) {
                Button {
                    HapticManager.warning()
                    manager.cancelRecording()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.gray)
                        .clipShape(Circle())
                }

                Button {
                    HapticManager.success()
                    manager.stopRecording(songId: song.id)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
    }

    private func playbackView(for rec: Recording) -> some View {
        VStack(spacing: DS.Spacing.m) {
            VStack(spacing: 2) {
                Text(rec.formattedDate)
                    .font(.subheadline).fontWeight(.semibold)
                Text("\(rec.formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress slider
            VStack(spacing: 6) {
                Slider(
                    value: Binding(
                        get: { manager.playbackPosition },
                        set: { manager.seek(to: $0) }
                    ),
                    in: 0...max(manager.playbackDuration, 0.01)
                )
                .tint(DS.Color.accent)
                .disabled(manager.playbackDuration == 0)

                HStack {
                    Text(formatTime(manager.playbackPosition))
                        .font(.caption2).monospacedDigit()
                    Spacer()
                    if let a = manager.loopPointA {
                        Text("A: \(formatTime(a))")
                            .font(.caption2).foregroundColor(.orange)
                    }
                    if let b = manager.loopPointB {
                        Text("B: \(formatTime(b))")
                            .font(.caption2).foregroundColor(.orange)
                    }
                    Spacer()
                    Text(formatTime(manager.playbackDuration))
                        .font(.caption2).monospacedDigit()
                }
            }

            // Transport controls
            HStack(spacing: DS.Spacing.m) {
                Button {
                    HapticManager.tap()
                    manager.stopPlayback()
                    selectedRecording = nil
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }

                Button {
                    HapticManager.impact(.medium)
                    if manager.isPlaying {
                        manager.pausePlayback()
                    } else {
                        if manager.playbackPosition > 0 {
                            manager.resumePlayback()
                        } else {
                            manager.play(rec)
                        }
                    }
                } label: {
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(DS.Color.accentGradient)
                        .clipShape(Circle())
                }

                Button {
                    HapticManager.tap()
                    showDeleteConfirm = rec
                } label: {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }
            }

            // A/B loop controls
            loopControls
        }
    }

    private var loopControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    HapticManager.tap()
                    manager.setLoopA()
                } label: {
                    loopButton(label: "A Ayarla", color: manager.loopPointA != nil ? .orange : .secondary)
                }
                Button {
                    HapticManager.tap()
                    manager.setLoopB()
                } label: {
                    loopButton(label: "B Ayarla", color: manager.loopPointB != nil ? .orange : .secondary)
                }
                Button {
                    HapticManager.tap()
                    manager.clearLoop()
                } label: {
                    loopButton(label: "Temizle", color: .red.opacity(0.8))
                }
            }

            if manager.loopPointA != nil && manager.loopPointB != nil {
                Toggle(isOn: $manager.isLoopEnabled) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                        Text("A/B Döngü")
                            .font(.subheadline)
                    }
                }
                .tint(.orange)
                .padding(.horizontal, 4)
            }
        }
    }

    private func loopButton(label: String, color: Color) -> some View {
        Text(label)
            .font(.caption).fontWeight(.medium)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(DS.CornerRadius.small)
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        List {
            Section("Kayıtlarım") {
                ForEach(manager.recordings(for: song.id)) { rec in
                    Button {
                        HapticManager.tap()
                        manager.stopPlayback()
                        manager.clearLoop()
                        selectedRecording = rec
                        manager.play(rec)
                    } label: {
                        HStack(spacing: DS.Spacing.s) {
                            Image(systemName: selectedRecording?.id == rec.id ? "waveform.circle.fill" : "waveform")
                                .font(.title3)
                                .foregroundColor(selectedRecording?.id == rec.id ? DS.Color.accent : .secondary)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(rec.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedRecording?.id == rec.id && manager.isPlaying {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(DS.Color.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            showDeleteConfirm = rec
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        let mins = total / 60
        let secs = total % 60
        let ms = Int((t - Double(total)) * 10)
        return String(format: "%d:%02d.%d", mins, secs, ms)
    }
}
