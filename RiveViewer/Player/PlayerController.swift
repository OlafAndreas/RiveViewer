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
    /// Inputs of the running state machine (empty in animation mode).
    private(set) var inputs: [LiveInput] = []
    /// Default instance of the artboard's default view model, bound to the running artboard and state machine.
    private(set) var boundInstance: RiveDataBindingViewModel.Instance?
    private(set) var boundViewModelName: String?
    private(set) var dataBindingRoots: [DataBindingNode] = []
    /// Incremented whenever a bound property changes, so views re-read live values.
    private(set) var dataBindingRevision = 0

    var selection: PlaybackSelection? {
        didSet {
            if selection != oldValue { applySelection() }
        }
    }

    // MARK: View options

    var loopMode: LoopMode = .loop {
        didSet { applyLoopMode() }
    }

    var fit: RiveFit = .contain {
        didSet { viewModel?.fit = fit }
    }

    var alignment: RiveAlignment = .center {
        didSet { viewModel?.alignment = alignment }
    }

    var background: CanvasBackground = .checkerboard

    var showsFPS = false {
        didSet {
            RiveView.showFPSCounters = showsFPS
            viewModel?.riveView?.showFPS = showsFPS
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

    var currentAnimation: AnimationSummary? {
        guard case .animation(_, let name) = selection else { return nil }
        return currentArtboard?.animation(named: name)
    }

    var currentStateMachine: StateMachineSummary? {
        guard case .stateMachine(_, let name) = selection else { return nil }
        return currentArtboard?.stateMachine(named: name)
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
                viewModel = InspectorRiveViewModel(model, stateMachineName: name, fit: fit, alignment: alignment, autoPlay: true, artboardName: selection.artboardName)
            case .animation(_, let name):
                viewModel = InspectorRiveViewModel(model, animationName: name, fit: fit, alignment: alignment, autoPlay: true, artboardName: selection.artboardName)
            }
            wire(viewModel)
            self.viewModel = viewModel
            isPlaying = true
            loadError = nil
            rebuildInputs()
            bindDataModel()
            log.notice("playing \(selection.logDescription, privacy: .public) on artboard instance \(viewModel.riveModel?.artboard.name() ?? "-", privacy: .public)")
            if let animation = currentAnimation {
                loopMode = animation.loop
            }
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

    private func bindDataModel() {
        boundInstance = nil
        boundViewModelName = nil
        dataBindingRoots = []
        guard let model = viewModel?.riveModel, let artboard = model.artboard else {
            log.notice("data binding: no model or artboard")
            return
        }
        guard let viewModel = model.riveFile.defaultViewModel(for: artboard) else {
            log.notice("data binding: no default view model for \(artboard.name(), privacy: .public) (file has \(model.riveFile.viewModelCount) view models)")
            return
        }
        guard let instance = viewModel.createDefaultInstance() else {
            log.notice("data binding: no default instance for \(viewModel.name, privacy: .public)")
            return
        }
        model.stateMachine?.bind(viewModelInstance: instance)
        artboard.bind(viewModelInstance: instance)
        boundInstance = instance
        boundViewModelName = viewModel.name
        dataBindingRoots = DataBindingNode.nodes(of: instance)
        dataBindingRoots.forEach { $0.observe { [weak self] in self?.dataBindingRevision += 1 } }
        log.notice("data binding: \(viewModel.name, privacy: .public)/\(instance.name, privacy: .public) properties=\(instance.propertyCount)")
    }

    /// Called after the inspector writes a bound property; redraws when playback is paused.
    func dataBindingDidChange() {
        dataBindingRevision += 1
        if !isPlaying { viewModel?.riveView?.advance(delta: 0) }
    }

    private func rebuildInputs() {
        guard let stateMachine = viewModel?.riveModel?.stateMachine else {
            inputs = []
            return
        }
        var rebuilt: [LiveInput] = []
        for index in 0..<stateMachine.inputCount() {
            guard let input = try? stateMachine.input(from: index) else { continue }
            let kind: InputSummary.Kind
            var boolValue = false
            var numberValue: Float = 0
            if input.isBoolean(), let bool = input as? RiveSMIBool {
                boolValue = bool.value()
                kind = .boolean(initial: boolValue)
            } else if input.isNumber(), let number = input as? RiveSMINumber {
                numberValue = number.value()
                kind = .number(initial: numberValue)
            } else {
                kind = .trigger
            }
            rebuilt.append(LiveInput(summary: InputSummary(name: input.name(), kind: kind), boolValue: boolValue, numberValue: numberValue, controller: self))
        }
        inputs = rebuilt
    }

    private func applyLoopMode() {
        viewModel?.riveModel?.animation?.loop(Int32(loopMode.rawValue))
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
        applyLoopMode()
        viewModel?.play()
        currentTime = 0
        elapsed = 0
        isSettled = false
        isPlaying = true
        append(.playback("Restart"))
        rebuildInputs()
        bindDataModel()
    }

    // MARK: Inputs

    func setInput(_ name: String, bool: Bool) {
        viewModel?.setInput(name, value: bool)
        append(.playback("Input \(name) = \(bool)"))
    }

    func setInput(_ name: String, number: Float) {
        viewModel?.setInput(name, value: number)
        append(.playback("Input \(name) = \(number)"))
    }

    func fire(_ name: String) {
        viewModel?.triggerInput(name)
        append(.playback("Trigger \(name)"))
    }

    /// Moves an animation to `time` and redraws, without changing the play state.
    func seek(to time: Double) {
        guard let viewModel, let animation = viewModel.riveModel?.animation else { return }
        animation.setTime(Float(time))
        viewModel.riveView?.advance(delta: 0)
        currentTime = time
    }

    /// Pauses and moves an animation by whole frames, clamped to its playable range.
    func step(frames: Int) {
        guard let animation = currentAnimation else { return }
        pause()
        seek(to: FrameStepper.step(time: currentTime, fps: animation.fps, by: frames, within: animation.timeRange))
    }

    func clearEvents() {
        eventLog.removeAll()
    }
}
