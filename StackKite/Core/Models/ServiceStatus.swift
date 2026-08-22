import SwiftUI

enum ServiceStatus {
    case checking
    case running
    case stopped
    case installing
    case error

    var color: Color {
        switch self {
        case .checking: return .gray
        case .running: return .green
        case .stopped: return .red
        case .installing: return .yellow
        case .error: return .orange
        }
    }

    var label: String {
        switch self {
        case .checking: return "Checking…"
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .installing: return "Installing"
        case .error: return "Error"
        }
    }
}
