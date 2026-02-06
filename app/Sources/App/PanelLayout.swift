import SwiftUI
import AppKit

struct TopBar: View {
    @ObservedObject var viewModel: RepoViewModel

    private var repoStatusText: String {
        viewModel.isRepoOpen ? "Repository connected" : "No repository"
    }

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                    Image(systemName: "folder")
                    Text("untitled-project")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)

                HStack(spacing: 6) {
                    ToolBarButton(symbol: "tray.and.arrow.down", label: "Pull", style: .flat)
                    ToolBarButton(symbol: "tray.and.arrow.up", label: "Push", style: .flat)
                    ToolBarButton(symbol: "arrow.triangle.branch", label: "Branch", style: .flat)
                    ToolBarButton(symbol: "checkmark.seal", label: "Commit", style: .flat)
                    ToolBarButton(symbol: "arrow.2.squarepath", label: "Sync", style: .flat)
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 8)
            .padding(.trailing, 8)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.chromeMuted)
                Text("Search everywhere")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.chromeMuted)
                Spacer(minLength: 0)
                Text("Double Shift")
                    .font(.system(size: 10, weight: .regular))
                    .background(
                        Rectangle()
                            .fill(AppTheme.chromeDark)
                    )
            }
            .frame(minWidth: 220, idealWidth: 300, maxWidth: 340)
            .background(
                Rectangle()
                    .fill(AppTheme.chromeDarkElevated)
            )
            .overlay(
                Rectangle()
                    .stroke(AppTheme.chromeDivider, lineWidth: 1)
            )

            HStack(spacing: 10) {
                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.branch")
                    Text("master")
                }
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.chromeMuted)

                ToolBarButton(symbol: "play.fill", label: "Run", tint: AppTheme.accent, style: .flat)
                ToolBarButton(symbol: "ladybug.fill", label: "Debug", style: .flat)
                ToolBarButton(symbol: "gearshape", label: "Settings", style: .flat)

                Button {
                    Task { await viewModel.openRepo() }
                } label: {
                    Text("Open")
                        .font(.system(size: 11, weight: .semibold))
                        .background(
                            Rectangle()
                                .fill(AppTheme.accent)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppTheme.chromeDark)
        .frame(height: 28)
    }
}

struct ToolBarButton: View {
    let symbol: String
    let label: String
    var tint: Color = AppTheme.chromeText
    var style: ToolBarButtonStyle = .raised

    enum ToolBarButtonStyle {
        case raised
        case flat
    }

    var body: some View {
        Button {
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(backgroundShape)
        }
        .buttonStyle(.plain)
        .help(label)
    }

    @ViewBuilder
    private var backgroundShape: some View {
        switch style {
        case .raised:
            Rectangle()
                .fill(AppTheme.chromeDarkElevated)
                .overlay(
                    Rectangle()
                        .stroke(AppTheme.chromeDivider, lineWidth: 1)
                )
        case .flat:
            Rectangle()
                .fill(AppTheme.chromeDark)
        }
    }
}

struct ToolWindowRail: View {
    var body: some View {
        VStack(spacing: 10) {
            RailButton(symbol: "tray.full", label: "Changes")
            RailButton(symbol: "folder", label: "Files")
            RailButton(symbol: "terminal", label: "Terminal")
            RailButton(symbol: "sparkles", label: "Actions")
            Spacer(minLength: 0)
            RailButton(symbol: "gearshape", label: "Settings")
        }
        .frame(width: 44)
        .background(
            Rectangle()
                .fill(AppTheme.chromeDark)
        )
        .overlay(
            Rectangle()
                .stroke(AppTheme.chromeDivider, lineWidth: 1)
        )
    }
}

