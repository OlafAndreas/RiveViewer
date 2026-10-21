import Foundation
import RiveRuntime

public enum CanvasBackground: String, CaseIterable, Sendable, Identifiable {
    case checkerboard
    case dark
    case light

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .checkerboard: return "Checkerboard"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
}

extension RiveFit {
    public static let pickerCases: [RiveFit] = [.contain, .cover, .fill, .fitWidth, .fitHeight, .scaleDown, .noFit, .layout]

    public var displayName: String {
        switch self {
        case .fill: return "Fill"
        case .contain: return "Contain"
        case .cover: return "Cover"
        case .fitHeight: return "Fit height"
        case .fitWidth: return "Fit width"
        case .scaleDown: return "Scale down"
        case .noFit: return "No fit"
        case .layout: return "Layout"
        @unknown default: return "Fit \(rawValue)"
        }
    }
}

extension RiveAlignment {
    public static let pickerCases: [RiveAlignment] = [
        .topLeft, .topCenter, .topRight,
        .centerLeft, .center, .centerRight,
        .bottomLeft, .bottomCenter, .bottomRight,
    ]

    public var displayName: String {
        switch self {
        case .topLeft: return "Top left"
        case .topCenter: return "Top center"
        case .topRight: return "Top right"
        case .centerLeft: return "Center left"
        case .center: return "Center"
        case .centerRight: return "Center right"
        case .bottomLeft: return "Bottom left"
        case .bottomCenter: return "Bottom center"
        case .bottomRight: return "Bottom right"
        @unknown default: return "Alignment \(rawValue)"
        }
    }
}
