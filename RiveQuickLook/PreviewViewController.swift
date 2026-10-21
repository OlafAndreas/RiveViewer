import AppKit
import OSLog
import QuickLookUI
import RiveRuntime
import RiveViewerKit

private let log = Logger(subsystem: "no.olafandreas.RiveViewer", category: "quicklook")

/// Quick Look preview: plays the file's default state machine, or its longest animation when the
/// state machine settles, so the preview always moves when the file contains any animation.
@MainActor
final class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController, @preconcurrency RivePlayerDelegate {
    private var riveView: RiveView?
    private var model: RiveModel?
    private var summary: RiveFileSummary?
    private var selection: PlaybackSelection?
    private var didFallBack = false
    private var fileName = ""

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping @Sendable ((any Error)?) -> Void) {
        do {
            try prepare(url: url)
            handler(nil)
        } catch {
            log.error("preview failed: \(error.localizedDescription, privacy: .public)")
            handler(error)
        }
    }

    private func prepare(url: URL) throws {
        fileName = url.lastPathComponent
        let file = try RiveFileLoader.load(url: url)
        let summary = RiveFileInspector.summarize(file)
        let selection = DefaultPlayback.selection(for: summary)
        self.summary = summary
        self.selection = selection

        let riveView = RiveView()
        riveView.frame = view.bounds
        riveView.autoresizingMask = [.width, .height]
        riveView.playerDelegate = self
        view.addSubview(riveView)
        self.riveView = riveView

        let model: RiveModel
        if let selection {
            model = try PlaybackConfigurator.makeModel(file: file, selection: selection)
            model.animation?.loop(Int32(RiveLoop.loop.rawValue))
            self.model = model
            try riveView.setModel(model, autoPlay: true)
        } else {
            model = RiveModel(riveFile: file)
            try model.setArtboard()
            self.model = model
            try riveView.setModel(model, autoPlay: false)
        }

        let artboard = summary.artboard(named: selection?.artboardName ?? summary.defaultArtboardName ?? "")
        preferredContentSize = PreviewSizing.preferredSize(artboardWidth: artboard?.width ?? 0, artboardHeight: artboard?.height ?? 0)
        log.notice("preview \(self.fileName, privacy: .public): artboard=\(artboard?.name ?? "-", privacy: .public) selection=\(selection?.logDescription ?? "none", privacy: .public)")
    }

    // MARK: RivePlayerDelegate

    func player(playedWithModel riveModel: RiveModel?) {}
    func player(loopedWithModel riveModel: RiveModel?, type: Int) {}
    func player(stoppedWithModel riveModel: RiveModel?) {}
    func player(didAdvanceby seconds: Double, riveModel: RiveModel?) {}

    func player(pausedWithModel riveModel: RiveModel?) {
        guard !didFallBack,
              let selection, selection.isStateMachine,
              let summary, let artboard = summary.artboard(named: selection.artboardName),
              let fallback = DefaultPlayback.fallbackAnimation(for: artboard),
              let file = model?.riveFile
        else { return }
        didFallBack = true
        let newSelection = PlaybackSelection.animation(artboard: artboard.name, name: fallback)
        // Leave the delegate callback before swapping models; setModel restarts the frame loop.
        Task { @MainActor [weak self] in
            guard let self, let riveView = self.riveView else { return }
            do {
                let model = try PlaybackConfigurator.makeModel(file: file, selection: newSelection)
                model.animation?.loop(Int32(RiveLoop.loop.rawValue))
                self.model = model
                self.selection = newSelection
                try riveView.setModel(model, autoPlay: true)
                log.notice("fallback to animation \(fallback, privacy: .public)")
            } catch {
                log.error("fallback failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
