import SwiftUI

/// The runtime cannot enumerate text runs, so the user looks them up by name and edits the value in place.
struct TextRunsSection: View {
    @Bindable var controller: PlayerController
    @State private var name = ""
    @State private var path = ""

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        Section("Text runs") {
            TextField("Text run name", text: $name)
                .onSubmit(lookUp)
            TextField("Nested artboard path (optional)", text: $path)
                .onSubmit(lookUp)
            Button("Look up", action: lookUp)
                .disabled(trimmedName.isEmpty)
            if controller.textRunLookups.isEmpty {
                Text("Enter a text run's name as shown in the Rive editor; the runtime cannot list them.")
                    .foregroundStyle(.secondary)
            }
            ForEach(controller.textRunLookups) { lookup in
                TextRunRow(lookup: lookup, controller: controller)
            }
        }
    }

    private func lookUp() {
        guard !trimmedName.isEmpty else { return }
        controller.addTextRunLookup(name: trimmedName, path: path.trimmingCharacters(in: .whitespaces))
        name = ""
    }
}

private struct TextRunRow: View {
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
