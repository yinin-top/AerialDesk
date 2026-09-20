import Testing
import Foundation
@testable import AerialDesk

@Test func settingsRoundTrip() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("aerialdesk-settings-\(UUID().uuidString)").path
    defer { try? FileManager.default.removeItem(atPath: dir) }

    let store = SettingsStore(directory: dir)
    var settings = Settings()
    settings.playbackEnabled = true
    settings.videoPath = "/tmp/demo.mov"
    settings.screenIDs = [1, 2, 3]
    settings.launchAtLogin = true
    store.save(settings)
    #expect(store.load() == settings)
}

@Test func loadMissingReturnsDefaults() {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("aerialdesk-settings-\(UUID().uuidString)").path
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let settings = SettingsStore(directory: dir).load()
    #expect(settings == Settings())
    #expect(settings.playbackEnabled == false)
    #expect(settings.screenIDs.isEmpty)
}

@Test func corruptSettingsBackedUpAndReplaced() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("aerialdesk-settings-\(UUID().uuidString)").path
    defer { try? FileManager.default.removeItem(atPath: dir) }
    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    try Data("{ not json".utf8).write(to: URL(fileURLWithPath: dir + "/settings.json"))

    #expect(SettingsStore(directory: dir).load() == Settings())
    #expect(FileManager.default.fileExists(atPath: dir + "/settings.json.bad"))
}
