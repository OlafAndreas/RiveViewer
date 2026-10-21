import Foundation

/// Everything the runtime can tell us about a `.riv` file, as plain values.
public struct RiveFileSummary: Sendable, Equatable {
    public var runtimeVersion: String
    public var defaultArtboardName: String?
    public var artboards: [ArtboardSummary]
    public var viewModels: [ViewModelSummary]

    public init(runtimeVersion: String, defaultArtboardName: String?, artboards: [ArtboardSummary], viewModels: [ViewModelSummary]) {
        self.runtimeVersion = runtimeVersion
        self.defaultArtboardName = defaultArtboardName
        self.artboards = artboards
        self.viewModels = viewModels
    }

    public func artboard(named name: String) -> ArtboardSummary? {
        artboards.first { $0.name == name }
    }
}

public struct ArtboardSummary: Sendable, Equatable, Identifiable {
    public var id: String { name }
    public var index: Int
    public var name: String
    public var width: Double
    public var height: Double
    public var defaultStateMachineName: String?
    public var defaultViewModelName: String?
    public var stateMachines: [StateMachineSummary]
    public var animations: [AnimationSummary]

    public init(index: Int, name: String, width: Double, height: Double, defaultStateMachineName: String?, defaultViewModelName: String?, stateMachines: [StateMachineSummary], animations: [AnimationSummary]) {
        self.index = index
        self.name = name
        self.width = width
        self.height = height
        self.defaultStateMachineName = defaultStateMachineName
        self.defaultViewModelName = defaultViewModelName
        self.stateMachines = stateMachines
        self.animations = animations
    }

    public func stateMachine(named name: String) -> StateMachineSummary? {
        stateMachines.first { $0.name == name }
    }

    public func animation(named name: String) -> AnimationSummary? {
        animations.first { $0.name == name }
    }
}

public struct StateMachineSummary: Sendable, Equatable {
    public var name: String
    public var layerCount: Int
    public var inputs: [InputSummary]

    public init(name: String, layerCount: Int, inputs: [InputSummary]) {
        self.name = name
        self.layerCount = layerCount
        self.inputs = inputs
    }
}

public struct InputSummary: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case boolean(initial: Bool)
        case number(initial: Float)
        case trigger

        public var displayName: String {
            switch self {
            case .boolean: return "Boolean"
            case .number: return "Number"
            case .trigger: return "Trigger"
            }
        }
    }

    public var name: String
    public var kind: Kind

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }
}

public struct AnimationSummary: Sendable, Equatable {
    public var name: String
    public var fps: Int
    public var durationFrames: Int
    /// The frame range the animation actually plays, or `nil` when the whole timeline plays.
    public var workArea: ClosedRange<Int>?
    public var loop: LoopMode

    public init(name: String, fps: Int, durationFrames: Int, workArea: ClosedRange<Int>?, loop: LoopMode) {
        self.name = name
        self.fps = fps
        self.durationFrames = durationFrames
        self.workArea = workArea
        self.loop = loop
    }

    /// Playable time range in seconds (work area applied).
    public var timeRange: ClosedRange<Double> {
        let fps = Double(max(self.fps, 1))
        let start = Double(workArea?.lowerBound ?? 0) / fps
        let end = Double(workArea?.upperBound ?? durationFrames) / fps
        return start...max(start, end)
    }

    public var effectiveDurationSeconds: Double {
        timeRange.upperBound - timeRange.lowerBound
    }
}

public enum LoopMode: Int, Sendable, CaseIterable {
    case oneShot = 0
    case loop = 1
    case pingPong = 2

    public var displayName: String {
        switch self {
        case .oneShot: return "One shot"
        case .loop: return "Loop"
        case .pingPong: return "Ping-pong"
        }
    }
}

public struct ViewModelSummary: Sendable, Equatable {
    public var name: String
    public var instanceNames: [String]
    public var properties: [PropertySummary]

    public init(name: String, instanceNames: [String], properties: [PropertySummary]) {
        self.name = name
        self.instanceNames = instanceNames
        self.properties = properties
    }
}

public struct PropertySummary: Sendable, Equatable {
    public var name: String
    public var type: PropertyType

    public init(name: String, type: PropertyType) {
        self.name = name
        self.type = type
    }
}

/// Mirrors `RiveDataBindingViewModelInstancePropertyData.DataType` raw values.
public enum PropertyType: Int, Sendable, CaseIterable {
    case none = 0
    case string
    case number
    case boolean
    case color
    case list
    case `enum`
    case trigger
    case viewModel
    case integer
    case symbolListIndex
    case assetImage
    case assetFont
    case assetBlob
    case artboard
    case input
    case any

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .string: return "String"
        case .number: return "Number"
        case .boolean: return "Boolean"
        case .color: return "Color"
        case .list: return "List"
        case .enum: return "Enum"
        case .trigger: return "Trigger"
        case .viewModel: return "View model"
        case .integer: return "Integer"
        case .symbolListIndex: return "Symbol list index"
        case .assetImage: return "Image"
        case .assetFont: return "Font"
        case .assetBlob: return "Blob"
        case .artboard: return "Artboard"
        case .input: return "Input"
        case .any: return "Any"
        }
    }
}
