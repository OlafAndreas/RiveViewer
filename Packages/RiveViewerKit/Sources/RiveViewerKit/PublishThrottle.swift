/// Lets frequent updates through at most once per `interval` seconds of the caller's clock.
public struct PublishThrottle: Sendable, Equatable {
    public let interval: Double
    private var lastPublished: Double?

    public init(interval: Double) {
        self.interval = interval
    }

    public mutating func shouldPublish(at time: Double) -> Bool {
        if let lastPublished, time - lastPublished < interval - 1e-9 { return false }
        lastPublished = time
        return true
    }

    public mutating func reset() {
        lastPublished = nil
    }
}
