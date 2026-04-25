import Foundation
#if canImport(MetricKit)
import MetricKit
#endif

/// Subscribes to MetricKit payloads (perf metrics + crash/hang/diagnostic reports)
/// and persists them to Documents/MetricReports/ for later inspection or sharing.
///
/// Apple delivers these payloads at most once per day; crash/diagnostic payloads
/// arrive shortly after the next launch following a relevant event.
final class MetricsService: NSObject {
    static let shared = MetricsService()

    private let directoryName = "MetricReports"
    private let maxReports = 30

    private override init() {
        super.init()
    }

    func start() {
        #if canImport(MetricKit) && !targetEnvironment(simulator)
        MXMetricManager.shared.add(self)
        #endif
    }

    /// Folder where reports are stored (created lazily).
    var reportsDirectory: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = docs.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Returns existing report file URLs sorted newest first.
    func savedReports() -> [URL] {
        guard let dir = reportsDirectory else { return [] }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return files.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lDate > rDate
        }
    }

    private func write(_ data: Data, prefix: String) {
        guard let dir = reportsDirectory else { return }
        let timestamp = Self.fileTimestampFormatter.string(from: Date())
        let url = dir.appendingPathComponent("\(prefix)-\(timestamp).json")
        do {
            try data.write(to: url, options: .atomic)
            pruneOldReports(in: dir)
            NSLog("MetricsService: wrote \(url.lastPathComponent) (\(data.count) bytes)")
        } catch {
            NSLog("MetricsService: failed to write report: \(error.localizedDescription)")
        }
    }

    private func pruneOldReports(in dir: URL) {
        let files = savedReports()
        guard files.count > maxReports else { return }
        for url in files.suffix(from: maxReports) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static let fileTimestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

#if canImport(MetricKit)
extension MetricsService: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            write(payload.jsonRepresentation(), prefix: "metric")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            write(payload.jsonRepresentation(), prefix: "diagnostic")
        }
    }
}
#endif
