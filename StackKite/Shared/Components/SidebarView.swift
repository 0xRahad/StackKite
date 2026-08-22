import SwiftUI

struct SidebarView: View {
    @Binding var selection: ManagedService?
    @EnvironmentObject private var store: ServiceStore

    var body: some View {
        List(ManagedService.allCases, selection: $selection) { service in
            SidebarRow(service: service, viewModel: store.viewModel(for: service))
                .tag(service)
        }
        .navigationTitle("StackKite")
        .listStyle(.sidebar)
    }
}

private struct SidebarRow: View {
    let service: ManagedService
    @ObservedObject var viewModel: ServiceViewModel

    var body: some View {
        HStack {
            Label(service.title, systemImage: service.systemImage)
            Spacer()
            if service.brewFormula != nil {
                Circle()
                    .fill(viewModel.status.color)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
