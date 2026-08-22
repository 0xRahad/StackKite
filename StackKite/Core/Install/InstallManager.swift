import Foundation

enum InstallError: LocalizedError {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message): return message.isEmpty ? "Installation failed." : message
        }
    }
}

final class InstallManager {
    static let shared = InstallManager()

    private let shell = ShellService.shared
    private let fm = FileManager.default

    private init() {}

    var supportDirectory: URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("StackKite", isDirectory: true)
    }

    var binDirectory: URL {
        supportDirectory.appendingPathComponent("bin", isDirectory: true)
    }

    private var composerDirectory: URL {
        supportDirectory.appendingPathComponent("composer", isDirectory: true)
    }

    private func phpDirectory(_ version: String) -> URL {
        supportDirectory.appendingPathComponent("php/\(version)", isDirectory: true)
    }

    private func nodeDirectory(_ version: String) -> URL {
        supportDirectory.appendingPathComponent("node/\(version)", isDirectory: true)
    }

    private var machineArch: String {
        var system = utsname()
        uname(&system)
        return withUnsafeBytes(of: &system.machine) { raw in
            String(cString: raw.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
    }

    func isHomebrewInstalled() async -> Bool {
        guard let result = try? await shell.run("command -v brew") else { return false }
        return result.isSuccess
    }

    func isBrewFormulaInstalled(_ formula: String) async -> Bool {
        guard let result = try? await shell.run("brew list --versions \(formula)"),
              result.isSuccess else { return false }
        return !result.stdout.isEmpty
    }

    func brewInstall(_ formula: String) async throws {
        let result = try await shell.run("brew install \(formula)")
        guard result.isSuccess else {
            throw InstallError.failed(result.stderr.isEmpty ? result.stdout : result.stderr)
        }
    }

    func brewUninstall(_ formula: String) async throws {
        _ = try? await shell.run("brew services stop \(formula)")
        let result = try await shell.run("brew uninstall \(formula)")
        guard result.isSuccess else {
            throw InstallError.failed(result.stderr.isEmpty ? result.stdout : result.stderr)
        }
    }

    func installedPHPVersions() -> [String] {
        versions(in: supportDirectory.appendingPathComponent("php"), binaryName: "php")
    }

    func installedNodeVersions() -> [String] {
        versions(in: supportDirectory.appendingPathComponent("node"), binaryName: "bin/node")
    }

    private func versions(in directory: URL, binaryName: String) -> [String] {
        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return entries
            .filter { fm.fileExists(atPath: $0.appendingPathComponent(binaryName).path) }
            .map(\.lastPathComponent)
            .sorted { $0.isNewerThan($1) }
    }

    func installPHP(
        _ version: String,
        progressHandler: @escaping @MainActor (Double) -> Void
    ) async throws {
        let arch = machineArch == "arm64" ? "aarch64" : "x86_64"
        let url = "https://dl.static-php.dev/static-php-cli/bulk/php-\(version)-cli-macos-\(arch).tar.gz"
        let archive = fm.temporaryDirectory.appendingPathComponent("stackkite-php-\(version).tar.gz")
        defer { try? fm.removeItem(at: archive) }

        try await DownloadService.shared.download(from: url, to: archive, progressHandler: progressHandler)

        let dest = phpDirectory(version)
        try? fm.removeItem(at: dest)
        try await extractTarGz(archive, to: dest)
        let binary = dest.appendingPathComponent("php")
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binary.path)
        try replaceSymlink(at: binDirectory.appendingPathComponent("php-\(version)"), destination: binary)
        try refreshBinLink(named: "php", versions: installedPHPVersions(), destination: { phpDirectory($0).appendingPathComponent("php") })
    }

    func uninstallPHP(_ version: String) throws {
        try? fm.removeItem(at: phpDirectory(version))
        try? fm.removeItem(at: binDirectory.appendingPathComponent("php-\(version)"))
        try refreshBinLink(named: "php", versions: installedPHPVersions(), destination: { phpDirectory($0).appendingPathComponent("php") })
    }

    func installNode(
        _ version: String,
        progressHandler: @escaping @MainActor (Double) -> Void
    ) async throws {
        let arch = machineArch == "arm64" ? "arm64" : "x64"
        let url = "https://nodejs.org/dist/v\(version)/node-v\(version)-darwin-\(arch).tar.gz"
        let tmp = fm.temporaryDirectory.appendingPathComponent("stackkite-node-\(version)")
        try? fm.removeItem(at: tmp)
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tmp) }

        let archive = tmp.appendingPathComponent("node.tar.gz")
        try await DownloadService.shared.download(from: url, to: archive, progressHandler: progressHandler)
        try await extractTarGz(archive, to: tmp)

        let inner = tmp.appendingPathComponent("node-v\(version)-darwin-\(arch)")
        let dest = nodeDirectory(version)
        try? fm.removeItem(at: dest)
        try fm.moveItem(at: inner, to: dest)
        try fm.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: dest.appendingPathComponent("bin/node").path
        )
        try replaceSymlink(
            at: binDirectory.appendingPathComponent("node-\(version)"),
            destination: dest.appendingPathComponent("bin/node")
        )
        try refreshBinLink(named: "node", versions: installedNodeVersions(), destination: { nodeDirectory($0).appendingPathComponent("bin/node") })
    }

    func uninstallNode(_ version: String) throws {
        try? fm.removeItem(at: nodeDirectory(version))
        try? fm.removeItem(at: binDirectory.appendingPathComponent("node-\(version)"))
        try refreshBinLink(named: "node", versions: installedNodeVersions(), destination: { nodeDirectory($0).appendingPathComponent("bin/node") })
    }

    func isComposerInstalled() -> Bool {
        fm.fileExists(atPath: composerDirectory.appendingPathComponent("composer.phar").path)
    }

    func installComposer(progressHandler: @escaping @MainActor (Double) -> Void) async throws {
        let dir = composerDirectory
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let phar = dir.appendingPathComponent("composer.phar")
        try await DownloadService.shared.download(
            from: "https://getcomposer.org/composer.phar",
            to: phar,
            progressHandler: progressHandler
        )

        let wrapper = dir.appendingPathComponent("composer")
        let script = """
        #!/bin/zsh
        BIN_DIR="$HOME/Library/Application Support/StackKite/bin"
        if [[ -x "$BIN_DIR/php" ]]; then
          PHP="$BIN_DIR/php"
        elif command -v php >/dev/null 2>&1; then
          PHP="$(command -v php)"
        else
          echo "PHP is not installed. Install PHP first." >&2
          exit 1
        fi
        exec "$PHP" "$HOME/Library/Application Support/StackKite/composer/composer.phar" "$@"
        """
        try script.write(to: wrapper, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: wrapper.path)
        try? fm.createDirectory(at: binDirectory, withIntermediateDirectories: true)
        try replaceSymlink(at: binDirectory.appendingPathComponent("composer"), destination: wrapper)
    }

    func uninstallComposer() throws {
        try? fm.removeItem(at: composerDirectory)
        try? fm.removeItem(at: binDirectory.appendingPathComponent("composer"))
    }

    private func extractTarGz(_ archive: URL, to directory: URL) async throws {
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let result = try await shell.run(
            "mkdir -p '\(directory.path)' && tar -xzf '\(archive.path)' -C '\(directory.path)'"
        )
        guard result.isSuccess else {
            throw InstallError.failed(result.stderr.isEmpty ? result.stdout : result.stderr)
        }
    }

    private func replaceSymlink(at link: URL, destination: URL) throws {
        try? fm.removeItem(at: link)
        try? fm.createDirectory(at: link.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: link, withDestinationURL: destination)
    }

    private func refreshBinLink(
        named name: String,
        versions: [String],
        destination: (String) -> URL
    ) throws {
        try? fm.createDirectory(at: binDirectory, withIntermediateDirectories: true)
        if let latest = versions.first {
            try replaceSymlink(at: binDirectory.appendingPathComponent(name), destination: destination(latest))
        } else {
            try? fm.removeItem(at: binDirectory.appendingPathComponent(name))
        }
    }
}

private extension String {
    func isNewerThan(_ other: String) -> Bool {
        let a = split(separator: ".").compactMap { Int($0) }
        let b = other.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
