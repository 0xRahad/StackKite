import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: ServiceStore
    private let services = ManagedService.allCases.filter { $0 != .dashboard }
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your local stack")
                    .font(.title.bold())
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(services) { service in
                        ServiceCard(viewModel: store.viewModel(for: service))
                    }
                }
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Dashboard")
        .background {
            LiquidGlassBackground()
        }
    }
}

private struct ServiceCard: View {
    @ObservedObject var viewModel: ServiceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(viewModel.service.title, systemImage: viewModel.service.systemImage)
                    .font(.headline)
                Spacer()
                StatusBadge(status: viewModel.status)
            }

            Text(viewModel.version ?? (viewModel.isInstalled ? "Installed" : "Not installed"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.25),
                    Color.purple.opacity(0.18),
                    Color.pink.opacity(0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 60)

            Circle()
                .fill(Color.cyan.opacity(0.25))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: -280, y: -240)

            Circle()
                .fill(Color.pink.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: 300, y: 280)
        }
        .ignoresSafeArea()
    }
}
