import AppKit
import UniformTypeIdentifiers

/// Menu bar UI: play/stop, per-display selection, video source, launch-at-login.
/// Owns the settings state; every action persists through SettingsStore and
/// re-applies the engine immediately.
final class MenuBarController: NSObject {
    private let engine: WallpaperEngine
    private let store: SettingsStore
    private var settings: Settings
    private var item: NSStatusItem!

    /// Session-only CLI overrides (`--video`, `--screens`). Not persisted.
    private let overrideVideo: String?
    private let overrideScreens: [UInt32]?

    init(engine: WallpaperEngine, store: SettingsStore,
         overrides: (video: String?, screens: [UInt32]?) = (nil, nil)) {
        self.engine = engine
        self.store = store
        self.settings = store.load()
        self.overrideVideo = overrides.video
        self.overrideScreens = overrides.screens
        super.init()
        if overrides.video != nil { settings.playbackEnabled = true }
        engine.onDisplaysChanged = { [weak self] in self?.rebuild() }
    }

    func install() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "photo.on.rectangle.angled",
                                accessibilityDescription: "AerialDesk")
            button.image = image?.withSymbolConfiguration(.init(pointSize: 14, weight: .regular))
            button.toolTip = "AerialDesk — animated desktop wallpaper"
        }
        let menu = NSMenu()
        item.menu = menu
        menu.delegate = self
        rebuild()
        if settings.playbackEnabled { applyPlayback() }
    }

    private func rebuild() {
        guard let menu = item.menu else { return }
        menu.removeAllItems()

        let toggle = NSMenuItem(title: settings.playbackEnabled ? "⏹ Stop Playback" : "▶ Play on Desktop",
                                action: #selector(togglePlayback), keyEquivalent: "")
        toggle.target = self
        toggle.isEnabled = true
        menu.addItem(toggle)

        let status = NSMenuItem(title: statusLine(), action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        menu.addItem(displaysSubmenu())
        menu.addItem(videoSubmenu())
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.isEnabled = true
        login.state = settings.launchAtLogin ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit AerialDesk", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        menu.autoenablesItems = false
    }

    private func statusLine() -> String {
        if engine.activeDisplayCount > 0 {
            let n = engine.activeDisplayCount
            return "Playing on \(n) display\(n == 1 ? "" : "s")"
        }
        return settings.playbackEnabled ? "No video found — pick one below" : "Stopped"
    }

    private func displaysSubmenu() -> NSMenuItem {
        let parent = NSMenuItem(title: "Displays", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let all = NSMenuItem(title: "All Displays", action: #selector(useAllDisplays), keyEquivalent: "")
        all.target = self
        all.isEnabled = true
        all.state = settings.screenIDs.isEmpty ? .on : .off
        sub.addItem(all)
        sub.addItem(.separator())
        for display in ScreenRouter.displays() {
            let row = NSMenuItem(title: "\(display.name) · \(display.width)×\(display.height)",
                                 action: #selector(toggleDisplay(_:)), keyEquivalent: "")
            row.target = self
            row.isEnabled = true
            row.state = ScreenRouter.isSelected(settings.screenIDs, on: display.id) ? .on : .off
            row.representedObject = NSNumber(value: display.id)
            sub.addItem(row)
        }
        parent.submenu = sub
        return parent
    }

    private func videoSubmenu() -> NSMenuItem {
        let parent = NSMenuItem(title: "Video Source", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let videos = VideoLibrary.availableVideos()
        let current = effectiveVideoPath(available: videos)
        for video in videos {
            let row = NSMenuItem(title: video.name, action: #selector(pickVideo(_:)), keyEquivalent: "")
            row.target = self
            row.isEnabled = true
            row.state = (video.path == current) ? .on : .off
            row.representedObject = video.path
            sub.addItem(row)
        }
        sub.addItem(.separator())
        let other = NSMenuItem(title: "Choose Other Video…", action: #selector(chooseOtherVideo), keyEquivalent: "")
        other.target = self
        other.isEnabled = true
        sub.addItem(other)
        parent.submenu = sub
        return parent
    }

    /// Path the engine should use right now: CLI override > configured > auto-discovered.
    private func effectiveVideoPath(available: [VideoOption] = VideoLibrary.availableVideos()) -> String? {
        if let overrideVideo, FileManager.default.fileExists(atPath: overrideVideo) { return overrideVideo }
        return VideoLibrary.resolveVideo(settings.videoPath, available: available)
    }

    private func applyPlayback() {
        guard settings.playbackEnabled,
              let path = effectiveVideoPath(),
              FileManager.default.fileExists(atPath: path) else {
            if settings.playbackEnabled { engine.stop() }
            rebuild()
            return
        }
        let screens = (overrideScreens ?? settings.screenIDs)
        engine.apply(videoPath: path, screens: screens)
        rebuild()
    }

    // MARK: Actions

    @objc private func togglePlayback() {
        settings.playbackEnabled.toggle()
        store.save(settings)
        if settings.playbackEnabled {
            if effectiveVideoPath() == nil { chooseVideoFile() }   // nothing to play yet → pick one
            applyPlayback()
        } else {
            engine.stop()
            rebuild()
        }
    }

    @objc private func useAllDisplays() {
        settings.screenIDs = []
        store.save(settings)
        applyPlayback()
    }

    @objc private func toggleDisplay(_ sender: NSMenuItem) {
        guard let id = (sender.representedObject as? NSNumber)?.uint32Value else { return }
        settings.screenIDs = ScreenRouter.toggled(current: settings.screenIDs,
                                                  toggle: id,
                                                  allIDs: ScreenRouter.displays().map { $0.id })
        store.save(settings)
        applyPlayback()
    }

    @objc private func pickVideo(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        settings.videoPath = path
        store.save(settings)
        applyPlayback()
    }

    @objc private func chooseOtherVideo() { chooseVideoFile() }

    private func chooseVideoFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Video"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.videoPath = url.path
        store.save(settings)
        applyPlayback()
    }

    @objc private func toggleLogin() {
        let intent = !settings.launchAtLogin
        LoginItem.setEnabled(intent)
        settings.launchAtLogin = LoginItem.isEnabled   // reflect actual state (dev builds can't register)
        store.save(settings)
        rebuild()
    }
}

extension MenuBarController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) { rebuild() }
}
