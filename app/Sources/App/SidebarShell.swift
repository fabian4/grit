import SwiftUI

struct SidebarShell: View {
    private enum PrefKey {
        static let leftTab = "ui.left.tab"
    }

    @ObservedObject var viewModel: RepoViewModel
    @Binding var leftTab: LeftPanelMode

    @State private var didLoadPref: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AppTheme.chromeDivider)
            if leftTab == .changes {
                ChangesPanel(viewModel: viewModel)
            } else {
                FilesPanel(viewModel: viewModel)
            }
        }
        .onAppear {
            if !didLoadPref {
                let raw = UserDefaults.standard.string(forKey: PrefKey.leftTab)
                leftTab = LeftPanelMode(rawValue: raw ?? "") ?? .changes
                didLoadPref = true
            }
            applyTab()
        }
        .onChange(of: leftTab) { _ in
            UserDefaults.standard.set(leftTab.rawValue, forKey: PrefKey.leftTab)
            applyTab()
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            tab("Changes", mode: .changes)
            tab("Files", mode: .files)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(AppTheme.sidebarDark)
    }

    private func tab(_ title: String, mode: LeftPanelMode) -> some View {
        Button {
            leftTab = mode
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(leftTab == mode ? AppTheme.chromeText : AppTheme.chromeMuted)
                .padding(.horizontal, 10)
                .frame(height: 20)
                .background(leftTab == mode ? AppTheme.chromeDarkElevated : AppTheme.sidebarDark)
        }
        .buttonStyle(.plain)
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }

    private func applyTab() {
        viewModel.leftMode = leftTab
        if leftTab == .changes {
            if viewModel.selectedPath != nil {
                Task { await viewModel.loadDiffForSelection() }
            }
        } else {
            Task { await viewModel.loadFileForSelection() }
        }
    }
}

