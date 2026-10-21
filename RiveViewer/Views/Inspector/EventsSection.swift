import RiveViewerKit
import SwiftUI

/// Playback events, state changes and Rive events, newest last.
struct EventsSection: View {
    @Bindable var controller: PlayerController

    var body: some View {
        Section {
            if controller.eventLog.isEmpty {
                Text("No events yet.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(controller.eventLog) { entry in
                                row(entry).id(entry.id)
                            }
                        }
                    }
                    .frame(minHeight: 120, maxHeight: 260)
                    .onChange(of: controller.eventLog.count) { _, _ in
                        if let last = controller.eventLog.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Events")
                Spacer()
                Button("Clear") { controller.clearEvents() }
                    .buttonStyle(.borderless)
                    .disabled(controller.eventLog.isEmpty)
            }
        }
    }

    private func row(_ entry: EventLogEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(TimeFormatting.seconds(entry.elapsed))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 56, alignment: .trailing)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                if let detail = entry.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