struct RailButton: View {
    let symbol: String
    let label: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)
                .frame(width: 28, height: 28)
                .background(
                    Rectangle()
                        .fill(AppTheme.chromeDarkElevated)
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

struct LeftPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            ToolWindowRail()
                .environment(\.colorScheme, .dark)
            ChromeCard {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workspace")
                            .font(.system(size: 20, weight: .semibold))
                            .fontWeight(.semibold)
                        Text(viewModel.repoPath)
                            .font(.caption)
                            .foregroundStyle(AppTheme.chromeMuted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        HStack(spacing: 8) {
                            StatusPill(title: "Changes", value: viewModel.statusItems.count)
                            StatusPill(title: "Files", value: viewModel.fileTree.count)
                        }
                    }
                    .foregroundStyle(AppTheme.chromeText)

                    Picker("Mode", selection: $viewModel.leftMode) {
                        ForEach(LeftPanelMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Divider().background(AppTheme.chromeDivider)

                    switch viewModel.leftMode {
                    case .changes:
                        if viewModel.statusItems.isEmpty {
                            Text("No changes")
                                .foregroundStyle(AppTheme.chromeMuted)
                        } else {
                            Toggle("Group by Folder", isOn: $viewModel.groupDiffByFolder)
                                .toggleStyle(.switch)
                            List(selection: $viewModel.selectedPath) {
                                if viewModel.groupDiffByFolder {
                                    OutlineGroup(viewModel.statusTree, children: \.children) { node in
                                        Text(node.name)
                                            .tag(node.path)
                                            .opacity(node.isLeaf ? 1.0 : 0.85)
                                    }
                                } else {
                                    ForEach(viewModel.sortedStatusItems) { item in
                                        Text(item.display)
                                            .tag(item.path)
                                    }
                                }
                            }
                            .listStyle(.sidebar)
                            .scrollContentBackground(.hidden)
                            .transaction { $0.animation = nil }
                            .onChange(of: viewModel.selectedPath) { _ in
                                if viewModel.isSelectedLeaf {
                                    Task { await viewModel.loadDiffForSelection() }
                                }
                            }
                        }
                    case .files:
                        if viewModel.fileTree.isEmpty {
                            Text("No files")
                                .foregroundStyle(AppTheme.chromeMuted)
                        } else {
                            List(selection: $viewModel.selectedFileID) {
                                OutlineGroup(viewModel.fileTree, children: \.children) { node in
                                    Text(node.name)
                                        .tag(node.id)
                                }
                            }
                            .listStyle(.sidebar)
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.selectedFileID) { _ in
                                Task { await viewModel.loadFileForSelection() }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .environment(\.colorScheme, .dark)
        }
    }
}


struct MainPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    private var detailTitle: String {
        switch viewModel.leftMode {
        case .changes:
            return viewModel.selectedPath ?? "Detail"
        case .files:
            return viewModel.selectedFileID ?? "Detail"
        }
    }

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 12) {
                IDETabStrip()
                VStack(alignment: .leading, spacing: 4) {
                    Text(detailTitle)
                        .font(.system(size: 20, weight: .semibold))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(AppTheme.chromeText)
                    Text(viewModel.leftMode == .changes ? "Diff preview" : "File preview")
                        .font(.caption)
                        .foregroundStyle(AppTheme.chromeMuted)
                }

                HStack(spacing: 12) {
                    if viewModel.leftMode == .changes {
                        Picker("Diff View", selection: $viewModel.diffMode) {
                            ForEach(DiffViewMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else {
                        Text("Unified")
                        .font(.caption)
                        .foregroundStyle(AppTheme.chromeMuted)
                        .background(
                            Rectangle().fill(AppTheme.chromeDarkElevated)
                        )
                        .overlay(
                            Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1)
                        )
                    }
                    Toggle("Editable", isOn: $viewModel.isDetailEditable)
                        .toggleStyle(.switch)
                }

                Divider().background(AppTheme.editorDivider)

                switch viewModel.leftMode {
                case .changes:
                    if viewModel.detailOutput.isEmpty {
                        Text("Select an item to view details")
                            .foregroundStyle(AppTheme.chromeMuted)
                    } else {
                        DiffTextView(
                            text: $viewModel.detailOutput,
                            lines: viewModel.diffLines,
                            mode: viewModel.diffMode,
                            isEditable: viewModel.isDetailEditable
                        )
                    }
                case .files:
                    if viewModel.fileContent.isEmpty {
                        Text("Select a file to view contents")
                            .foregroundStyle(AppTheme.chromeMuted)
                    } else {
                        DiffTextView(
                            text: $viewModel.fileContent,
                            lines: viewModel.diffLines,
                            mode: .unified,
                            isEditable: viewModel.isDetailEditable
                        )
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

}

struct IDETabStrip: View {
    var body: some View {
        HStack(spacing: 2) {
            IDETab(title: "Main.kt", icon: "k.circle.fill", isActive: true)
            IDETab(title: "Utils.java", icon: "j.circle.fill", isActive: false)
            Spacer(minLength: 0)
        }
        .frame(height: 28)
        .background(AppTheme.chromeDark)
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }
}

private struct IDETab: View {
    let title: String
    let icon: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(AppTheme.chromeText)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(isActive ? AppTheme.chromeDarkElevated : AppTheme.chromeDark)
        .overlay(
            Rectangle()
                .fill(isActive ? Color(red: 0.23, green: 0.57, blue: 0.98) : .clear)
                .frame(height: 1.5),
            alignment: .top
        )
    }
}

struct BottomPanel: View {
    @State private var selection: Int = 0
    @State private var tabs: [String] = ["Terminal 1"]

    var body: some View {
        PanelCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Terminal")
                        .font(.system(.title3, design: .serif))
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.chromeText)
                    Spacer()
                    Button("New Tab") {
                        tabs.append("Terminal \(tabs.count + 1)")
                        selection = max(0, tabs.count - 1)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }

                TabView(selection: $selection) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Text("Terminal tab \(index + 1) not wired yet")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .tag(index)
                    }
                }
                .tabViewStyle(.automatic)
            }
        }
    }
}
