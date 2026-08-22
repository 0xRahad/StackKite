import Combine
import Foundation

@MainActor
final class ServiceViewModel: ObservableObject {
    let service: ManagedService

    @Published private(set) var status: ServiceStatus = .checking
    @Published private(set) var version: String?
    @Published private(set) var isBusy = false
    @Published private(set) var isInstalled = false
    @Published private(set) var installedVersions: [String] = []
    @Published private(set) var isInstallBusy = false
    @Published private(set) var installProgress: Double = 0
    @Published private(set) var installMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isComposerInstalled = false
    @Published private(set) var isComposerBusy = false
    @Published private(set) var installedBrewFormulas: [String] = []
    @Published var selectedMethod: InstallMethod = .static_

    private let brew = BrewService.shared
    private let shell = ShellService.shared
    private let installer = InstallManager.shared

    init(service: ManagedService) {
        self.service = service
        self.selectedMethod = InstallCatalog.supportsStatic(service) ? .static_ : .homebrew
    }

    func refresh() async {
        installedBrewFormulas = await detectBrewFormulas()
        isInstalled = await detectInstalled()
        installedVersions = await detectVersions()
        version = await fetchVersion()
        status = await refreshStatus()
        isComposerInstalled = service == .php ? installer.isComposerInstalled() : false
    }

    private func detectBrewFormulas() async -> [String] {
        switch service {
        case .php:
            var found: [String] = []
            if await installer.isBrewFormulaInstalled("php") { found.append("php") }
            for version in InstallCatalog.versions(for: .php) {
                let formula = "php@\(version.version.split(separator: ".").prefix(2).joined(separator: "."))"
                if await installer.isBrewFormulaInstalled(formula) { found.append(formula) }
            }
            return found
        case .nodejs:
            var found: [String] = []
            if await installer.isBrewFormulaInstalled("node") { found.append("node") }
            for version in InstallCatalog.versions(for: .nodejs) {
                let major = version.version.split(separator: ".").first ?? ""
                let formula = "node@\(major)"
                if await installer.isBrewFormulaInstalled(formula) { found.append(formula) }
            }
            return found
        default:
            return []
        }
    }

    private func refreshStatus() async -> ServiceStatus {
        switch service {
        case .php, .nodejs:
            let brewStatus = await brew.serviceStatus(service.brewFormula ?? service.rawValue)
            if brewStatus == .running { return .running }
            if !installedVersions.isEmpty { return .running }
            return .stopped
        default:
            return await brew.serviceStatus(service.brewFormula ?? service.rawValue)
        }
    }

    func start() async {
        guard let formula = service.brewFormula else { return }
        isBusy = true
        _ = try? await brew.startService(formula)
        await refresh()
        isBusy = false
    }

    func stop() async {
        guard let formula = service.brewFormula else { return }
        isBusy = true
        _ = try? await brew.stopService(formula)
        await refresh()
        isBusy = false
    }

