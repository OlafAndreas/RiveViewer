/// Path arithmetic for nested view-model properties (`Nested/DeeperNested/String`).
public enum DataBindingPaths {
    public static func join(_ parent: String?, _ name: String) -> String {
        guard let parent, !parent.isEmpty else { return name }
        return "\(parent)/\(name)"
    }
}
