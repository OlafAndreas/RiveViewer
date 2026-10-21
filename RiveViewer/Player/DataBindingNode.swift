import AppKit
import RiveRuntime
import RiveViewerKit

/// One property of a bound view-model instance, with its nested instances expanded up to a fixed depth.
@MainActor
final class DataBindingNode: Identifiable {
    static let maxDepth = 4

    let path: String
    let name: String
    let type: PropertyType
    let owner: RiveDataBindingViewModel.Instance
    let children: [DataBindingNode]?

    nonisolated var id: String { path }

    private init(path: String, name: String, type: PropertyType, owner: RiveDataBindingViewModel.Instance, depth: Int) {
        self.path = path
        self.name = name
        self.type = type
        self.owner = owner
        if type == .viewModel, depth < Self.maxDepth, let nested = owner.viewModelInstanceProperty(fromPath: name) {
            children = Self.nodes(of: nested, parentPath: path, depth: depth + 1)
        } else {
            children = nil
        }
    }

    /// Every node in the given subtrees, depth first.
    static func flattened(_ nodes: [DataBindingNode]) -> [DataBindingNode] {
        nodes.flatMap { [$0] + flattened($0.children ?? []) }
    }

    static func nodes(of instance: RiveDataBindingViewModel.Instance, parentPath: String? = nil, depth: Int = 0) -> [DataBindingNode] {
        instance.properties.map { data in
            DataBindingNode(
                path: DataBindingPaths.join(parentPath, data.name),
                name: data.name,
                type: PropertyType(rawValue: data.type.rawValue) ?? .none,
                owner: instance,
                depth: depth
            )
        }
    }

    var stringProperty: RiveDataBindingViewModel.Instance.StringProperty? { owner.stringProperty(fromPath: name) }
    var numberProperty: RiveDataBindingViewModel.Instance.NumberProperty? { owner.numberProperty(fromPath: name) }
    var booleanProperty: RiveDataBindingViewModel.Instance.BooleanProperty? { owner.booleanProperty(fromPath: name) }
    var colorProperty: RiveDataBindingViewModel.Instance.ColorProperty? { owner.colorProperty(fromPath: name) }
    var enumProperty: RiveDataBindingViewModel.Instance.EnumProperty? { owner.enumProperty(fromPath: name) }
    var triggerProperty: RiveDataBindingViewModel.Instance.TriggerProperty? { owner.triggerProperty(fromPath: name) }

    /// Registers a listener on every value property in this subtree; `onChange` runs on the main actor.
    func observe(_ onChange: @escaping @MainActor () -> Void) {
        switch type {
        case .string: _ = stringProperty?.addListener { _ in MainActor.assumeIsolated(onChange) }
        case .number: _ = numberProperty?.addListener { _ in MainActor.assumeIsolated(onChange) }
        case .boolean: _ = booleanProperty?.addListener { _ in MainActor.assumeIsolated(onChange) }
        case .color: _ = colorProperty?.addListener { _ in MainActor.assumeIsolated(onChange) }
        case .enum: _ = enumProperty?.addListener { _ in MainActor.assumeIsolated(onChange) }
        case .trigger: _ = triggerProperty?.addListener { MainActor.assumeIsolated(onChange) }
        default: break
        }
        children?.forEach { $0.observe(onChange) }
    }
}
