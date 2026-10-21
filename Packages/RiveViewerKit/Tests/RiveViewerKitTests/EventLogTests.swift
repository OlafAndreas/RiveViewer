import Foundation
import Testing
@testable import RiveViewerKit

struct EventLogTests {
    @Test func formatsSecondsPosix() {
        #expect(TimeFormatting.seconds(1.25) == "1.25 s")
        #expect(TimeFormatting.seconds(0) == "0.00 s")
        #expect(TimeFormatting.seconds(10.0333) == "10.03 s")
        #expect(TimeFormatting.seconds(1234.5) == "1234.50 s")
    }

    @Test func eventEntryTitles() {
        #expect(EventLogEntry(elapsed: 0, kind: .stateChange(stateMachine: "SM", state: "Idle")).title == "State → Idle")
        let e = EventLogEntry(elapsed: 1, kind: .riveEvent(name: "Clicked", type: 128, properties: ["b": "2", "a": "1"]))
        #expect(e.title == "Clicked" && e.detail == "a: 1, b: 2")
        #expect(EventLogEntry(elapsed: 0, kind: .playback("Play")).detail == nil)
        #expect(EventLogEntry(elapsed: 0, kind: .playback("Play")).title == "Play")
        #expect(EventLogEntry(elapsed: 0, kind: .riveEvent(name: "E", type: 0, properties: [:])).detail == nil)
    }
}
