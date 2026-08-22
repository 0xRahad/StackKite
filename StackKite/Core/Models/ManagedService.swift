import Foundation

enum ManagedService: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case php
    case nginx
    case mysql
    case postgresql
    case mongodb
    case redis
    case nodejs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .php: return "PHP"
        case .nginx: return "Nginx"
        case .mysql: return "MySQL"
        case .postgresql: return "PostgreSQL"
        case .mongodb: return "MongoDB"
        case .redis: return "Redis"
        case .nodejs: return "Node.js"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .php: return "curlybraces"
        case .nginx: return "network"
        case .mysql: return "cylinder.split.1x2"
        case .postgresql: return "cylinder"
        case .mongodb: return "leaf"
        case .redis: return "bolt.fill"
        case .nodejs: return "hexagon"
        }
    }

    var brewFormula: String? {
        switch self {
        case .dashboard: return nil
        case .php: return "php"
        case .nginx: return "nginx"
        case .mysql: return "mysql"
        case .postgresql: return "postgresql"
        case .mongodb: return "mongodb-community"
        case .redis: return "redis"
        case .nodejs: return "node"
        }
    }

    var isDaemon: Bool {
        switch self {
        case .nginx, .mysql, .postgresql, .mongodb, .redis:
            return true
        default:
            return false
        }
    }

    var versionCommand: String? {
        switch self {
        case .dashboard: return nil
        case .php: return "php -v"
        case .nginx: return "nginx -v 2>&1"
        case .mysql: return "mysql --version"
        case .postgresql: return "postgres --version"
        case .mongodb: return "mongod --version"
        case .redis: return "redis-server --version"
        case .nodejs: return "node -v"
        }
    }
}
