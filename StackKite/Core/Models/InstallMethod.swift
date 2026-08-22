import Foundation

enum InstallMethod: String, CaseIterable, Identifiable {
    case static_ = "Static"
    case homebrew = "Homebrew"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .static_: return "Standalone binary"
        case .homebrew: return "brew package"
        }
    }
}