    func install(version: String) async {
        guard !isInstallBusy else { return }
        isInstallBusy = true
        errorMessage = nil
        installMessage = nil
        installProgress = 0

        let progress: @MainActor (Double) -> Void = { [weak self] fraction in
            self?.installProgress = fraction
        }

        do {
            switch service {
            case .php:
                switch selectedMethod {
                case .static_:
                    installMessage = "Downloading PHP \(version)…"
                    try await installer.installPHP(version, progressHandler: progress)
                    installMessage = "PHP \(version) installed"
                case .homebrew:
                    let formula = InstallCatalog.homebrewFormula(for: .php, version: version) ?? "php"
                    installMessage = "Installing \(formula) via Homebrew…"
                    try await installer.brewInstall(formula)
                    installMessage = "\(formula) installed"
                }
            case .nodejs:
                switch selectedMethod {
                case .static_:
                    installMessage = "Downloading Node.js \(version)…"
                    try await installer.installNode(version, progressHandler: progress)
                    installMessage = "Node.js \(version) installed"
                case .homebrew:
                    let formula = InstallCatalog.homebrewFormula(for: .nodejs, version: version) ?? "node"
                    installMessage = "Installing \(formula) via Homebrew…"
                    try await installer.brewInstall(formula)
                    installMessage = "\(formula) installed"
                }
            case .nginx, .mysql, .postgresql, .mongodb, .redis:
                let formula = InstallCatalog.homebrewFormula(for: service) ?? ""
                installMessage = "Installing \(service.title) via Homebrew…"
                try await installer.brewInstall(formula)
                installMessage = "\(service.title) installed"
            case .dashboard:
                break
            }
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
        installProgress = 0
        isInstallBusy = false
    }

    func uninstall(version: String? = nil) async {
        guard !isInstallBusy else { return }
        isInstallBusy = true
        errorMessage = nil
        installMessage = nil

        do {
            switch service {
            case .php:
                if selectedMethod == .homebrew {
                    let formula = InstallCatalog.homebrewFormula(for: .php, version: version) ?? "php"
                    installMessage = "Uninstalling \(formula) via Homebrew…"
                    try await installer.brewUninstall(formula)
                } else if let version {
                    installMessage = "Removing PHP \(version)…"
                    try installer.uninstallPHP(version)
                }
            case .nodejs:
                if selectedMethod == .homebrew {
                    let formula = InstallCatalog.homebrewFormula(for: .nodejs, version: version) ?? "node"
                    installMessage = "Uninstalling \(formula) via Homebrew…"
                    try await installer.brewUninstall(formula)
                } else if let version {
                    installMessage = "Removing Node.js \(version)…"
                    try installer.uninstallNode(version)
                }
            case .nginx, .mysql, .postgresql, .mongodb, .redis:
                let formula = InstallCatalog.homebrewFormula(for: service) ?? ""
                installMessage = "Uninstalling \(service.title)…"
                try await installer.brewUninstall(formula)
            case .dashboard:
                break
            }
            installMessage = "Removed"
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
        isInstallBusy = false
    }

    func installComposer() async {
        guard service == .php, !isComposerBusy else { return }
        isComposerBusy = true
        errorMessage = nil
        installProgress = 0

        let progress: @MainActor (Double) -> Void = { [weak self] fraction in
            self?.installProgress = fraction
        }

        do {
            try await installer.installComposer(progressHandler: progress)
            isComposerInstalled = true
        } catch {
            errorMessage = error.localizedDescription
        }
        installProgress = 0
        isComposerBusy = false
    }

    func uninstallComposer() async {
        guard service == .php, !isComposerBusy else { return }
        isComposerBusy = true
        errorMessage = nil
        do {
            try installer.uninstallComposer()
            isComposerInstalled = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isComposerBusy = false
    }

    private func detectInstalled() async -> Bool {
        switch service {
        case .php, .nodejs:
            if !installedBrewFormulas.isEmpty { return true }
            return !installedVersions.isEmpty
        case .nginx, .mysql, .postgresql, .mongodb, .redis:
            guard let formula = InstallCatalog.homebrewFormula(for: service) else { return false }
            return await installer.isBrewFormulaInstalled(formula)
        case .dashboard:
            return false
        }
    }

    private func detectVersions() async -> [String] {
        switch service {
        case .php: return installer.installedPHPVersions()
        case .nodejs: return installer.installedNodeVersions()
        default: return []
        }
    }

    private func fetchVersion() async -> String? {
        let command: String
        switch service {
        case .php:
            command = managedBinary("php") ?? "php -v"
        case .nodejs:
            command = (managedBinary("node") ?? "node") + " -v"
        default:
            guard let c = service.versionCommand else { return nil }
            command = c
        }
        guard let result = try? await shell.run(command), result.isSuccess else {
            return nil
        }
        return result.stdout.split(separator: "\n").first.map(String.init)
    }

    private func managedBinary(_ name: String) -> String? {
        let candidate = installer.binDirectory.appendingPathComponent(name).path
        return FileManager.default.isExecutableFile(atPath: candidate) ? "'\(candidate)'" : nil
    }
}
