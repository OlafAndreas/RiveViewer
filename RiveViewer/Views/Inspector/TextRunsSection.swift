import RiveViewerKit
import SwiftUI

/// Text runs found in the file (editable when they belong to the current artboard), plus a manual lookup
/// for runs inside nested artboards.
struct TextRunsSection: View {
    @Bindable var controller: PlayerController
    @State private var name = ""
    @State private var path = ""

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        Section("Text runs") {
            if controller.textRuns.isEmpty {
                Text(controller.rawFile == nil ? "Reading file structure…" : "No named text runs in this file.")
                    .foregroundStyle(.secondary)
            }
            ForEach(controller.textRuns) { entry in
                CatalogRow(entry: entry, controller: controller)
            }
            DisclosureGroup("Look up by nested path") {
                TextField("Text run name", text: $name)
                    .onSubmit(lookUp)
                TextField("Nested artboard path", text: $path)
                    .onSubmit(lookUp)
                Button("Look up", action: lookUp)
                    .disabled(trimmedName.isEmpty)
                ForEach(controller.textRunLookups) { lookup in
                    LookupRow(lookup: lookup, controller: controller)
                }
            }
        }
    }

    private func lookUp() {
        guard !trimmedName.isEmpty else { return }
        controller.addTextRunLookup(name: trimmedName, path: path.trimmingCharacters(in: .whitespaces))
        name = ""
    }
}

private struct CatalogRow: View {
    let entry: TextRunEntry
    let controller: PlayerController
    @State private var draft = ""
    @State private var failure: String?

    private var isInCurrentArtboard: Bool { entry.artboardName == controller.currentArtboard?.name }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent {
                if isInCurrentArtboard {
                    TextField("Value", text: $draft)
                        .labelsHidden()
                        .onSubmit(commit)
                } else {
                    Text("“\(entry.text)”")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Text(entry.name)
                if let artboard = entry.artboardName, !isInCurrentArtboard {
                    Text("in \(artboard)")
                }
            }
            if let failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { draft = controller.textRunValue(name: entry.name, path: "") ?? entry.text }
        .onChange(of: controller.selection) { _, _ in draft = controller.textRunValue(name: entry.name, path: "") ?? entry.text }
    }

    private func commit() {
        do {
            try controller.setTextRun(name: entry.name, path: "", value: draft)
            failure = nil
        } catch {
            failure = error.localizedDescription
        }
    }
}

private struct LookupRow: View {
    let lookup: TextRunLookup
    let controller: PlayerController
    @State private var draft = ""
    @State private var failure: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent(lookup.title) {
                HStack {
                    if lookup.lastValue != nil {
                        TextField("Value", text: $draft)
                            .labelsHidden()
                            .onSubmit(commit)
                    } else {
                        Text("No text run named “\(lookup.name)”")
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        controller.removeTextRunLookup(id: lookup.id)
                    } label: {
                        Label("Remove", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove this lookup")
                }
            }
            if let failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { draft = lookup.lastValue ?? "" }
        .onChange(of: lookup.lastValue) { _, value in draft = value ?? "" }
    }

    private func commit() {
        do {
            try controller.setTextRun(name: lookup.name, path: lookup.path, value: draft)
            failure = nil
        } catch {
            failure = error.localizedDescription
        }
    }
}
