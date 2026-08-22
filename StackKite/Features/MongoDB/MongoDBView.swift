import SwiftUI

struct MongoDBView: View {
    @EnvironmentObject private var store: ServiceStore

    var body: some View {
        ServiceDetailView(viewModel: store.viewModel(for: .mongodb))
    }
}
