import Testing
@testable import RiveViewerKit

struct DataBindingPathsTests {
    @Test func joinsPaths() {
        #expect(DataBindingPaths.join(nil, "String") == "String")
        #expect(DataBindingPaths.join("Nested", "DeeperNested") == "Nested/DeeperNested")
        #expect(DataBindingPaths.join("", "x") == "x")
    }
}
