import Foundation
import RiveRuntime

/// Reads a loaded `RiveFile` into a `RiveFileSummary` using the classic runtime API.
public enum RiveFileInspector {
    /// Rive writes this sentinel for "no work area".
    private static let noWorkArea = Int(UInt32.max)

    public static func summarize(_ file: RiveFile) -> RiveFileSummary {
        var artboards: [ArtboardSummary] = []
        for (index, name) in file.artboardNames().enumerated() {
            guard let artboard = try? file.artboard(fromName: name) else { continue }
            artboards.append(summarize(artboard, index: index, in: file))
        }

        var viewModels: [ViewModelSummary] = []
        for index in 0..<file.viewModelCount {
            guard let viewModel = file.viewModel(at: index) else { continue }
            viewModels.append(ViewModelSummary(
                name: viewModel.name,
                instanceNames: viewModel.instanceNames,
                properties: viewModel.properties.map {
                    PropertySummary(name: $0.name, type: PropertyType(rawValue: $0.type.rawValue) ?? .none)
                }
            ))
        }

        return RiveFileSummary(
            runtimeVersion: "\(RiveFile.majorVersion).\(RiveFile.minorVersion)",
            defaultArtboardName: (try? file.artboard())?.name(),
            artboards: artboards,
            viewModels: viewModels
        )
    }

    private static func summarize(_ artboard: RiveArtboard, index: Int, in file: RiveFile) -> ArtboardSummary {
        ArtboardSummary(
            index: index,
            name: artboard.name(),
            width: artboard.width(),
            height: artboard.height(),
            defaultStateMachineName: artboard.defaultStateMachine()?.name(),
            defaultViewModelName: file.defaultViewModel(for: artboard)?.name,
            stateMachines: artboard.stateMachineNames().compactMap { name in
                (try? artboard.stateMachine(fromName: name)).map(summarize)
            },
            animations: artboard.animationNames().compactMap { name in
                (try? artboard.animation(fromName: name)).map(summarize)
            }
        )
    }

    private static func summarize(_ stateMachine: RiveStateMachineInstance) -> StateMachineSummary {
        var inputs: [InputSummary] = []
        for index in 0..<stateMachine.inputCount() {
            guard let input = try? stateMachine.input(from: index) else { continue }
            let kind: InputSummary.Kind
            if input.isBoolean(), let bool = input as? RiveSMIBool {
                kind = .boolean(initial: bool.value())
            } else if input.isNumber(), let number = input as? RiveSMINumber {
                kind = .number(initial: number.value())
            } else {
                kind = .trigger
            }
            inputs.append(InputSummary(name: input.name(), kind: kind))
        }
        return StateMachineSummary(name: stateMachine.name(), layerCount: stateMachine.layerCount(), inputs: inputs)
    }

    private static func summarize(_ animation: RiveLinearAnimationInstance) -> AnimationSummary {
        let start = animation.workStart()
        let end = animation.workEnd()
        let workArea: ClosedRange<Int>? = (start >= noWorkArea || end >= noWorkArea || start > end) ? nil : start...end
        return AnimationSummary(
            name: animation.name(),
            fps: animation.fps(),
            durationFrames: animation.duration(),
            workArea: workArea,
            loop: LoopMode(rawValue: Int(animation.loop())) ?? .oneShot
        )
    }
}
