import Foundation

/// A rolling window of numeric samples, for charting how a value changed over the last `window` seconds.
public struct ValueHistory: Sendable, Equatable {
    public struct Sample: Sendable, Equatable {
        public let time: Double
        public let value: Double

        public init(time: Double, value: Double) {
            self.time = time
            self.value = value
        }
    }

    public let window: Double
    public private(set) var samples: [Sample] = []

    public init(window: Double = 10) {
        self.window = window
    }

    /// Records a sample and drops everything older than `time - window`; non-finite values are ignored.
    public mutating func append(time: Double, value: Double) {
        guard value.isFinite, time.isFinite else { return }
        samples.append(Sample(time: time, value: value))
        let cutoff = time - window
        if let firstKept = samples.firstIndex(where: { $0.time >= cutoff }), firstKept > 0 {
            samples.removeFirst(firstKept)
        }
    }

    public var latest: Sample? { samples.last }

    /// `min...max` of the kept samples.
    public var valueRange: ClosedRange<Double>? {
        guard let first = samples.first else { return nil }
        var low = first.value
        var high = first.value
        for sample in samples.dropFirst() {
            low = min(low, sample.value)
            high = max(high, sample.value)
        }
        return low...high
    }

    /// The window ending at the latest sample.
    public var timeRange: ClosedRange<Double>? {
        guard let latest else { return nil }
        return (latest.time - window)...latest.time
    }
}
