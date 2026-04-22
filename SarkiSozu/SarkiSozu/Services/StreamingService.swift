import UIKit

enum StreamingService {
    static func spotifyURL(artist: String, title: String) -> URL? {
        let query = "\(artist) \(title)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appScheme = URL(string: "spotify:search:\(query)")
        if let app = appScheme, UIApplication.shared.canOpenURL(app) {
            return app
        }
        return URL(string: "https://open.spotify.com/search/\(query)")
    }

    static func appleMusicURL(artist: String, title: String) -> URL? {
        let query = "\(artist) \(title)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://music.apple.com/tr/search?term=\(query)")
    }

    static func youtubeURL(artist: String, title: String) -> URL? {
        let query = "\(artist) \(title)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appScheme = URL(string: "youtube://results?search_query=\(query)")
        if let app = appScheme, UIApplication.shared.canOpenURL(app) {
            return app
        }
        return URL(string: "https://www.youtube.com/results?search_query=\(query)")
    }

    static func open(_ url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url)
    }
}
