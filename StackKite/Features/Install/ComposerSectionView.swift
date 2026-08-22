import SwiftUI

struct ComposerSectionView: View {
    @ObservedObject var viewModel: ServiceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Composer", systemImage: "shippingbox.fill")
                .font(.title3.bold())

            Text("Composer is the dependency manager for PHP. It runs alongside the PHP binary managed by StackKite.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(viewModel.isComposerInstalled ? "Installed" : "Not installed")
                    .font(.callout)
                    .foregroundStyle(viewModel.isComposerInstalled ? .green : .secondary)
                Spacer()
                if viewModel.isComposerInstalled {
                    Button("Uninstall", role: .destructive) {
                        Task { await viewModel.uninstallComposer() }
                    }
                } else {
                    Button("Install") {
                        Task { await viewModel.installComposer() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .disabled(viewModel.isComposerBusy)
            .opacity(viewModel.isComposerBusy ? 0.6 : 1)

            if viewModel.isComposerBusy {
                ProgressView(value: viewModel.installProgress)
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
    }
}
