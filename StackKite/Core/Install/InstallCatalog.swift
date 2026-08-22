import Foundation

struct InstallCatalog {
    static func versions(for service: ManagedService) -> [InstallableVersion] {
        switch service {
        case .php:
            return [
                InstallableVersion(version: "8.4.23", kind: .phpStatic),
                InstallableVersion(version: "8.3.32", kind: .phpStatic),
                InstallableVersion(version: "8.2.32", kind: .phpStatic),
                InstallableVersion(version: "8.1.34", kind: .phpStatic),
            ]
        case .nodejs:
            return [
                InstallableVersion(version: "24.19.0", kind: .nodeTarball),
                InstallableVersion(version: "22.23.2", kind: .nodeTarball),
                InstallableVersion(version: "20.20.2", kind: .nodeTarball),
            ]
        case .nginx, .mysql, .postgresql, .mongodb, .redis:
            return [InstallableVersion(version: "latest", kind: .brew)]
        case .dashboard:
            return []
        }
    }

    static func homebrewFormula(for service: ManagedService, version: String? = nil) -> String? {
        switch service {
        case .php:
            guard let version else { return "php" }
            let majorMinor = version.split(separator: ".").prefix(2).joined(separator: ".")
            return "php@\(majorMinor)"
        case .nodejs:
            guard let version else { return "node" }
            let major = version.split(separator: ".").first ?? "22"
            return "node@\(major)"
        case .nginx: return "nginx"
        case .mysql: return "mysql"
        case .postgresql: return "postgresql"
        case .mongodb: return "mongodb-community"
        case .redis: return "redis"
        case .dashboard: return nil
        }
    }

    static func supportsHomebrew(_ service: ManagedService) -> Bool {
        switch service {
        case .php, .nodejs, .nginx, .mysql, .postgresql, .mongodb, .redis:
            return true
        case .dashboard:
            return false
        }
    }

    static func supportsStatic(_ service: ManagedService) -> Bool {
        switch service {
        case .php, .nodejs:
            return true
        default:
            return false
        }
    }
}