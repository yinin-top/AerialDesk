import AppKit

// AerialDesk — animated desktop wallpaper, living in the menu bar.
//
// CLI:
//   AerialDesk --list-screens                 print displays (id, name, size) and exit
//   AerialDesk --video <path> [--screens 1,2] session override: force playback (debug)
//   AerialDesk --stop-after <seconds>         debug: auto-stop playback after N seconds

let args = CommandLine.arguments
if args.contains("--list-screens") {
    _ = NSApplication.shared
    for display in ScreenRouter.displays() {
        print("display id=\(display.id) name=\(display.name) \(display.width)x\(display.height)")
    }
    exit(0)
}

var overrideVideo: String?
var overrideScreens: [UInt32]?
var stopAfter: TimeInterval?
if let i = args.firstIndex(of: "--video"), i + 1 < args.count {
    overrideVideo = args[i + 1]
}
if let i = args.firstIndex(of: "--screens"), i + 1 < args.count {
    overrideScreens = args[i + 1].split(separator: ",").compactMap { UInt32($0.trimmingCharacters(in: .whitespaces)) }
}
if let i = args.firstIndex(of: "--stop-after"), i + 1 < args.count, let s = TimeInterval(args[i + 1]) {
    stopAfter = s
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: MenuBarController?
    var engine: WallpaperEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let engine = WallpaperEngine()
        self.engine = engine
        controller = MenuBarController(engine: engine, store: SettingsStore(),
                                       overrides: (overrideVideo, overrideScreens))
        controller?.install()
        // debug hook: verify the stop path stays alive without UI automation
        if let stopAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + stopAfter) { [weak self] in
                self?.engine?.stop()
                NSLog("[AerialDesk] debug stop-after fired")
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false   // menu bar app: closing windows never means quitting
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Menu bar agent: no Dock icon, never takes focus. In the bundled .app this is
// also declared via LSUIElement; the programmatic policy covers dev runs.
app.setActivationPolicy(.accessory)
app.run()
