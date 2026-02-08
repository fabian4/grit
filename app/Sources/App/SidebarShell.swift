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
            chrome
            if leftTab == .changes {
                ChangesPanel(viewModel: viewModel)
            } else if leftTab == .files {
                FilesPanel(viewModel: viewModel)
            } else {
                HistorySidebarPanel(viewModel: viewModel)
                    .background(AppTheme.sidebarDark)
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
        VStack(alignment: .leading, spacing: leftTab == .history ? 8 : 0) {
            if leftTab == .history {
                Text("GRIT")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                    .padding(.leading, 2)
            }
            HStack(spacing: 0) {
                tab("Changes", mode: .changes)
                tab("Files", mode: .files)
                tab("History", mode: .history)
                Spacer(minLength: 0)
            }
            .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
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
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AppTheme.chromeDivider)
        }
    }

    private func applyTab() {
        viewModel.leftMode = leftTab
        if leftTab == .changes {
            if viewModel.selectedPath != nil {
                Task { await viewModel.loadDiffForSelection() }
            }
        } else if leftTab == .files {
            Task { await viewModel.loadFileForSelection() }
        }
    }
}
