import Foundation
import Testing
@testable import RiveViewerKit

struct RiveBinaryReaderTests {
    @Test func parsesHeaderAndObjects() throws {
        var reader = RiveBinaryReader(data: try Fixture.data("teststatemachine"))
        let file = try reader.readFile()
        #expect(file.majorVersion == 7)
        #expect(file.objects.contains { $0.typeKey == 1 && $0.name == "New Artboard" })    // Artboard
        #expect(file.objects.contains { $0.typeKey == 53 && $0.name == "State Machine 1" }) // StateMachine
        #expect(file.objects.contains { $0.typeKey == 31 && $0.name == "MoveY" })           // LinearAnimation
        #expect(RiveSchema.typeNames[1] == "Artboard")
        #expect(RiveSchema.propertyNames[4] == "Component.name")
    }

    @Test func listsTextRuns() throws {
        var reader = RiveBinaryReader(data: try Fixture.data("testtext"))
        let runs = TextRunCatalog.textRuns(in: try reader.readFile())
        #expect(!runs.isEmpty)
        #expect(runs.allSatisfy { !$0.name.isEmpty })
        #expect(runs.allSatisfy { $0.artboardName == "New Artboard" })
    }

    @Test func rejectsGarbage() {
        var reader = RiveBinaryReader(data: Data("junk".utf8))
        #expect(throws: RiveBinaryError.badFingerprint) { try reader.readFile() }
    }

    @Test func allFixturesParseToEnd() throws {
        for name in ["testanimation", "artboard_animations", "runtime_nested_inputs", "play_button_event_example", "rating_animation", "data_binding_test"] {
            var reader = RiveBinaryReader(data: try Fixture.data(name))
            let file = try reader.readFile()
            #expect(!file.objects.isEmpty, "\(name) has objects")
        }
    }

    @Test func buildsObjectTreeUnderArtboards() throws {
        var reader = RiveBinaryReader(data: try Fixture.data("teststatemachine"))
        let roots = RiveObjectTree.roots(of: try reader.readFile())
        let artboard = try #require(roots.first { $0.object.typeKey == 1 })
        #expect(artboard.object.name == "New Artboard")
        #expect(!(artboard.children ?? []).isEmpty)
        #expect(roots.allSatisfy { $0.object.parentId == nil })
    }
}
