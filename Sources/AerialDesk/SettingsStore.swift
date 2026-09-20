import Foundation

struct Settings: Codable, Equatable {
    var playbackEnabled = false
    var videoPath = ""             // "" = auto: newest discovered aerial
    var screenIDs: [UInt32] = []   // [] = all displays
    var launchAtLogin = false
}

/// settings.json persistence in ~/Library/Application Support/AerialDesk/.
/// Corrupt files are backed up as settings.json.bad and replaced by defaults.
final class SettingsStore {
    let directory: String
    var path: String { directory + "/settings.json" }
    private var badPath: String { directory + "/settings.json.bad" }

    init(directory: String = NSHomeDirectory() + "/Library/Application Support/AerialDesk") {
        self.directory = directory
    }

    func load() -> Settings {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        guard let data = FileManager.default.contents(atPath: path) else { return Settings() }
        if let s = try? JSONDecoder().decode(Settings.self, from: data) { return s }
        try? data.write(to: URL(fileURLWithPath: badPath))
        return Settings()
    }

    func save(_ settings: Settings) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }
}
