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
            ResizableSplitView(ratio: $splitRatio, minLeft: 190, minRight: 520) {
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
        .onAppear {
            normalizeSplitRatio(for: leftTab)
        }
        .onChange(of: leftTab) { newTab in
            normalizeSplitRatio(for: newTab)
        }
        .alert("Git Error", isPresented: $showGitError) {
            Button("OK") { viewModel.lastErrorMessage = nil }
        } message: {
            Text(viewModel.lastErrorMessage ?? "")
        }
    }

    private func normalizeSplitRatio(for tab: LeftPanelMode) {
        let target: CGFloat
        switch tab {
        case .changes:
            target = 0.205
        case .files:
            target = 0.195
        case .history:
            target = 0.20
        }
        guard abs(splitRatio - target) > 0.015 else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            splitRatio = target
        }
    }
}
