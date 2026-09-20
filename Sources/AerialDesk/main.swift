import AppKit

// AerialDesk — animated desktop wallpaper, living in the menu bar.
//
// CLI:
//   AerialDesk --list-screens                 print displays (id, name, size) and exit
//   AerialDesk --video <path> [--screens 1,2] session override: force playback (debug)

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
if let i = args.firstIndex(of: "--video"), i + 1 < args.count {
    overrideVideo = args[i + 1]
}
if let i = args.firstIndex(of: "--screens"), i + 1 < args.count {
    overrideScreens = args[i + 1].split(separator: ",").compactMap { UInt32($0.trimmingCharacters(in: .whitespaces)) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = MenuBarController(engine: WallpaperEngine(), store: SettingsStore(),
                                       overrides: (overrideVideo, overrideScreens))
        controller?.install()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Menu bar agent: no Dock icon, never takes focus. In the bundled .app this is
// also declared via LSUIElement; the programmatic policy covers dev runs.
app.setActivationPolicy(.accessory)
app.run()
