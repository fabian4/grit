import SwiftUI

struct WorkspaceShell: View {
    @ObservedObject var viewModel: RepoViewModel
    @Binding var splitRatio: CGFloat
    @State private var showGitError: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar(viewModel: viewModel)
            Divider().overlay(AppTheme.chromeDividerStrong)
            ResizableSplitView(ratio: $splitRatio, minLeft: 190, minRight: 520) {
                SidebarShell(
                    viewModel: viewModel,
                    leftTab: Binding(
                        get: { viewModel.leftMode },
                        set: { viewModel.leftMode = $0 }
                    )
                )
            } right: {
                DiffPanel(viewModel: viewModel)
            }
            if viewModel.leftMode == .changes {
                Divider().overlay(AppTheme.chromeDividerStrong)
                CommitPanel(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.lastErrorMessage) { _ in
            showGitError = viewModel.lastErrorMessage != nil
        }
        .onAppear {
            normalizeSplitRatio(for: viewModel.leftMode)
        }
        .onChange(of: viewModel.leftMode) { newTab in
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
            target = 0.209
        case .files:
            target = 0.203
        case .history:
            target = 0.207
        }
        guard abs(splitRatio - target) > 0.015 else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            splitRatio = target
        }
    }
}
