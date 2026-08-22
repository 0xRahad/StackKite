import SwiftUI

struct InstallSectionView: View {
    @ObservedObject var viewModel: ServiceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Install")
                .font(.title2.bold())

            if InstallCatalog.supportsHomebrew(viewModel.service) && InstallCatalog.supportsStatic(viewModel.service) {
                methodPicker
            }

            versionList
            statusArea
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var methodPicker: some View {
        Picker("Method", selection: $viewModel.selectedMethod) {
            ForEach(InstallMethod.allCases) { method in
                Text(method.rawValue).tag(method)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var versionList: some View {
        if viewModel.service == .php || viewModel.service == .nodejs {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(InstallCatalog.versions(for: viewModel.service)) { item in
                    versionRow(item)
                }
            }
        } else {
            brewRow
        }
    }

    private func versionRow(_ item: InstallableVersion) -> some View {
        let staticInstalled = staticVersions.contains(item.version)
        let brewInstalled = installedBrewFormula(for: item.version) != nil
        let isInstalled = staticInstalled || brewInstalled
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.service.title) \(item.version)")
                    .font(.body.weight(.medium))
                if isInstalled {
                    Text(staticInstalled ? "Installed" : "Installed (Homebrew)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isInstalled {
                Button("Uninstall", role: .destructive) {
                    Task { await viewModel.uninstall(version: item.version) }
                }
            } else {
                Button("Install") {
                    Task { await viewModel.install(version: item.version) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .disabled(viewModel.isInstallBusy)
        .opacity(viewModel.isInstallBusy ? 0.6 : 1)
    }

    private var brewRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.service.title) (Homebrew)")
                    .font(.body.weight(.medium))
                if viewModel.isInstalled {
                    Text("Installed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if viewModel.isInstalled {
                Button("Uninstall", role: .destructive) {
                    Task { await viewModel.uninstall() }
                }
            } else {
                Button("Install") {
                    Task { await viewModel.install(version: "latest") }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .disabled(viewModel.isInstallBusy)
        .opacity(viewModel.isInstallBusy ? 0.6 : 1)
    }

    @ViewBuilder
    private var statusArea: some View {
        if viewModel.isInstallBusy {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: viewModel.installProgress)
                    .progressViewStyle(.linear)
                if let message = viewModel.installMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if let error = viewModel.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private var staticVersions: [String] {
        viewModel.installedVersions
    }

    private func installedBrewFormula(for version: String) -> String? {
        viewModel.installedBrewFormulas.first {
            $0 == InstallCatalog.homebrewFormula(for: viewModel.service, version: version)
        }
    }
}