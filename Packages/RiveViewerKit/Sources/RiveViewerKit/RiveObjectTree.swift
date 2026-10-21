import Foundation

/// A file object with its children, resolved from `parentId` inside each artboard.
public struct RiveObjectNode: Sendable, Equatable, Identifiable {
    public let object: RiveObject
    public let children: [RiveObjectNode]?

    public var id: Int { object.id }

    public init(object: RiveObject, children: [RiveObjectNode]?) {
        self.object = object
        self.children = children
    }
}

public enum RiveObjectTree {
    /// Roots are objects without a parent (artboards, the backboard, assets, view models…); artboard children
    /// nest under their artboard by `parentId`.
    public static func roots(of file: RiveBinaryFile) -> [RiveObjectNode] {
        var childrenByParent: [ParentKey: [RiveObject]] = [:]
        var roots: [RiveObject] = []
        for object in file.objects {
            if let parentId = object.parentId, let scopeId = object.scopeId, object.typeKey != RiveObject.artboardTypeKey {
                childrenByParent[ParentKey(scopeId: scopeId, localIndex: parentId), default: []].append(object)
            } else {
                roots.append(object)
            }
        }
        func node(for object: RiveObject) -> RiveObjectNode {
            let key = ParentKey(scopeId: object.scopeId ?? -1, localIndex: object.localIndex)
            guard let children = childrenByParent[key], !children.isEmpty else {
                return RiveObjectNode(object: object, children: nil)
            }
            return RiveObjectNode(object: object, children: children.map(node(for:)))
        }
        return roots.map(node(for:))
    }

    private struct ParentKey: Hashable {
        let scopeId: Int
        let localIndex: Int
    }
}
