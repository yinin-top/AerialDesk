import Testing
import Foundation
@testable import AerialDesk

private func makeTempDir(_ label: String) -> String {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("aerialdesk-tests-\(label)-\(UUID().uuidString)").path
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    return dir
}

private func touch(_ path: String, daysAgo: Double) {
    FileManager.default.createFile(atPath: path, contents: Data([1]))
    try? FileManager.default.setAttributes([.modificationDate: Date().addingTimeInterval(-daysAgo * 86400)],
                                           ofItemAtPath: path)
}

@Test func scanVideosFiltersExtensionsAndSortsNewestFirst() throws {
    let dir = makeTempDir("scan")
    defer { try? FileManager.default.removeItem(atPath: dir) }
    touch(dir + "/old.mov", daysAgo: 300)
    touch(dir + "/new.mp4", daysAgo: 1)
    touch(dir + "/notes.txt", daysAgo: 0)

    let videos = VideoLibrary.scanVideos(dir: dir, recursive: false)
    #expect(videos.count == 2)
    #expect(videos[0].url.lastPathComponent == "new.mp4")
    #expect(videos[1].url.lastPathComponent == "old.mov")
}

@Test func scanVideosRecursiveAndMissingDir() throws {
    let dir = makeTempDir("recursive")
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let nested = dir + "/sub/01"
    try FileManager.default.createDirectory(atPath: nested, withIntermediateDirectories: true)
    touch(dir + "/top.mov", daysAgo: 5)
    touch(nested + "/deep.mov", daysAgo: 2)

    #expect(VideoLibrary.scanVideos(dir: dir, recursive: true).count == 2)
    #expect(VideoLibrary.scanVideos(dir: dir, recursive: false).count == 1)
    #expect(VideoLibrary.scanVideos(dir: "/nonexistent-aerialdesk", recursive: true).isEmpty)
}

@Test func resolveVideoFallsBackToNewestWhenMissing() throws {
    let existing = makeTempDir("resolve") + "/exists.mov"
    defer { try? FileManager.default.removeItem(atPath: existing) }
    FileManager.default.createFile(atPath: existing, contents: nil)

    // configured path exists on disk → used as-is, even if not in the discovered list
    let fallbackOptions = [VideoOption(name: "newest", path: existing)]
    #expect(VideoLibrary.resolveVideo(existing, available: fallbackOptions) == existing)
    // configured path missing on disk → fall back to first available
    #expect(VideoLibrary.resolveVideo("/nope.mov", available: fallbackOptions) == existing)
    #expect(VideoLibrary.resolveVideo("", available: fallbackOptions) == existing)
    #expect(VideoLibrary.resolveVideo("", available: []) == nil)
}

@Test func availableVideosUsesSystemDirWhenUserDirsAbsent() throws {
    // temp home has no aerial caches; system dir injected so the test
    // doesn't depend on the machine actually shipping system wallpapers
    let home = makeTempDir("home")
    let sysDir = makeTempDir("system")
    defer {
        try? FileManager.default.removeItem(atPath: home)
        try? FileManager.default.removeItem(atPath: sysDir)
    }
    touch(sysDir + "/Golden Gate.mov", daysAgo: 90)

    let videos = VideoLibrary.availableVideos(home: home, systemDir: sysDir)
    #expect(videos.count == 1)
    #expect(videos[0].path == sysDir + "/Golden Gate.mov")
    #expect(videos[0].name == "Golden Gate (System)")
}
