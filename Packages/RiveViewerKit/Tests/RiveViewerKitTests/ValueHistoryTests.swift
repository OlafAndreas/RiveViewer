import Testing
@testable import RiveViewerKit

struct ValueHistoryTests {
    @Test func keepsOnlyTheWindow() {
        var h = ValueHistory(window: 10)
        h.append(time: 0, value: 1)
        h.append(time: 5, value: 2)
        h.append(time: 12, value: 3)
        #expect(h.samples.map(\.time) == [5, 12])
        #expect(h.timeRange == 2...12)
    }

    @Test func rangeAndLatest() {
        var h = ValueHistory()
        #expect(h.valueRange == nil && h.latest == nil && h.timeRange == nil)
        h.append(time: 1, value: -2)
        h.append(time: 2, value: 7)
        #expect(h.valueRange == -2...7)
        #expect(h.latest == ValueHistory.Sample(time: 2, value: 7))
    }

    @Test func ignoresNonFiniteValues() {
        var h = ValueHistory()
        h.append(time: 1, value: .nan)
        h.append(time: 2, value: .infinity)
        #expect(h.samples.isEmpty)
    }
}
