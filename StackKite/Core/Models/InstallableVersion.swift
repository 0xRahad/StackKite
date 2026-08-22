import Foundation

enum DownloadKind {
    case phpStatic
    case nodeTarball
    case composerPhar
    case brew
}

struct InstallableVersion: Identifiable, Hashable {
    let version: String
    let kind: DownloadKind

    var id: String {
        switch kind {
        case .brew: return "brew-\(version)"
        default: return "\(version)"
        }
    }
}