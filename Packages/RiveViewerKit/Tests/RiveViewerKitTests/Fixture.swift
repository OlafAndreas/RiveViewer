import Foundation

enum Fixture {
    static func url(_ name: String) -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: "riv", subdirectory: "Fixtures") else {
            fatalError("Missing fixture \(name).riv")
        }
        return url
    }

    static func data(_ name: String) throws -> Data {
        try Data(contentsOf: url(name))
    }
}
