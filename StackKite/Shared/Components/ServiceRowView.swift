import SwiftUI

struct ServiceRowView: View {
    @ObservedObject var viewModel: ServiceViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.service.title)
                    .font(.headline)
                Text(viewModel.version ?? "Not installed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(status: viewModel.status)

            if viewModel.service.isDaemon {
                Button(viewModel.status == .running ? "Stop" : "Start") {
                    Task {
                        if viewModel.status == .running {
                            await viewModel.stop()
                        } else {
                            await viewModel.start()
                        }
                    }
                }
                .disabled(viewModel.isBusy || viewModel.status == .checking)
            }
        }
        .padding(.vertical, 4)
    }
}
