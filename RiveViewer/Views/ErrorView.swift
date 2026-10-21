import RiveViewerKit
import SwiftUI

struct ErrorView: View {
    let error: RiveViewerError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't open file", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.errorDescription ?? "Unknown error")
        } actions: {
            Button("Reload", action: retry)
        }
    }
}
