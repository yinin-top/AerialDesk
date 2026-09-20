import AppKit
import AVFoundation

/// Backing-layer host for one AVPlayerLayer.
/// The player layer must be handed to AppKit via `makeBackingLayer()` — flipping
/// `wantsLayer` first and then assigning `.layer` leaves AppKit's own backing layer
/// in a broken ownership state that over-releases on window teardown (SIGSEGV in
/// objc_release during the post-close FrontBoard lifecycle callout).
final class PlayerHostView: NSView {
    private let playerLayer: AVPlayerLayer

    init(frame: NSRect, playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func makeBackingLayer() -> CALayer { playerLayer }

    override var wantsUpdateLayer: Bool { true }
}

/// Places looping, muted, click-through video windows between the desktop
/// wallpaper and desktop icons, across every selected display.
/// All of this used to be a separate player process in the prototype; as a
/// standalone app a single process owns everything.
final class WallpaperEngine {
    private var windows: [NSWindow] = []
    private var players: [AVQueuePlayer] = []
    private var loopers: [AVPlayerLooper] = []
    private var videoPath: String?
    private var selectedScreens: Set<UInt32> = []
    private var activityToken: NSObjectProtocol?

    /// Fired after a hot-plug / resolution change rebuilt the windows.
    var onDisplaysChanged: (() -> Void)?

    /// How many displays currently show a video window.
    var activeDisplayCount: Int { windows.count }

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.rebuild()
            self.onDisplaysChanged?()
        }
    }

    /// Start (or re-apply) playback. Empty `screens` = all displays.
    func apply(videoPath path: String, screens: [UInt32]) {
        videoPath = path
        selectedScreens = Set(screens)
        rebuild()
    }

    func stop() {
        videoPath = nil
        selectedScreens = []
        teardown()
    }

    private func teardown() {
        loopers.removeAll()
        players.forEach { $0.pause() }
        players.removeAll()
        windows.forEach { $0.close() }
        windows.removeAll()
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    private func rebuild() {
        teardown()
        guard let path = videoPath, FileManager.default.fileExists(atPath: path) else { return }
        let screens = NSScreen.screens.filter { ScreenRouter.isSelected(Array(selectedScreens), on: ScreenRouter.displayID(of: $0)) }
        guard !screens.isEmpty else { return }

        // App Nap would suspend decoding while the app sits "idle" in the menu bar.
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Playing desktop wallpaper video")

        let url = URL(fileURLWithPath: path)
        for screen in screens {
            let window = NSWindow(contentRect: screen.frame,
                                  styleMask: .borderless,
                                  backing: .buffered,
                                  defer: false)
            // Just above the desktop layer: desktop icons (and everything else) stay on top.
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            window.ignoresMouseEvents = true   // clicks fall through to the desktop
            // Programmatic windows are owned by our `windows` array; the default
            // isReleasedWhenClosed=true makes close() release out from under ARC
            // (double-release on teardown → SIGSEGV in objc_release).
            window.isReleasedWhenClosed = false
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            // A fully opaque desktop-level window can get merged into the wallpaper layer
            // by the compositor; keep it a hair transparent so it stays an independent layer.
            window.alphaValue = 0.999

            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .advance
            loopers.append(AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url)))
            players.append(player)

            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = NSRect(origin: .zero, size: screen.frame.size)

            let host = PlayerHostView(frame: NSRect(origin: .zero, size: screen.frame.size), playerLayer: playerLayer)
            window.contentView = host
            window.orderFrontRegardless()
            player.play()
            windows.append(window)
        }
    }
}
