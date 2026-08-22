import SwiftUI

struct ContentView: View {
    @State private var selection: ManagedService? = .dashboard
    @StateObject private var store = ServiceStore()
    @ObservedObject private var navigator = NavigationCoordinator.shared

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            NavigationStack {
                detailView
            }
        }
        .environmentObject(store)
        .onReceive(navigator.$navigationCount) { _ in
            selection = navigator.selection
        }
        .task {
            await store.refreshAll()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .dashboard {
        case .dashboard: DashboardView()
        case .php: PHPView()
        case .nginx: NginxView()
        case .mysql: MySQLView()
        case .postgresql: PostgreSQLView()
        case .mongodb: MongoDBView()
        case .redis: RedisView()
        case .nodejs: NodeJSView()
        }
    }
}

#Preview {
    ContentView()
}