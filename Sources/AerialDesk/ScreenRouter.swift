import AppKit

/// One attachable display, as exposed in menus and stored in settings.
struct DisplayInfo: Equatable {
    let id: CGDirectDisplayID
    let name: String
    let width: Int
    let height: Int
}

enum ScreenRouter {
    static func displays() -> [DisplayInfo] {
        NSScreen.screens.map {
            DisplayInfo(id: displayID(of: $0),
                        name: $0.localizedName,
                        width: Int($0.frame.width),
                        height: Int($0.frame.height))
        }
    }

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    /// Toggle one display inside the stored selection.
    /// Semantics: empty selection = "all displays". Deselecting while on "all" solidifies the
    /// complement; re-selecting everything returns to [] so newly plugged displays join too.
    /// The last remaining display cannot be deselected (use Stop instead) — an empty-but-custom
    /// selection would be indistinguishable from "all".
    static func toggled(current: [UInt32], toggle id: UInt32, allIDs: [UInt32]) -> [UInt32] {
        var set: Set<UInt32> = current.isEmpty ? Set(allIDs) : Set(current)
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        let ordered = allIDs.filter { set.contains($0) }
        if ordered.count == allIDs.count { return [] }
        if ordered.isEmpty { return [id] }
        return ordered
    }

    /// Whether a display receives playback under the given selection (empty = all).
    static func isSelected(_ selection: [UInt32], on id: UInt32) -> Bool {
        selection.isEmpty || selection.contains(id)
    }
}
