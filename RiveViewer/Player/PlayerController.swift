import Foundation
import Observation
import OSLog
import RiveRuntime
import RiveViewerKit

private let log = Logger(subsystem: "no.olafandreas.RiveViewer", category: "player")

/// One per document window: owns the loaded file, the current selection, the Rive view model and the event log.
@MainActor
@Observable
final class PlayerController {
    let fileURL: URL?

    private(set) var summary: RiveFileSummary?
    private(set) var loadError: RiveViewerError?
    private(set) var viewModel: InspectorRiveViewModel?
    private(set) var isPlaying = false
    /// Current animation time in seconds (animation mode).
    private(set) var currentTime: Double = 0
    /// Seconds advanced since the selection was applied (state-machine mode).
    private(set) var elapsed: Double = 0
    /// True once a state machine stopped advancing on its own.
    private(set) var isSettled = false
    private(set) var eventLog: [EventLogEntry] = []

    var selection: PlaybackSelection? {
        didSet {
            if selection != oldValue { applySelection() }
        }
    }

    @ObservationIgnored private var file: RiveFile?
    @ObservationIgnored private var userPaused = false

    private static let maxLogEntries = 500

    init(data: Data, fileURL: URL?) {
        self.fileURL = fileURL
        load(data: data)
    }

    var fileName: String { fileURL?.lastPathComponent ?? "Untitled" }

    var currentArtboard: ArtboardSummary? {
        guard let selection, let summary else { return nil }
        return summary.artboard(named: selection.artboardName)
    }

    // MARK: Loading

    func load(data: Data) {
        do {
            let file = try RiveFileLoader.load(data: data)
            let summary = RiveFileInspector.summarize(file)
            self.file = file
            self.summary = summary
            self.loadError = nil
            let reconciled = DefaultPlayback.reconcile(selection, in: summary)
            log.notice("opened \(self.fileName, privacy: .public): artboards=\(summary.artboards.count) selection=\(reconciled?.logDescription ?? "none", privacy: .public)")
            if reconciled == selection {
                applySelection()
            } else {
                selection = reconciled
            }
        } catch {
            fail(error)
        }
    }

    func reload() {
        guard let fileURL else { return }
        do {
            load(data: try Data(contentsOf: fileURL))
        } catch {
            fail(RiveViewerError.unreadableFile(fileURL))
        }
    }

    private func fail(_ error: any Error) {
        let viewerError = (error as? RiveViewerError) ?? .cannotLoad(error.localizedDescription)
        loadError = viewerError
        summary = nil
        viewModel = nil
        file = nil
        log.error("open failed: \(viewerError.localizedDescription, privacy: .public)")
    }

    private func applySelection() {
        eventLog.removeAll()
        currentTime = 0
        elapsed = 0
        isSettled = false
        userPaused = false
        guard let file, let selection else {
            viewModel = nil
            isPlaying = false
            return
        }
        do {
            let model = try PlaybackConfigurator.makeModel(file: file, selection: selection)
            let viewModel: InspectorRiveViewModel
            switch selection {
            case .stateMachine(_, let name):
                viewModel = InspectorRiveViewModel(model, stateMachineName: name, autoPlay: true)
            case .animation(_, let name):
                viewModel = InspectorRiveViewModel(model, animationName: name, autoPlay: true)
            }
            wire(viewModel)
            self.viewModel = viewModel
            isPlaying = true
            loadError = nil
        } catch {
            fail(error)
        }
    }

    private func wire(_ viewModel: InspectorRiveViewModel) {
        viewModel.onPlayback = { [weak self] kind in self?.handlePlayback(kind) }
        viewModel.onAdvance = { [weak self] seconds in self?.handleAdvance(seconds) }
        viewModel.onStateChange = { [weak self] stateMachine, state in
            log.notice("state change: \(stateMachine, privacy: .public) → \(state, privacy: .public)")
            self?.append(.stateChange(stateMachine: stateMachine, state: state))
        }
        viewModel.onRiveEvent = { [weak self] name, type, properties in
            self?.append(.riveEvent(name: name, type: type, properties: properties))
        }
    }

    private func handlePlayback(_ kind: EventLogEntry.Kind) {
        if case .playback(let name) = kind {
            switch name {
            case "Play":
                isPlaying = true
                isSettled = false
            case "Pause", "Stop":
                isPlaying = false
                if selection?.isStateMachine == true, !userPaused { isSettled = true }
            default:
                break
            }
        }
        append(kind)
    }

    private func handleAdvance(_ seconds: Double) {
        guard let model = viewModel?.riveModel else { return }
        if let animation = model.animation {
            currentTime = Double(animation.time())
        } else {
            elapsed += seconds
        }
    }

    private func append(_ kind: EventLogEntry.Kind) {
        let stamp = selection?.isStateMachine == true ? elapsed : currentTime
        eventLog.append(EventLogEntry(elapsed: stamp, kind: kind))
        if eventLog.count > Self.maxLogEntries {
            eventLog.removeFirst(eventLog.count - Self.maxLogEntries)
        }
    }

    // MARK: Transport

    func play() {
        userPaused = false
        viewModel?.play()
        isPlaying = true
    }

    func pause() {
        userPaused = true
        viewModel?.pause()
        isPlaying = false
    }

    func togglePlay() {
        if isPlaying { pause() } else { play() }
    }

    func restart() {
        userPaused = false
        viewModel?.reset()
        viewModel?.play()
        currentTime = 0
        elapsed = 0
        isSettled = false
        isPlaying = true
        append(.playback("Restart"))
    }

    func clearEvents() {
        eventLog.removeAll()
    }
}
