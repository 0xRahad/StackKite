import SwiftUI

struct ServiceDetailView: View {
    @ObservedObject var viewModel: ServiceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ServiceRowView(viewModel: viewModel)
                InstallSectionView(viewModel: viewModel)
                if viewModel.service == .php {
                    ComposerSectionView(viewModel: viewModel)
                }
            }
            .padding()
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(viewModel.service.title)
        .task { await viewModel.refresh() }
    }

    private var header: some View {
        HStack {
            Label(viewModel.service.title, systemImage: viewModel.service.systemImage)
                .font(.largeTitle.bold())
            Spacer()
            StatusBadge(status: viewModel.status)
        }
    }
}
