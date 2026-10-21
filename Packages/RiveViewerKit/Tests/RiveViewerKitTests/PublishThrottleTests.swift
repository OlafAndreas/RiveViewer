import Testing
@testable import RiveViewerKit

struct PublishThrottleTests {
    @Test func publishesAtMostOncePerInterval() {
        var throttle = PublishThrottle(interval: 0.1)
        let ticks = stride(from: 0.0, to: 1.0, by: 1.0 / 120).filter { throttle.shouldPublish(at: $0) }
        #expect(ticks.count == 10)
        #expect(ticks.first == 0)
    }

    @Test func resetPublishesImmediately() {
        var throttle = PublishThrottle(interval: 0.1)
        let first = throttle.shouldPublish(at: 5)
        let tooSoon = throttle.shouldPublish(at: 5.01)
        throttle.reset()
        let afterReset = throttle.shouldPublish(at: 0)
        #expect(first && !tooSoon && afterReset)
    }

    @Test func downsampledKeepsEndsAndExtremes() {
        var h = ValueHistory(window: 100)
        for i in 0..<1200 { h.append(time: Double(i) / 120, value: i == 600 ? 99 : Double(i % 7)) }
        let points = h.downsampled(maxPoints: 200)
        #expect(points.count <= 200)
        #expect(points.first == h.samples.first && points.last == h.samples.last)
        #expect(points.contains { $0.value == 99 }, "a spike survives downsampling")
    }

    @Test func downsampledReturnsSmallHistoriesUnchanged() {
        var h = ValueHistory()
        h.append(time: 0, value: 1); h.append(time: 1, value: 2)
        #expect(h.downsampled(maxPoints: 200) == h.samples)
    }
}
