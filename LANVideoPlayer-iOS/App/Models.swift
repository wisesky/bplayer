import Foundation
import UniformTypeIdentifiers

struct PlaylistItem: Identifiable, Codable, Equatable {
    enum Source: Codable, Equatable {
        case remoteURL(URL)
        case bookmarkedFile(BookmarkedFile)

        private enum CodingKeys: String, CodingKey { case type, url, file }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .remoteURL(let url):
                try container.encode("remoteURL", forKey: .type)
                try container.encode(url.absoluteString, forKey: .url)
            case .bookmarkedFile(let file):
                try container.encode("bookmarkedFile", forKey: .type)
                try container.encode(file, forKey: .file)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "remoteURL":
                let urlString = try container.decode(String.self, forKey: .url)
                guard let url = URL(string: urlString) else {
                    throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Invalid URL string")
                }
                self = .remoteURL(url)
            case "bookmarkedFile":
                let file = try container.decode(BookmarkedFile.self, forKey: .file)
                self = .bookmarkedFile(file)
            default:
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unknown Source type"))
            }
        }
    }

    var id: UUID = UUID()
    var title: String
    var source: Source
    var lastPlaybackTime: Double

    var displayURL: URL? {
        switch source {
        case .remoteURL(let url): return url
        case .bookmarkedFile(let file): return file.resolvedURL
        }
    }
}

struct BookmarkedFile: Codable, Equatable {
    let bookmarkData: Data
    var resolvedURL: URL? {
        try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], bookmarkDataIsStale: nil)
    }
}

final class PlaylistStore: ObservableObject {
    @Published var items: [PlaylistItem] = [] {
        didSet { persist() }
    }

    private let storageURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("playlist.json")
    }()

    init() {
        load()
    }

    func addRemote(urlString: String) {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme?.hasPrefix("http") == true else { return }
        let item = PlaylistItem(title: url.lastPathComponent.isEmpty ? url.host ?? url.absoluteString : url.lastPathComponent, source: .remoteURL(url), lastPlaybackTime: 0)
        items.append(item)
    }

    func addBookmarkedFile(url: URL) throws {
        let bookmark = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
        let file = BookmarkedFile(bookmarkData: bookmark)
        let title = url.lastPathComponent
        let item = PlaylistItem(title: title, source: .bookmarkedFile(file), lastPlaybackTime: 0)
        items.append(item)
    }

    func update(item: PlaylistItem, playbackTime: Double) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = items[idx]
        updated.lastPlaybackTime = playbackTime
        items[idx] = updated
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("Failed to persist playlist: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([PlaylistItem].self, from: data)
            self.items = decoded
        } catch {
            self.items = []
        }
    }
}