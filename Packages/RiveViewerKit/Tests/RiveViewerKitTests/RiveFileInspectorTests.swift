import Foundation
import Testing
@testable import RiveViewerKit

struct RiveFileInspectorTests {
    @Test func summarizesStateMachineFixture() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("teststatemachine")))
        #expect(s.defaultArtboardName == "New Artboard")
        let ab = try #require(s.artboards.first)
        #expect(ab.width == 500 && ab.height == 500 && ab.index == 0)
        #expect(ab.defaultStateMachineName == nil)
        let sm = try #require(ab.stateMachine(named: "State Machine 1"))
        #expect(sm.layerCount == 1)
        #expect(sm.inputs == [InputSummary(name: "BlendAmount", kind: .number(initial: 40))])
        let anim = try #require(ab.animation(named: "MoveY"))
        #expect(anim.fps == 60 && anim.durationFrames == 600 && anim.workArea == nil && anim.loop == .oneShot)
        #expect(anim.timeRange == 0...10)
    }

    @Test func summarizesWorkAreaAndLoopModes() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("play_button_event_example")))
        let ab = try #require(s.artboards.first)
        let sm = try #require(ab.stateMachine(named: "State Machine"))
        #expect(sm.layerCount == 3)
        #expect(sm.inputs == [
            InputSummary(name: "Click", kind: .trigger),
            InputSummary(name: "Hover", kind: .boolean(initial: false)),
        ])
        let thumb = try #require(ab.animation(named: "Thumbnail"))
        #expect(thumb.durationFrames == 600 && thumb.workArea == 0...270 && thumb.loop == .loop)
        #expect(abs(thumb.effectiveDurationSeconds - 4.5) < 0.0001)
        let text = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("testtext")))
        #expect(text.artboards[0].animations[0].loop == .pingPong)
    }

    @Test func summarizesDefaults() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("runtime_nested_inputs")))
        #expect(s.artboards.map(\.name) == ["MainArtboard", "CircleInner", "CircleOuter"])
        #expect(s.artboards[0].defaultStateMachineName == "MainStateMachine")
        #expect(s.artboards[0].width == 200)
    }

    @Test func summarizesViewModels() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("data_binding_test")))
        #expect(s.viewModels.count == 3)
        #expect(s.artboards[0].defaultViewModelName == "Test")
        #expect(s.artboards[0].defaultStateMachineName == "State Machine 1")
        let test = try #require(s.viewModels.first { $0.name == "Test" })
        #expect(test.instanceNames == ["Default", "Editor Defaults"])
        #expect(test.properties.count == 11)
        #expect(test.properties.contains(PropertySummary(name: "Number", type: .number)))
        #expect(test.properties.contains(PropertySummary(name: "Enum", type: .enum)))
        #expect(test.properties.contains(PropertySummary(name: "Nested", type: .viewModel)))
        #expect(test.properties.contains(PropertySummary(name: "Image", type: .assetImage)))
        #expect(test.properties.contains(PropertySummary(name: "Trigger Blue", type: .trigger)))
        #expect(s.runtimeVersion == "7.4")
    }
}
