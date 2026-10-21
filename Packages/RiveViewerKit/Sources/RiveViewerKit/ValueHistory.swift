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

extension ValueHistory {
    /// At most `maxPoints` samples for drawing: the first and last sample, plus the minimum and maximum of each bucket
    /// in time order, so spikes stay visible.
    public func downsampled(maxPoints: Int) -> [Sample] {
        guard samples.count > maxPoints, maxPoints >= 4 else { return samples }
        let interior = samples[1..<(samples.count - 1)]
        let bucketCount = (maxPoints - 2) / 2
        let bucketSize = Int((Double(interior.count) / Double(bucketCount)).rounded(.up))
        var result: [Sample] = [samples[0]]
        var start = interior.startIndex
        while start < interior.endIndex {
            let end = min(start + bucketSize, interior.endIndex)
            let bucket = interior[start..<end]
            if let low = bucket.min(by: { $0.value < $1.value }), let high = bucket.max(by: { $0.value < $1.value }) {
                if low == high {
                    result.append(low)
                } else {
                    result.append(contentsOf: low.time < high.time ? [low, high] : [high, low])
                }
            }
            start = end
        }
        result.append(samples[samples.count - 1])
        return result
    }
}
