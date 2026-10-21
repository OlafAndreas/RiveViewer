import RiveRuntime
import Testing
@testable import RiveViewerKit

struct ViewOptionsTests {
    @Test func pickerCasesHaveUniqueNames() {
        #expect(Set(RiveFit.pickerCases.map(\.displayName)).count == RiveFit.pickerCases.count)
        #expect(RiveAlignment.pickerCases.count == 9)
        #expect(Set(RiveAlignment.pickerCases.map(\.displayName)).count == 9)
        #expect(CanvasBackground.allCases.map(\.displayName) == ["Checkerboard", "Dark", "Light"])
    }
}
