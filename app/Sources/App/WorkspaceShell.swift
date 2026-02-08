import SwiftUI

struct WorkspaceShell: View {
    @ObservedObject var viewModel: RepoViewModel
    @Binding var splitRatio: CGFloat
    @State private var showGitError: Bool = false
    @State private var leftTab: LeftPanelMode = .changes

    var body: some View {
        VStack(spacing: 0) {
            TopBar(viewModel: viewModel)
            Divider().overlay(AppTheme.chromeDivider)
            ResizableSplitView(ratio: $splitRatio, minLeft: 240, minRight: 520) {
                SidebarShell(viewModel: viewModel, leftTab: $leftTab)
            } right: {
                DiffPanel(viewModel: viewModel)
            }
            if leftTab == .changes {
                Divider().overlay(AppTheme.chromeDivider)
                CommitPanel(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.lastErrorMessage) { _ in
            showGitError = viewModel.lastErrorMessage != nil
        }
        .alert("Git Error", isPresented: $showGitError) {
            Button("OK") { viewModel.lastErrorMessage = nil }
        } message: {
            Text(viewModel.lastErrorMessage ?? "")
        }
    }
}
