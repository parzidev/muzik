import SwiftUI

// MARK: - Practice Timer + Stats

struct PracticeView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var practiceManager = PracticeManager.shared

    @State private var selectedDuration: Int = 30 // minutes
    @State private var isSessionActive = false
    @State private var showHistory = false

    let durations = [10, 15, 20, 30, 45, 60]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                // Streak card
                streakCard

                if isSessionActive {
                    activeSessionView
                } else {
                    startSessionView
                }

                // Stats
                statsSection

                // Recent sessions
                recentSessionsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Pratik")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: DS.Spacing.m) {
            VStack(spacing: 4) {
                Text("\(practiceManager.currentStreak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("Gün Seri")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 50)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        let practiced = practiceManager.didPractice(daysAgo: 6 - day)
                        Circle()
                            .fill(practiced ? Color.orange : Color(uiColor: .tertiarySystemFill))
                            .frame(width: 24, height: 24)
                            .overlay(
                                practiced ? Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white) : nil
                            )
                    }
                }
                Text("Son 7 gün")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.large)
        .padding(.horizontal)
    }

    // MARK: - Start Session

    private var startSessionView: some View {
        VStack(spacing: DS.Spacing.m) {
            Text("Pratik Süresi")
                .font(.headline)

            // Duration selector
            HStack(spacing: 8) {
                ForEach(durations, id: \.self) { mins in
                    Button {
                        selectedDuration = mins
                    } label: {
                        Text("\(mins)dk")
                            .font(.subheadline)
                            .fontWeight(selectedDuration == mins ? .bold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedDuration == mins ? DS.Color.accent : Color(uiColor: .tertiarySystemFill))
                            .foregroundColor(selectedDuration == mins ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }

            Button {
                practiceManager.startSession(durationMinutes: selectedDuration)
                isSessionActive = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Pratiğe Başla")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DS.Color.accent)
                .cornerRadius(DS.CornerRadius.medium)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.large)
        .padding(.horizontal)
    }

    // MARK: - Active Session

    private var activeSessionView: some View {
        VStack(spacing: DS.Spacing.m) {
            Text("Pratik Devam Ediyor")
                .font(.headline)
                .foregroundColor(DS.Color.accent)

            // Timer display
            Text(practiceManager.formattedRemainingTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: practiceManager.progress)
                    .stroke(DS.Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: practiceManager.progress)
            }
            .frame(width: 120, height: 120)

            Text("Şarkı açarak pratik yapabilirsin!")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button {
                    practiceManager.endSession()
                    isSessionActive = false
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Bitir")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(DS.CornerRadius.medium)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.large)
        .padding(.horizontal)
        .onReceive(practiceManager.timer) { _ in
            practiceManager.tick()
            if practiceManager.remainingSeconds <= 0 {
                practiceManager.endSession()
                isSessionActive = false
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("İstatistikler")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: DS.Spacing.s) {
                statCard(title: "Toplam", value: "\(practiceManager.totalSessions)", subtitle: "oturum", icon: "music.note", color: .blue)
                statCard(title: "Bu Hafta", value: "\(practiceManager.sessionsThisWeek)", subtitle: "oturum", icon: "calendar", color: .green)
                statCard(title: "Toplam", value: practiceManager.formattedTotalTime, subtitle: "süre", icon: "clock", color: .purple)
            }
            .padding(.horizontal)
        }
    }

    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.m)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.medium)
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            if !practiceManager.sessions.isEmpty {
                Text("Son Oturumlar")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(practiceManager.sessions.prefix(10)) { session in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.formattedDate)
                                    .font(.subheadline)
                                Text("\(session.durationMinutes) dakika")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        Divider().padding(.leading, 44)
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(DS.CornerRadius.large)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Practice Manager

class PracticeManager: ObservableObject {
    static let shared = PracticeManager()

    @Published var sessions: [PracticeSession] = []
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isActive = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let sessionsKey = "practiceSessions"

    init() {
        loadSessions()
    }

    var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
    }

    var formattedRemainingTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())

        // Check if practiced today
        if !sessions.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // Check yesterday (allow gap for today not done yet)
            date = calendar.date(byAdding: .day, value: -1, to: date)!
            if !sessions.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return 0
            }
        }

        while sessions.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            streak += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    var totalSessions: Int { sessions.count }

    var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { $0.date > weekAgo }.count
    }

    var formattedTotalTime: String {
        let totalMins = sessions.reduce(0) { $0 + $1.durationMinutes }
        if totalMins < 60 {
            return "\(totalMins)dk"
        }
        return "\(totalMins / 60)sa"
    }

    func didPractice(daysAgo: Int) -> Bool {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        return sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func startSession(durationMinutes: Int) {
        totalSeconds = durationMinutes * 60
        remainingSeconds = totalSeconds
        isActive = true
    }

    func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
    }

    func endSession() {
        guard isActive else { return }
        isActive = false
        let elapsed = totalSeconds - remainingSeconds
        let mins = max(elapsed / 60, 1)
        let session = PracticeSession(date: Date(), durationMinutes: mins)
        sessions.insert(session, at: 0)
        saveSessions()
        remainingSeconds = 0
        totalSeconds = 0
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let saved = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            sessions = saved
        }
    }
}

// MARK: - Practice Session Model

struct PracticeSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let durationMinutes: Int

    init(date: Date, durationMinutes: Int) {
        self.id = UUID()
        self.date = date
        self.durationMinutes = durationMinutes
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM, HH:mm"
        return formatter.string(from: date)
    }
}
