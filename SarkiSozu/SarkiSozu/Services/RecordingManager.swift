import Foundation
import AVFoundation
import Combine

/// Metadata for a single recording, persisted as JSON.
struct Recording: Codable, Identifiable {
    let id: UUID
    let songId: Int
    let filename: String
    let createdAt: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), songId: Int, filename: String, createdAt: Date = Date(), duration: TimeInterval) {
        self.id = id
        self.songId = songId
        self.filename = filename
        self.createdAt = createdAt
        self.duration = duration
    }

    var url: URL {
        RecordingManager.recordingsDirectory.appendingPathComponent(filename)
    }

    var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: createdAt)
    }

    var formattedDuration: String {
        let total = Int(duration.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

/// Manages audio recording and playback with A/B loop support.
@MainActor
final class RecordingManager: NSObject, ObservableObject {
    static let shared = RecordingManager()

    @Published private(set) var recordings: [Recording] = []
    @Published private(set) var isRecording = false
    @Published private(set) var isPlaying = false
    @Published private(set) var recordingElapsed: TimeInterval = 0
    @Published private(set) var playbackPosition: TimeInterval = 0
    @Published private(set) var playbackDuration: TimeInterval = 0
    @Published var lastError: String?

    /// A/B loop markers (seconds). If both non-nil and A < B, playback loops this region.
    @Published var loopPointA: TimeInterval?
    @Published var loopPointB: TimeInterval?
    @Published var isLoopEnabled: Bool = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordTimer: Timer?
    private var playTimer: Timer?
    private var recordingStartDate: Date?
    private var currentPlayingURL: URL?

    private let metadataKey = "savedRecordings"

    nonisolated static var recordingsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    override init() {
        super.init()
        loadRecordings()
    }

    // MARK: - Public API

    func recordings(for songId: Int) -> [Recording] {
        recordings.filter { $0.songId == songId }.sorted { $0.createdAt > $1.createdAt }
    }

    func startRecording(songId: Int) {
        guard !isRecording else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            lastError = "Mikrofon oturumu açılamadı: \(error.localizedDescription)"
            return
        }

        let filename = "song_\(songId)_\(Int(Date().timeIntervalSince1970)).m4a"
        let url = Self.recordingsDirectory.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.delegate = self
            rec.prepareToRecord()
            rec.record()
            self.recorder = rec
            self.isRecording = true
            self.recordingStartDate = Date()
            self.recordingElapsed = 0
            startRecordTimer()
        } catch {
            lastError = "Kayıt başlatılamadı: \(error.localizedDescription)"
        }
    }

    func stopRecording(songId: Int) {
        guard isRecording, let rec = recorder else { return }
        let url = rec.url
        rec.stop()
        stopRecordTimer()
        isRecording = false

        let duration = rec.currentTime > 0 ? rec.currentTime : recordingElapsed
        let recording = Recording(songId: songId, filename: url.lastPathComponent, duration: duration)
        recordings.insert(recording, at: 0)
        saveRecordings()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func cancelRecording() {
        guard let rec = recorder else { return }
        let url = rec.url
        rec.stop()
        try? FileManager.default.removeItem(at: url)
        stopRecordTimer()
        isRecording = false
        recorder = nil
    }

    func play(_ recording: Recording) {
        stopPlayback()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            lastError = "Oynatma oturumu açılamadı: \(error.localizedDescription)"
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: recording.url)
            p.delegate = self
            p.prepareToPlay()
            // Seek to A if loop enabled and markers set
            if isLoopEnabled, let a = loopPointA, a < p.duration {
                p.currentTime = a
            }
            p.play()
            self.player = p
            self.currentPlayingURL = recording.url
            self.isPlaying = true
            self.playbackDuration = p.duration
            self.playbackPosition = p.currentTime
            startPlayTimer()
        } catch {
            lastError = "Oynatılamadı: \(error.localizedDescription)"
        }
    }

    func pausePlayback() {
        player?.pause()
        isPlaying = false
        stopPlayTimer()
    }

    func resumePlayback() {
        guard let p = player else { return }
        p.play()
        isPlaying = true
        startPlayTimer()
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        currentPlayingURL = nil
        isPlaying = false
        playbackPosition = 0
        playbackDuration = 0
        stopPlayTimer()
    }

    func seek(to position: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = max(0, min(position, p.duration))
        playbackPosition = p.currentTime
    }

    func delete(_ recording: Recording) {
        if currentPlayingURL == recording.url { stopPlayback() }
        try? FileManager.default.removeItem(at: recording.url)
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }

    // MARK: - A/B Loop

    func setLoopA() {
        loopPointA = playbackPosition
        // Ensure B > A
        if let b = loopPointB, b <= playbackPosition {
            loopPointB = nil
        }
    }

    func setLoopB() {
        // Only allow if greater than A
        if let a = loopPointA, playbackPosition > a {
            loopPointB = playbackPosition
            isLoopEnabled = true
        }
    }

    func clearLoop() {
        loopPointA = nil
        loopPointB = nil
        isLoopEnabled = false
    }

    // MARK: - Timers

    private func startRecordTimer() {
        stopRecordTimer()
        recordTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.recordingStartDate else { return }
                self.recordingElapsed = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopRecordTimer() {
        recordTimer?.invalidate()
        recordTimer = nil
    }

    private func startPlayTimer() {
        stopPlayTimer()
        playTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let p = self.player else { return }
                self.playbackPosition = p.currentTime

                // A/B loop enforcement
                if self.isLoopEnabled,
                   let a = self.loopPointA,
                   let b = self.loopPointB,
                   b > a,
                   p.currentTime >= b {
                    p.currentTime = a
                }
            }
        }
    }

    private func stopPlayTimer() {
        playTimer?.invalidate()
        playTimer = nil
    }

    // MARK: - Persistence

    private func saveRecordings() {
        if let data = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }

    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let saved = try? JSONDecoder().decode([Recording].self, from: data) else {
            return
        }
        // Filter out orphaned files
        recordings = saved.filter { FileManager.default.fileExists(atPath: $0.url.path) }
        if recordings.count != saved.count {
            saveRecordings()
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.lastError = error?.localizedDescription
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension RecordingManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            // If loop enabled with both markers, player won't fire this because we reset currentTime
            // This fires at natural end.
            if self.isLoopEnabled, let a = self.loopPointA, let b = self.loopPointB, b > a {
                player.currentTime = a
                player.play()
                self.isPlaying = true
                self.startPlayTimer()
            } else {
                self.isPlaying = false
                self.playbackPosition = 0
                self.stopPlayTimer()
            }
        }
    }
}
