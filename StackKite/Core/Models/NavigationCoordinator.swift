import Combine
import Foundation

@MainActor
final class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    @Published var selection: ManagedService? = .dashboard
    @Published var navigationCount = 0

    private init() {}

    func navigate(to service: ManagedService) {
        selection = service
        navigationCount += 1
    }
}