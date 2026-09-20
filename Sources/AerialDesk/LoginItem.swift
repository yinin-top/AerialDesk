import ServiceManagement

/// Login item via SMAppService (macOS 13+). Requires a properly bundled .app —
/// bare `swift build` binaries will fail to register, which callers surface as-is.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    @discardableResult
    static func setEnabled(_ enable: Bool) -> Bool {
        do {
            if enable { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            return true
        } catch {
            NSLog("[AerialDesk] login item error: \(error.localizedDescription)")
            return false
        }
    }
}
