import Foundation

final class BrewService {
    static let shared = BrewService()

    private let shell = ShellService.shared

    private init() {}

    func startService(_ formula: String) async throws -> ShellResult {
        try await shell.run("brew services start \(formula)")
    }

    func stopService(_ formula: String) async throws -> ShellResult {
        try await shell.run("brew services stop \(formula)")
    }

    func serviceStatus(_ formula: String) async -> ServiceStatus {
        guard let result = try? await shell.run("brew services list | grep '^\(formula) '"),
              result.isSuccess, !result.stdout.isEmpty else {
            return .stopped
        }

        if result.stdout.contains("started") {
            return .running
        } else if result.stdout.contains("error") {
            return .error
        }
        return .stopped
    }
}
