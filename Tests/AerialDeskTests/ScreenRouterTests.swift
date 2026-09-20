import Testing
@testable import AerialDesk

@Test func toggledFromAllSolidifiesThenDeselects() {
    let all: [UInt32] = [1, 2, 3]
    // [] (= all) — deselecting display 2 solidifies to [1, 3]
    #expect(ScreenRouter.toggled(current: [], toggle: 2, allIDs: all) == [1, 3])
    // [1, 3] — deselect 1 → [3]
    #expect(ScreenRouter.toggled(current: [1, 3], toggle: 1, allIDs: all) == [3])
    // [3] — re-select 1 → [1, 3]
    #expect(ScreenRouter.toggled(current: [3], toggle: 1, allIDs: all) == [1, 3])
    // back to full selection → [] so future displays join automatically
    #expect(ScreenRouter.toggled(current: [1, 3], toggle: 2, allIDs: all) == [])
    // the last remaining display cannot be deselected (use Stop instead)
    #expect(ScreenRouter.toggled(current: [1], toggle: 1, allIDs: all) == [1])
}

@Test func toggledIgnoresStaleDisplayID() {
    // a display that was unplugged never re-enters the selection
    #expect(ScreenRouter.toggled(current: [1, 2], toggle: 99, allIDs: [1, 2, 3]) == [1, 2])
}

@Test func isSelectedEmptyMeansAll() {
    #expect(ScreenRouter.isSelected([], on: 1))
    #expect(ScreenRouter.isSelected([], on: 42))
    #expect(ScreenRouter.isSelected([1, 2], on: 1))
    #expect(!ScreenRouter.isSelected([1, 2], on: 3))
}
