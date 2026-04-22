import Foundation
import Combine

/// Syncs user data (favorites, notes, playlists, custom chords) across devices
/// via iCloud Key-Value Store (NSUbiquitousKeyValueStore).
///
/// Total storage limit: 1 MB, per-key 1 MB, max 1024 keys — plenty for our needs.
@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published var iCloudEnabled: Bool = UserDefaults.standard.bool(forKey: "icloudSyncEnabled")

    // Keys
    private let kFavorites = "sync.favorites.v1"
    private let kNotes = "sync.notes.v1"
    private let kPlaylists = "sync.playlists.v1"
    private let kCustomChords = "sync.customChords.v1"
    private let kRecent = "sync.recent.v1"

    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                self?.handleRemoteChange(note)
            }
        }
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Enable / Disable

    func setEnabled(_ enabled: Bool) {
        iCloudEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "icloudSyncEnabled")
        if enabled {
            pullAll()
            pushAll()
            store.synchronize()
        }
    }

    // MARK: - Push (local → iCloud)

    func publishFavorites(_ ids: Set<Int>) {
        guard iCloudEnabled else { return }
        if let data = try? JSONEncoder().encode(Array(ids)) {
            store.set(data, forKey: kFavorites)
            store.synchronize()
            lastSyncDate = Date()
        }
    }

    func publishNotes(_ notes: [Int: String]) {
        guard iCloudEnabled else { return }
        if let data = try? JSONEncoder().encode(notes) {
            store.set(data, forKey: kNotes)
            store.synchronize()
            lastSyncDate = Date()
        }
    }

    func publishPlaylists(_ data: Data) {
        guard iCloudEnabled else { return }
        store.set(data, forKey: kPlaylists)
        store.synchronize()
        lastSyncDate = Date()
    }

    func publishCustomChords(_ data: Data) {
        guard iCloudEnabled else { return }
        store.set(data, forKey: kCustomChords)
        store.synchronize()
        lastSyncDate = Date()
    }

    func publishRecent(_ ids: [Int]) {
        guard iCloudEnabled else { return }
        if let data = try? JSONEncoder().encode(ids) {
            store.set(data, forKey: kRecent)
            store.synchronize()
            lastSyncDate = Date()
        }
    }

    private func pushAll() {
        let ds = SongDataService.shared
        publishFavorites(ds.favorites)
        publishNotes(ds.songNotes)
        if let playlistData = try? JSONEncoder().encode(ds.playlists) {
            publishPlaylists(playlistData)
        }
        if let data = UserDefaults.standard.data(forKey: "customChords.v1") {
            publishCustomChords(data)
        }
        publishRecent(ds.recentlyViewed)
    }

    // MARK: - Pull (iCloud → local)

    func pullAll() {
        guard iCloudEnabled else { return }
        isSyncing = true
        defer { isSyncing = false }

        let ds = SongDataService.shared

        if let data = store.data(forKey: kFavorites),
           let ids = try? JSONDecoder().decode([Int].self, from: data) {
            ds.favorites = Set(ids)
        }

        if let data = store.data(forKey: kNotes),
           let notes = try? JSONDecoder().decode([Int: String].self, from: data) {
            ds.songNotes = notes
        }

        if let data = store.data(forKey: kPlaylists),
           let playlists = try? JSONDecoder().decode([Playlist].self, from: data) {
            ds.playlists = playlists
        }

        if let data = store.data(forKey: kCustomChords),
           let chords = try? JSONDecoder().decode([CustomChord].self, from: data) {
            CustomChordStore.shared.replaceAll(with: chords)
        }

        if let data = store.data(forKey: kRecent),
           let ids = try? JSONDecoder().decode([Int].self, from: data) {
            ds.recentlyViewed = ids
        }

        lastSyncDate = Date()
    }

    // MARK: - Remote change

    private func handleRemoteChange(_ notification: Notification) {
        guard iCloudEnabled else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

        let ds = SongDataService.shared

        for key in changedKeys {
            switch key {
            case kFavorites:
                if let data = store.data(forKey: kFavorites),
                   let ids = try? JSONDecoder().decode([Int].self, from: data) {
                    ds.favorites = Set(ids)
                }
            case kNotes:
                if let data = store.data(forKey: kNotes),
                   let notes = try? JSONDecoder().decode([Int: String].self, from: data) {
                    ds.songNotes = notes
                }
            case kPlaylists:
                if let data = store.data(forKey: kPlaylists),
                   let playlists = try? JSONDecoder().decode([Playlist].self, from: data) {
                    ds.playlists = playlists
                }
            case kCustomChords:
                if let data = store.data(forKey: kCustomChords),
                   let chords = try? JSONDecoder().decode([CustomChord].self, from: data) {
                    CustomChordStore.shared.replaceAll(with: chords)
                }
            case kRecent:
                if let data = store.data(forKey: kRecent),
                   let ids = try? JSONDecoder().decode([Int].self, from: data) {
                    ds.recentlyViewed = ids
                }
            default: break
            }
        }
        lastSyncDate = Date()
    }
}
