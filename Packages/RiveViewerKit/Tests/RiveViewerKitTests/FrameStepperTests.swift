import Testing
@testable import RiveViewerKit

struct FrameStepperTests {
    @Test func frameMathRoundTrips() {
        #expect(FrameStepper.frame(at: 0.5, fps: 60) == 30)
        #expect(FrameStepper.time(ofFrame: 30, fps: 60) == 0.5)
    }

    @Test func stepClampsToRange() {
        #expect(FrameStepper.step(time: 0, fps: 60, by: -1, within: 0...1) == 0)
        #expect(FrameStepper.step(time: 0.99, fps: 60, by: 1, within: 0...1) == 1)
        #expect(abs(FrameStepper.step(time: 1.0, fps: 60, by: 1, within: 1.0...3.0) - (1.0 + 1.0 / 60)) < 1e-9)
    }

    @Test func extremeFpsStaysFinite() {
        let t = FrameStepper.step(time: 0, fps: 3000, by: 30100, within: 0...(30100.0 / 3000.0))
        #expect(t.isFinite && abs(t - 30100.0 / 3000.0) < 1e-9)
        #expect(FrameStepper.step(time: 0.5, fps: 0, by: 60, within: 0...2) == 1.5)
    }

    @Test func workAreaTimeRange() {
        let a = AnimationSummary(name: "a", fps: 60, durationFrames: 240, workArea: 60...180, loop: .loop)
        #expect(a.timeRange == 1.0...3.0 && a.effectiveDurationSeconds == 2.0)
    }
}
