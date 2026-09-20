import Foundation

struct VideoOption: Equatable {
    let name: String
    let path: String
}

/// Discovers playable wallpaper videos:
/// - macOS 14+ caches Apple "Aerial" videos under com.apple.wallpaper
/// - macOS 13.x cached them under com.apple.idleassetsd (nested)
/// - macOS ships a couple of aerial videos inside /System
/// Apple's videos are only *discovered locally* — nothing is bundled or downloaded here.
enum VideoLibrary {
    static let videoExtensions: Set<String> = ["mov", "mp4", "m4v"]

    static func wallpaperAerialsDir(home: String = NSHomeDirectory()) -> String {
        home + "/Library/Application Support/com.apple.wallpaper/aerials/videos"
    }

    static func legacyAerialsDir(home: String = NSHomeDirectory()) -> String {
        home + "/Library/Application Support/com.apple.idleassetsd/Customer"
    }

    static func systemVideosDir() -> String {
        "/System/Library/Wallpapers/.default"
    }

    /// All playable videos: user's aerials (newest first) followed by system-bundled ones.
    static func availableVideos(home: String = NSHomeDirectory()) -> [VideoOption] {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none

        var options: [VideoOption] = []
        let userDirs = [wallpaperAerialsDir(home: home), legacyAerialsDir(home: home)]
        for dir in userDirs {
            for (url, mtime) in scanVideos(dir: dir, recursive: dir == legacyAerialsDir(home: home)) {
                options.append(VideoOption(name: "Aerial · " + df.string(from: mtime), path: url.path))
            }
        }
        for (url, _) in scanVideos(dir: systemVideosDir(), recursive: false) {
            let base = url.deletingPathExtension().lastPathComponent
            options.append(VideoOption(name: base + " (System)", path: url.path))
        }
        return options
    }

    /// Videos inside one directory, filtered by extension, newest modification first.
    /// Returns (url, modificationDate) pairs; testable with an injected directory.
    static func scanVideos(dir: String, recursive: Bool) -> [(url: URL, mtime: Date)] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir) else { return [] }
        let root = URL(fileURLWithPath: dir)
        var urls: [URL] = []
        if recursive {
            guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                return []
            }
            for case let url as URL in enumerator
            where videoExtensions.contains(url.pathExtension.lowercased()) {
                urls.append(url)
            }
        } else {
            guard let names = try? fm.contentsOfDirectory(atPath: dir) else { return [] }
            urls = names.map { root.appendingPathComponent($0) }
                .filter { videoExtensions.contains($0.pathExtension.lowercased()) }
        }
        return urls.compactMap { url in
            let mtime = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return (url: url, mtime: mtime)
        }
        .sorted { $0.mtime > $1.mtime }
    }

    /// Configured path wins when it exists; otherwise the first (newest) option.
    static func resolveVideo(_ configured: String, available: [VideoOption]) -> String? {
        if !configured.isEmpty && FileManager.default.fileExists(atPath: configured) { return configured }
        return available.first?.path
    }
}
