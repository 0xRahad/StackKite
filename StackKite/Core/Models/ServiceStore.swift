import Combine
import Foundation

@MainActor
final class ServiceStore: ObservableObject {
    private let viewModels: [ManagedService: ServiceViewModel]

    init() {
        var models: [ManagedService: ServiceViewModel] = [:]
        for service in ManagedService.allCases {
            models[service] = ServiceViewModel(service: service)
        }
        viewModels = models
    }

    func viewModel(for service: ManagedService) -> ServiceViewModel {
        viewModels[service] ?? ServiceViewModel(service: service)
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for viewModel in viewModels.values {
                group.addTask { await viewModel.refresh() }
            }
        }
    }
}
