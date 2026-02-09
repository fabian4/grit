import SwiftUI

struct SidebarShell: View {
    @ObservedObject var viewModel: RepoViewModel
    @Binding var leftTab: LeftPanelMode

    var body: some View {
        VStack(spacing: 0) {
            chrome
            if leftTab == .changes && viewModel.isRepoOpen {
                ChangesPanel(viewModel: viewModel)
            } else if leftTab == .files {
                FilesPanel(viewModel: viewModel)
            } else {
                HistorySidebarPanel(viewModel: viewModel)
                    .background(AppTheme.sidebarDark)
            }
        }
        .onAppear {
            applyTab()
        }
        .onChange(of: leftTab) { _ in
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
            .padding(1.5)
            .background(AppTheme.chromeDark, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(AppTheme.chromeDivider, lineWidth: 1)
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(AppTheme.sidebarDark)
    }

    private func tab(_ title: String, mode: LeftPanelMode) -> some View {
        SidebarTabControl(
            title: title,
            isSelected: leftTab == mode
        ) {
            leftTab = mode
        }
        .opacity(mode == .changes && !viewModel.isRepoOpen ? 0.55 : 1.0)
        .allowsHitTesting(!(mode == .changes && !viewModel.isRepoOpen))
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AppTheme.chromeDividerStrong)
        }
    }

    private func applyTab() {
        if leftTab == .changes && !viewModel.isRepoOpen {
            leftTab = .files
        }
        viewModel.leftMode = leftTab
        if leftTab == .changes {
            if viewModel.selectedPath != nil {
                Task { await viewModel.loadDiffForSelection() }
            }
        } else if leftTab == .files {
            Task {
                await viewModel.refreshFiles()
                await viewModel.loadFileForSelection()
            }
        }
    }
}

private struct SidebarTabControl: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering: Bool = false
    @GestureState private var isPressing: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.0, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AppTheme.chromeText.opacity(0.94) : AppTheme.chromeMuted.opacity(0.84))
                .padding(.horizontal, 8)
                .frame(height: 18)
                .background(backgroundFill, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .opacity(isPressing ? 0.84 : 1.0)
        .scaleEffect(isPressing ? 0.985 : 1.0)
        .onHover { inside in
            isHovering = inside
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressing) { _, state, _ in
                    state = true
                }
        )
        .animation(.easeOut(duration: 0.08), value: isPressing)
        .animation(.easeOut(duration: 0.10), value: isHovering)
    }

    private var backgroundFill: Color {
        if isSelected {
            return Color(red: 0.232, green: 0.232, blue: 0.236)
        }
        if isPressing {
            return AppTheme.chromeDarkElevated.opacity(0.55)
        }
        if isHovering {
            return AppTheme.chromeDarkElevated.opacity(0.34)
        }
        return AppTheme.chromeDark.opacity(0.28)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.white.opacity(0.13)
        }
        if isHovering {
            return AppTheme.chromeDivider.opacity(0.55)
        }
        return AppTheme.chromeDivider.opacity(0.2)
    }
}
