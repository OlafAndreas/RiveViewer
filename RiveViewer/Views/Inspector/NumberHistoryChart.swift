import Charts
import RiveViewerKit
import SwiftUI

/// Rolling line chart of one numeric data-binding property.
struct NumberHistoryChart: View {
    let history: ValueHistory

    private static let posix = Locale(identifier: "en_US_POSIX")

    var body: some View {
        if let timeRange = history.timeRange, let valueRange = history.valueRange {
            let domain = padded(valueRange)
            VStack(alignment: .leading, spacing: 2) {
                Chart(history.samples, id: \.time) { sample in
                    LineMark(x: .value("Time", sample.time), y: .value("Value", sample.value))
                }
                .chartXScale(domain: timeRange)
                .chartYScale(domain: domain)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [domain.lowerBound, domain.upperBound]) {
                        AxisGridLine()
                        AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2)).locale(Self.posix))
                    }
                }
                .frame(height: 56)
                Text("min \(format(valueRange.lowerBound)) · max \(format(valueRange.upperBound)) · last \(format(history.latest?.value ?? 0))")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("No samples yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Pads the value range by 5% so the line never touches the edges; a flat line gets ±1.
    private func padded(_ range: ClosedRange<Double>) -> ClosedRange<Double> {
        let span = range.upperBound - range.lowerBound
        let pad = span > 0 ? span * 0.05 : 1
        return (range.lowerBound - pad)...(range.upperBound + pad)
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(Self.posix))
    }
}
