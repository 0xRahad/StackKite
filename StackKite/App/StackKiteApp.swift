import SwiftUI

@main
struct StackKiteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ServiceStore()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
        } label: {
            Image(systemName: "kite")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarView: View {
    @EnvironmentObject private var store: ServiceStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("StackKite")
                    .font(.headline)
                Spacer()
                Button {
                    NavigationCoordinator.shared.navigate(to: .dashboard)
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.borderless)
            }
            .padding(.bottom, 4)

            ForEach(ManagedService.allCases.filter { $0 != .dashboard }) { service in
                let viewModel = store.viewModel(for: service)
                MenuBarServiceRow(service: service, viewModel: viewModel) {
                    NavigationCoordinator.shared.navigate(to: service)
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
            }

            Divider()

            Button("Refresh") {
                Task { await store.refreshAll() }
            }

            Button("Quit StackKite") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(10)
        .frame(width: 300)
        .task { await store.refreshAll() }
    }
}

private struct MenuBarServiceRow: View {
    let service: ManagedService
    @ObservedObject var viewModel: ServiceViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(service.title, systemImage: service.systemImage)
                    .font(.callout)
                Spacer()
                Circle()
                    .fill(viewModel.status.color)
                    .frame(width: 8, height: 8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}