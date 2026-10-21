import Foundation

/// Frame/time arithmetic for stepping and scrubbing animations.
public enum FrameStepper {
    public static func frame(at time: Double, fps: Int) -> Int {
        Int((time * Double(effectiveFPS(fps))).rounded())
    }

    public static func time(ofFrame frame: Int, fps: Int) -> Double {
        Double(frame) / Double(effectiveFPS(fps))
    }

    /// Moves `time` by `frames` and clamps the result into `range`.
    public static func step(time: Double, fps: Int, by frames: Int, within range: ClosedRange<Double>) -> Double {
        let next = time + Double(frames) / Double(effectiveFPS(fps))
        return min(max(next, range.lowerBound), range.upperBound)
    }

    private static func effectiveFPS(_ fps: Int) -> Int {
        fps > 0 ? fps : 60
    }
}
