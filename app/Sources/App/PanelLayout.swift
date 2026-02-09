import SwiftUI
import AppKit

struct TopBar: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            leadingGroup
                .padding(.leading, 68)
                .frame(width: 240, alignment: .leading)

            Spacer(minLength: 0)

            centerGroup

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                branchButton
                iconButton(symbol: "arrow.clockwise") {
                    Task { await viewModel.refresh() }
                }
                .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.45)
                .disabled(!viewModel.isRepoOpen || viewModel.isBusy)

                if viewModel.leftMode == .changes {
                    Button("Fetch") {
                        viewModel.lastErrorMessage = "Fetch is not implemented in MVP."
                    }
                    .font(.system(size: 10.0, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 9)
                    .frame(height: 23)
                    .background(AppTheme.chromeDarkElevated, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(AppTheme.chromeDivider, lineWidth: 1)
                    )
                    .hoverPressControl(cornerRadius: 5, hoverFillOpacity: 0.28, pressFillOpacity: 0.54)
                    .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.45)
                    .disabled(!viewModel.isRepoOpen || viewModel.isBusy)
                } else {
                    iconButton(symbol: "arrow.down.to.line") {
                        viewModel.lastErrorMessage = "Fetch is not implemented in MVP."
                    }
                    .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.45)
                    .disabled(!viewModel.isRepoOpen || viewModel.isBusy)
                }

                if viewModel.isBusy {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.65)
                        .frame(width: 14, height: 14)
                        .tint(AppTheme.chromeMuted.opacity(0.8))
                }
            }
            .frame(width: 240, alignment: .trailing)
            .padding(.trailing, 10)
        }
        .frame(height: 33)
        .background(AppTheme.chromeBarGradient.allowsHitTesting(false))
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDividerStrong).frame(height: 1) }
    }

    @ViewBuilder
    private var leadingGroup: some View {
        if viewModel.leftMode == .changes {
            if viewModel.isRepoOpen {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.accentSecondary)
                    Text(shortPath)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button {
                    openRepoPicker()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 10.5, weight: .semibold))
                        Text("Open Repo")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                    .padding(.horizontal, 10)
                    .frame(height: 23)
                    .background(AppTheme.chromeDarkElevated, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(AppTheme.chromeDivider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .hoverPressControl(cornerRadius: 5, hoverFillOpacity: 0.28, pressFillOpacity: 0.54)
                .disabled(viewModel.isBusy)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack(spacing: 8) {
                Button {
                    openRepoPicker()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 10.5, weight: .semibold))
                        Text("Open Repo")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                    .padding(.horizontal, 10)
                    .frame(height: 23)
                    .background(AppTheme.chromeDarkElevated, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(AppTheme.chromeDivider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .hoverPressControl(cornerRadius: 5, hoverFillOpacity: 0.28, pressFillOpacity: 0.54)
                .disabled(viewModel.isBusy)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var centerGroup: some View {
        if viewModel.leftMode == .changes {
            searchField
                .frame(width: 298)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                Text(repoName)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(AppTheme.chromeText.opacity(0.95))
            }
            .frame(width: 298, alignment: .center)
        }
    }

    private var repoName: String {
        guard viewModel.isRepoOpen else { return "Grit" }
        return URL(fileURLWithPath: viewModel.repoPath).lastPathComponent
    }

    private var shortPath: String {
        if !viewModel.isRepoOpen {
            return "~/Projects/grit-web"
        }
        let path = viewModel.repoPath
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home + "/") {
            return "~/" + path.dropFirst(home.count + 1)
        }
        return path
    }

    private var searchField: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
            TextField(
                "",
                text: $viewModel.filterQuery,
                prompt: Text("Search")
                    .foregroundColor(AppTheme.chromeMuted.opacity(0.75))
            )
                .textFieldStyle(.plain)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.chromeText)
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(AppTheme.chromeDarkElevated, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(AppTheme.chromeDivider, lineWidth: 1)
        )
    }

    private var branchButton: some View {
        Button {
            // MVP: read-only
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 10, weight: .semibold))
                Text(viewModel.currentBranch)
                    .font(.system(size: 9.5, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
            }
            .foregroundStyle(AppTheme.chromeText.opacity(0.95))
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(AppTheme.chromeDarkElevated, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(AppTheme.chromeDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverPressControl(cornerRadius: 5, hoverFillOpacity: 0.28, pressFillOpacity: 0.54)
        .opacity(1.0)
    }

    private func iconButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                .frame(width: 24, height: 22)
                .background(AppTheme.chromeDarkElevated, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(AppTheme.chromeDivider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .hoverPressControl(cornerRadius: 5, hoverFillOpacity: 0.28, pressFillOpacity: 0.54)
    }

    private func openRepoPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Repo"
        panel.message = "Choose a local Git repository"
        if panel.runModal() == .OK, let url = panel.url {
            Task { await viewModel.openRepo(path: url.path) }
        }
    }
}

private struct HeaderIcon: View {
    let symbol: String
    var tint: Color = AppTheme.chromeMuted

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(tint.opacity(0.9))
                .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
    }
}

enum SidebarMode {
    case project
    case commit
}

private enum CommitScope: String, CaseIterable {
    case all = "All"
    case staged = "Staged"
    case unstaged = "Unstaged"
}

private struct FileTreeEntry {
    let node: FileNode
    let depth: Int
}

private struct CommitTreeEntry {
    let id: String
    let name: String
    let fullPath: String
    let depth: Int
    let isDirectory: Bool
    let fileCount: Int
    let statusItem: StatusItem?
}

struct ToolWindowRail: View {
    let selected: SidebarMode
    let onSelect: (SidebarMode) -> Void

    var body: some View {
        VStack(spacing: 6) {
            RailModeIcon(
                symbol: "folder",
                active: selected == .project
            ) { onSelect(.project) }
            RailModeIcon(
                symbol: "arrow.triangle.branch",
                active: selected == .commit
            ) { onSelect(.commit) }
            Spacer(minLength: 0)
        }
        .padding(.top, 6)
        .frame(width: 32)
        .background(AppTheme.sidebarDark)
        .overlay(alignment: .trailing) { Rectangle().fill(AppTheme.chromeDivider).frame(width: 1) }
    }
}

private struct RailModeIcon: View {
    let symbol: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? AppTheme.chromeText : AppTheme.chromeMuted)
                .frame(width: 22, height: 22)
                .background(active ? AppTheme.chromeDarkElevated.opacity(0.95) : .clear)
                .overlay(Rectangle().stroke(active ? AppTheme.accent.opacity(0.45) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct LeftPanel: View {
    private enum PrefKey {
        static let leftTab = "ui.left.tab"
    }

    @ObservedObject var viewModel: RepoViewModel
    @State private var leftTab: LeftPanelMode = {
        let raw = UserDefaults.standard.string(forKey: PrefKey.leftTab)
        return LeftPanelMode(rawValue: raw ?? "") ?? .changes
    }()
    @State private var query: String = ""
    @State private var commitMessage: String = ""
    @State private var pendingDiscardItem: StatusItem? = nil
    @State private var showGitError: Bool = false
    @State private var keyMonitor: Any? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(AppTheme.chromeDivider)
            if leftTab == .changes {
                changesPanel
            } else {
                filesPanel
            }
        }
        .background(AppTheme.sidebarDark)
        .overlay(alignment: .trailing) { Rectangle().fill(AppTheme.chromeDivider).frame(width: 1) }
        .onAppear {
            viewModel.leftMode = leftTab
            installKeyMonitor()
        }
        .onChange(of: leftTab) { newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: PrefKey.leftTab)
            viewModel.leftMode = newValue
            if newValue == .changes {
                Task { await viewModel.loadDiffForSelection() }
            } else {
                Task { await viewModel.loadFileForSelection() }
            }
        }
        .onChange(of: viewModel.lastErrorMessage) { _ in
            showGitError = viewModel.lastErrorMessage != nil
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .alert(item: $pendingDiscardItem) { item in
            Alert(
                title: Text(item.isUntracked ? "Delete untracked file?" : "Discard changes?"),
                message: Text(item.path),
                primaryButton: .destructive(Text(item.isUntracked ? "Delete" : "Discard")) {
                    Task { await viewModel.discard(item: item) }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Git Error", isPresented: $showGitError) {
            Button("OK") { viewModel.lastErrorMessage = nil }
        } message: {
            Text(viewModel.lastErrorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            MVPLeftTabs(selection: $leftTab)
            Spacer(minLength: 0)
            if leftTab == .changes {
                Toggle("Group", isOn: $viewModel.groupDiffByFolder)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
    }

    private var changesPanel: some View {
        VStack(spacing: 0) {
            searchField(placeholder: "Filter files", text: $query)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

            HStack(spacing: 10) {
                Text("Changes: \(filteredStatusItems.count)")
                Text("Staged: \(viewModel.stagedCount)")
                Spacer(minLength: 0)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            HStack(spacing: 8) {
                Button("Stage All") { Task { await viewModel.stageAll() } }
                Button("Unstage All") { Task { await viewModel.unstageAll() } }
                Spacer(minLength: 0)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.chromeText)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            Divider().overlay(AppTheme.chromeDivider)

            ScrollView {
                if viewModel.statusItems.isEmpty {
                    EmptyLeftState(title: "Working tree clean", subtitle: nil)
                        .padding(.top, 18)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredStatusItems) { item in
                            MVPChangeRow(
                                item: item,
                                selected: item.path == viewModel.selectedPath,
                                onToggleStage: { Task { await viewModel.toggleStage(item: item) } },
                                onSelect: {
                                    viewModel.selectedPath = item.path
                                    viewModel.activateTab(item.path)
                                    Task { await viewModel.loadDiffForSelection() }
                                },
                                onDiscard: { requestDiscard(item) }
                            )
                            .contextMenu { statusItemContextMenu(item) }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Divider().overlay(AppTheme.chromeDivider)
            commitBox
        }
    }

    private var filesPanel: some View {
        VStack(spacing: 0) {
            searchField(placeholder: "Filter files", text: $query)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            Divider().overlay(AppTheme.chromeDivider)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredFileTreeRows, id: \.node.id) { entry in
                        ProjectTreeRow(
                            entry: entry,
                            fileStatus: nil,
                            isCollapsed: false,
                            isSelected: entry.node.id == viewModel.selectedFileID,
                            onTap: {
                                guard !entry.node.isDirectory else { return }
                                Task { await viewModel.selectAndLoadFile(path: entry.node.relativePath, id: entry.node.id) }
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var commitBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Commit Message")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $commitMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(4)
                    .frame(height: 64)
                    .background(AppTheme.editorBackground)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                if commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Write a commit message")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 8) {
                Button("Commit") { performCommit() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 78, height: 21)
                    .background(AppTheme.accent)
                    .opacity(canCommit ? 1.0 : 0.45)
                    .disabled(!canCommit)
                    .keyboardShortcut(.return, modifiers: .command)

                Spacer(minLength: 0)
                Text("branch \(viewModel.currentBranch)")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func searchField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.chromeText)
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(AppTheme.fieldFill)
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }

    private var filteredStatusItems: [StatusItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return viewModel.sortedStatusItems }
        return viewModel.sortedStatusItems.filter { $0.path.lowercased().contains(q) }
    }

    private var filteredFileTreeRows: [FileTreeEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let nodes = q.isEmpty ? viewModel.fileTree : filteredProjectNodes(viewModel.fileTree, query: q)
        return flattenProjectNodes(nodes, depth: 0)
    }

    private func flattenProjectNodes(_ nodes: [FileNode], depth: Int) -> [FileTreeEntry] {
        var out: [FileTreeEntry] = []
        for node in nodes {
            out.append(FileTreeEntry(node: node, depth: depth))
            if node.isDirectory, let children = node.children {
                out.append(contentsOf: flattenProjectNodes(children, depth: depth + 1))
            }
        }
        return out
    }

    private func filteredProjectNodes(_ nodes: [FileNode], query: String) -> [FileNode] {
        nodes.compactMap { node in
            let nameMatches = node.name.lowercased().contains(query)
            let pathMatches = node.relativePath.lowercased().contains(query)
            if node.isDirectory {
                let children = filteredProjectNodes(node.children ?? [], query: query)
                if !children.isEmpty || nameMatches || pathMatches {
                    return FileNode(
                        id: node.id,
                        name: node.name,
                        relativePath: node.relativePath,
                        absolutePath: node.absolutePath,
                        isDirectory: true,
                        children: children
                    )
                }
                return nil
            }
            return (nameMatches || pathMatches) ? node : nil
        }
    }

    private var commitTitle: String {
        commitMessage
            .split(separator: "\n", omittingEmptySubsequences: false)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var commitBody: String {
        let lines = commitMessage.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count > 1 else { return "" }
        return lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCommit: Bool {
        !commitTitle.isEmpty && viewModel.stagedCount > 0
    }

    private func performCommit() {
        guard canCommit else { return }
        Task {
            await viewModel.commit(title: commitTitle, body: commitBody)
        }
    }

    @ViewBuilder
    private func statusItemContextMenu(_ item: StatusItem) -> some View {
        Button(item.isStaged ? "Unstage" : "Stage") {
            Task { await viewModel.toggleStage(item: item) }
        }
        Button(item.isUntracked ? "Delete Untracked" : "Discard", role: .destructive) {
            requestDiscard(item)
        }
        Divider()
        Button("Copy Path") { copyPath(item.path) }
        Button("Open in Finder") { openInFinder(relativePath: item.path) }
    }

    private func requestDiscard(_ item: StatusItem) {
        pendingDiscardItem = item
    }

    private func copyPath(_ path: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
    }

    private func openInFinder(relativePath: String) {
        let url = URL(fileURLWithPath: viewModel.repoPath).appendingPathComponent(relativePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard leftTab == .changes else { return event }
            if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView || responder is NSTextField {
                return event
            }
            guard let chars = event.charactersIgnoringModifiers, chars.count == 1 else { return event }
            if chars == String(UnicodeScalar(NSDownArrowFunctionKey)!) {
                moveChangeSelection(step: 1)
                return nil
            }
            if chars == String(UnicodeScalar(NSUpArrowFunctionKey)!) {
                moveChangeSelection(step: -1)
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func moveChangeSelection(step: Int) {
        let items = filteredStatusItems
        guard !items.isEmpty else { return }
        let currentIndex = items.firstIndex { $0.path == viewModel.selectedPath } ?? 0
        let nextIndex = max(0, min(items.count - 1, currentIndex + step))
        let next = items[nextIndex]
        viewModel.leftMode = .changes
        viewModel.selectedPath = next.path
        viewModel.activateTab(next.path)
        Task { await viewModel.loadDiffForSelection() }
    }
}

private struct MVPLeftTabs: View {
    @Binding var selection: LeftPanelMode

    var body: some View {
        HStack(spacing: 0) {
            tab("Changes", mode: .changes)
            tab("Files", mode: .files)
        }
        .background(AppTheme.chromeDarkElevated)
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }

    private func tab(_ title: String, mode: LeftPanelMode) -> some View {
        Button {
            selection = mode
        } label: {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(selection == mode ? AppTheme.chromeText : AppTheme.chromeMuted)
                .frame(width: 74, height: 22)
                .background(selection == mode ? Color.white.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyLeftState: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText.opacity(0.9))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }
}

private struct MVPChangeRow: View {
    let item: StatusItem
    let selected: Bool
    let onToggleStage: () -> Void
    let onSelect: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggleStage) {
                Image(systemName: item.isStaged ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(item.isStaged ? AppTheme.accent : AppTheme.chromeMuted)
            }
            .buttonStyle(.plain)

            Text(statusLetter)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(statusColor)
                .frame(width: 12, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                    .lineLimit(1)
                if !dirPath.isEmpty {
                    Text(dirPath)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.75))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 0)

            if item.additions > 0 || item.deletions > 0 {
                Text("+\(item.additions)")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.green.opacity(0.85))
                Text("-\(item.deletions)")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.85))
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 21)
        .contentShape(Rectangle())
        .background(selected ? Color.white.opacity(0.07) : .clear)
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button(item.isUntracked ? "Delete Untracked" : "Discard", role: .destructive) {
                onDiscard()
            }
        }
    }

    private var statusLetter: String {
        if item.isUntracked { return "U" }
        if item.status.contains("A") { return "A" }
        if item.status.contains("D") { return "D" }
        return "M"
    }

    private var statusColor: Color {
        switch statusLetter {
        case "A": return Color.green.opacity(0.9)
        case "D": return Color.red.opacity(0.9)
        case "U": return Color.orange.opacity(0.9)
        default: return AppTheme.accent.opacity(0.9)
        }
    }

    private var fileName: String {
        URL(fileURLWithPath: item.path).lastPathComponent
    }

    private var dirPath: String {
        let dir = URL(fileURLWithPath: item.path).deletingLastPathComponent().path
        return dir == "/" ? "" : dir
    }
}

private struct CommitToolIcon: View {
    let symbol: String
    var tint: Color = AppTheme.chromeMuted

    var body: some View {
        Button {
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectTreeRow: View {
    let entry: FileTreeEntry
    let fileStatus: String?
    let isCollapsed: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(entry.depth) * 8, height: 1)

            if entry.node.isDirectory {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted)
                Image(systemName: "folder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
            } else {
                Color.clear.frame(width: 8, height: 1)
                Image(systemName: fileSymbol(entry.node.name))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(fileColor(entry.node.name))
            }

            Text(entry.node.name)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(isSelected ? AppTheme.chromeText : AppTheme.chromeMuted)
                .lineLimit(1)

            if let fileStatus, !entry.node.isDirectory {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusBadgeColor(fileStatus))
                        .frame(width: 5, height: 5)
                    Text(statusBadgeText(fileStatus))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(statusBadgeColor(fileStatus))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 21)
        .contentShape(Rectangle())
        .background(isSelected ? Color.white.opacity(0.07) : .clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isSelected ? AppTheme.accent.opacity(0.8) : .clear)
                .frame(width: 2)
        }
        .onTapGesture(perform: onTap)
    }

    private func fileSymbol(_ name: String) -> String {
        let lowered = name.lowercased()
        if lowered.hasSuffix(".swift") { return "swift" }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return "curlybraces" }
        if lowered.hasSuffix(".md") { return "text.alignleft" }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return "photo" }
        if lowered == "makefile" { return "hammer" }
        if lowered.hasSuffix(".rs") { return "r.square" }
        return "doc.text"
    }

    private func fileColor(_ name: String) -> Color {
        let lowered = name.lowercased()
        if lowered.hasSuffix(".swift") { return AppTheme.accent }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return Color.purple.opacity(0.85) }
        if lowered.hasSuffix(".md") { return Color.cyan.opacity(0.85) }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return Color.orange.opacity(0.9) }
        if lowered == "makefile" { return Color.yellow.opacity(0.9) }
        if lowered.hasSuffix(".rs") { return Color.red.opacity(0.85) }
        return AppTheme.chromeMuted
    }

    private func statusBadgeText(_ status: String) -> String {
        if status == "??" { return "U" }
        if status.contains("A") { return "A" }
        if status.contains("D") { return "D" }
        return "M"
    }

    private func statusBadgeColor(_ status: String) -> Color {
        if status == "??" { return Color.orange.opacity(0.95) }
        if status.contains("A") { return Color.green.opacity(0.95) }
        if status.contains("D") { return Color.red.opacity(0.95) }
        return AppTheme.accent
    }
}

private struct CommitSectionHeader: View {
    let title: String
    let count: Int
    let expanded: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "square")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppTheme.chromeMuted)
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted)
                Text(title)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(AppTheme.chromeText)
            Text("\(count) files")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 21)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct CommitTreeRow: View {
    let entry: CommitTreeEntry
    let isCollapsed: Bool
    let isSelected: Bool
    let onToggleStage: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(entry.depth - 1) * 9, height: 1)

            if entry.isDirectory {
                Image(systemName: "square")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.chromeMuted)
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted)
                Image(systemName: "folder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
                Text(entry.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.chromeText.opacity(0.9))
                    .lineLimit(1)
                Text("\(entry.fileCount) file\(entry.fileCount == 1 ? "" : "s")")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            } else {
                Button {
                    onToggleStage()
                } label: {
                    Image(systemName: (entry.statusItem?.isStaged ?? false) ? "checkmark.square.fill" : "square")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle((entry.statusItem?.isStaged ?? false) ? AppTheme.accent : AppTheme.chromeMuted)
                }
                .buttonStyle(.plain)
                Image(systemName: statusIcon(entry.statusItem?.status ?? ""))
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(statusColor(entry.statusItem?.status ?? ""))
                Text(entry.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.chromeText : statusTextColor(entry.statusItem?.status ?? ""))
                    .lineLimit(1)
                if let item = entry.statusItem {
                    Text("+\(item.additions)")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(Color.green.opacity(0.9))
                    Text("-\(item.deletions)")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.9))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 21)
        .contentShape(Rectangle())
        .background(isSelected ? Color.white.opacity(0.10) : .clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isSelected ? AppTheme.accent : .clear)
                .frame(width: 2)
        }
        .onTapGesture(perform: onTap)
    }

    private func statusIcon(_ status: String) -> String {
        if status == "??" { return "questionmark.circle" }
        if status.contains("A") { return "plus.circle" }
        if status.contains("D") { return "minus.circle" }
        return "pencil.circle"
    }

    private func statusColor(_ status: String) -> Color {
        if status == "??" { return Color.orange }
        if status.contains("A") { return Color.green }
        if status.contains("D") { return Color.red }
        return AppTheme.accent
    }

    private func statusTextColor(_ status: String) -> Color {
        if status == "??" { return Color(red: 0.90, green: 0.44, blue: 0.44) }
        if status.contains("A") { return Color(red: 0.48, green: 0.81, blue: 0.54) }
        if status.contains("D") { return Color(red: 0.89, green: 0.41, blue: 0.41) }
        return AppTheme.accent.opacity(0.9)
    }
}

struct DiffPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    private let diffFontPreset: DiffFontPreset = .medium
    @State private var selectedHunkIndex: Int = 0
    @State private var focusSelectedHunk: Bool = false
    @State private var showsCopiedBadgeHint: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.leftMode != .history {
                header
                Divider().overlay(AppTheme.chromeDividerStrong)
            }
            if viewModel.leftMode == .files {
                filesBody
            } else if viewModel.leftMode == .history {
                HistoryMainPanel(viewModel: viewModel)
            } else {
                changesBody
            }
        }
        .background(AppTheme.mainPanelGradient)
        .onChange(of: viewModel.selectedPath) { _ in
            selectedHunkIndex = 0
        }
        .onChange(of: viewModel.diffLines) { _ in
            selectedHunkIndex = 0
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(breadcrumb)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.82))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Button {
                #if os(macOS)
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(badgeText, forType: .string)
                #endif
                showsCopiedBadgeHint = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    showsCopiedBadgeHint = false
                }
            } label: {
                Text(showsCopiedBadgeHint ? "Copied" : badgeText)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.68))
                    .padding(.horizontal, 7)
                    .frame(height: 17)
                    .background(AppTheme.chromeDarkElevated.opacity(0.78), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(AppTheme.chromeDivider.opacity(0.75), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .hoverPressControl(cornerRadius: 4, hoverFillOpacity: 0.30, pressFillOpacity: 0.58)
        }
        .padding(.horizontal, 12)
        .frame(height: 29)
        .background(AppTheme.panelDark.opacity(0.92))
    }

    private var badgeText: String {
        if viewModel.leftMode == .files, !viewModel.fileContent.isEmpty {
            let bytes = Int64(viewModel.fileContent.utf8.count)
            let kb = max(0.1, (Double(bytes) / 1024.0))
            return String(format: "%.1f KB", kb)
        }
        return "Binary: No"
    }

    private var breadcrumb: String {
        guard viewModel.isRepoOpen else { return "Diff" }
        guard let path = viewModel.selectedPath, !path.isEmpty else { return "Diff" }
        let parts = path.split(separator: "/").map(String.init)
        if parts.count <= 1 { return path }
        return parts.joined(separator: "  >  ")
    }

    @ViewBuilder
    private var changesBody: some View {
        if !viewModel.isRepoOpen {
            EmptyMainState(title: "Open a repository", subtitle: "Use Open in the top bar")
        } else if viewModel.statusItems.isEmpty {
            EmptyMainState(title: "No changes to show", subtitle: nil)
        } else if viewModel.selectedPath == nil {
            EmptyMainState(title: "Select a file to view changes", subtitle: nil)
        } else if viewModel.diffLines.isEmpty {
            EmptyMainState(title: "No diff available", subtitle: nil)
        } else {
            IDEUnifiedDiff(
                lines: mapLines(viewModel.diffLines),
                split: false,
                fontPreset: diffFontPreset,
                selectedHunkIndex: selectedHunkIndex,
                focusSelectedHunk: focusSelectedHunk
            )
        }
    }

    @ViewBuilder
    private var filesBody: some View {
        if !viewModel.isRepoOpen {
            EmptyMainState(title: "Open a repository", subtitle: "Use Open in the top bar")
        } else if viewModel.selectedPath == nil {
            EmptyMainState(title: "Select a file to view file", subtitle: nil)
        } else {
            FileDetailView(
                text: $viewModel.fileContent,
                path: viewModel.selectedPath,
                isEditable: false,
                emptyText: "Select a file to view file"
            )
        }
    }

    private var hunkCount: Int {
        max(viewModel.diffLines.filter { $0.kind == .hunk }.count, 1)
    }

    private func jumpToPrevHunk() {
        guard hunkCount > 1 else { return }
        selectedHunkIndex = (selectedHunkIndex - 1 + hunkCount) % hunkCount
    }

    private func jumpToNextHunk() {
        guard hunkCount > 1 else { return }
        selectedHunkIndex = (selectedHunkIndex + 1) % hunkCount
    }

    private func mapLines(_ lines: [DiffLine]) -> [IDEDiffRow] {
        lines.map { line in
            switch line.kind {
            case .added:
                return IDEDiffRow(
                    oldNum: nil,
                    oldText: "",
                    newNum: line.newLine,
                    newText: String(line.text.dropFirst()),
                    kind: .added
                )
            case .removed:
                return IDEDiffRow(
                    oldNum: line.oldLine,
                    oldText: String(line.text.dropFirst()),
                    newNum: nil,
                    newText: "",
                    kind: .removed
                )
            case .hunk:
                return IDEDiffRow(
                    oldNum: nil,
                    oldText: line.text,
                    newNum: nil,
                    newText: line.text,
                    kind: .hunk
                )
            default:
                let text = line.text.first.map { ($0 == "+" || $0 == "-" || $0 == " ") ? String(line.text.dropFirst()) : line.text } ?? line.text
                return IDEDiffRow(
                    oldNum: line.oldLine,
                    oldText: text,
                    newNum: line.newLine,
                    newText: text,
                    kind: .normal
                )
            }
        }
    }
}

private struct FileDetailView: View {
    @Binding var text: String
    let path: String?
    let isEditable: Bool
    let emptyText: String

    var body: some View {
        if isEditable {
            TextEditor(text: $text)
                .font(.system(size: 13.5, weight: .regular, design: .monospaced))
                .foregroundStyle(AppTheme.chromeText)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(AppTheme.editorBackground)
        } else {
            ScrollView {
                Text(displayText)
                    .font(.system(size: 13.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(AppTheme.chromeText)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .background(AppTheme.editorBackground)
        }
    }

    private var displayText: String {
        if path == nil {
            return emptyText
        }
        return text.isEmpty ? emptyText : text
    }
}

private struct EmptyMainState: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText.opacity(0.92))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.93))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.editorBackground)
    }
}

private enum DiffFontPreset: String, CaseIterable {
    case small = "S"
    case medium = "M"
    case large = "L"

    var lineNumberSize: CGFloat {
        switch self {
        case .small: return 10.0
        case .medium: return 10.5
        case .large: return 11.5
        }
    }

    var codeSize: CGFloat {
        switch self {
        case .small: return 11.5
        case .medium: return 12.0
        case .large: return 13.5
        }
    }

    var rowHeight: CGFloat {
        switch self {
        case .small: return 19
        case .medium: return 20
        case .large: return 22
        }
    }
}

private struct EditorTabs: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabItems, id: \.self) { path in
                tab(
                    title: compact(path),
                    path: path,
                    pinned: viewModel.pinnedTabs.contains(path),
                    selected: path == viewModel.selectedPath
                ) {
                    viewModel.selectedPath = path
                    viewModel.activateTab(path)
                    Task {
                        if viewModel.leftMode == .changes {
                            await viewModel.loadDiffForSelection()
                        } else {
                            await viewModel.loadFileForSelection()
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 4)
        .frame(height: 24)
        .background(AppTheme.chromeDark)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
    }

    private var tabItems: [String] {
        if viewModel.displayedTabs.isEmpty, let current = viewModel.selectedPath {
            return [current]
        }
        return viewModel.displayedTabs
    }

    @ViewBuilder
    private func tab(title: String, path: String, pinned: Bool, selected: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selected ? AppTheme.accent : AppTheme.chromeMuted.opacity(0.9))
                    Text(title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(selected ? AppTheme.chromeText : AppTheme.chromeMuted)
                }
            }
            .buttonStyle(.plain)

            Button {
                viewModel.togglePinTab(path)
            } label: {
                Image(systemName: pinned ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(pinned ? AppTheme.accent : AppTheme.chromeMuted)
            }
            .buttonStyle(.plain)

            Button {
                let wasSelected = (viewModel.selectedPath == path)
                viewModel.closeTab(path)
                guard wasSelected else { return }
                Task {
                    if viewModel.leftMode == .changes {
                        await viewModel.loadDiffForSelection()
                    } else {
                        await viewModel.loadFileForSelection()
                    }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 9)
        .frame(height: 23)
        .background(selected ? AppTheme.chromeDarkElevated : AppTheme.chromeDark)
        .overlay(alignment: .bottom) {
            Rectangle().fill(selected ? AppTheme.accent : .clear).frame(height: 1.5)
        }
    }

    private func compact(_ path: String) -> String {
        path.split(separator: "/").last.map(String.init) ?? path
    }
}

private struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.chromeText : AppTheme.chromeMuted)
                .frame(minWidth: 60)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.chromeDarkElevated)
                .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isSelected ? AppTheme.accent : .clear)
                        .frame(height: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct SegmentedPill: View {
    let labels: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Button {
                    onSelect(index)
                } label: {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(index == selectedIndex ? .white : AppTheme.chromeMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(index == selectedIndex ? AppTheme.accent : AppTheme.chromeDarkElevated)
                        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }
}

private enum DiffKind {
    case normal
    case added
    case removed
    case hunk
}

private struct IDEDiffRow: Identifiable {
    let id = UUID()
    let oldNum: Int?
    let oldText: String
    let newNum: Int?
    let newText: String
    let kind: DiffKind
}

private struct IDEUnifiedDiff: View {
    let lines: [IDEDiffRow]
    let split: Bool
    let fontPreset: DiffFontPreset
    let selectedHunkIndex: Int
    let focusSelectedHunk: Bool
    @State private var collapsedHunks: Set<Int> = []
    @State private var hoveredRowIndex: Int? = nil

    private struct AnnotatedDiffRow: Identifiable {
        let id: Int
        let row: IDEDiffRow
        let hunkIndex: Int?
    }

    private var visibleRows: [AnnotatedDiffRow] {
        var out: [AnnotatedDiffRow] = []
        var currentHunk: Int? = nil
        var hunkCounter = -1

        for (index, row) in lines.enumerated() {
            if row.kind == .hunk {
                hunkCounter += 1
                currentHunk = hunkCounter
                if focusSelectedHunk && currentHunk != selectedHunkIndex {
                    continue
                }
                out.append(AnnotatedDiffRow(id: index, row: row, hunkIndex: currentHunk))
                continue
            }

            if focusSelectedHunk && currentHunk != selectedHunkIndex {
                continue
            }
            if let hunk = currentHunk, collapsedHunks.contains(hunk) {
                continue
            }
            out.append(AnnotatedDiffRow(id: index, row: row, hunkIndex: currentHunk))
        }
        return out
    }

    var body: some View {
        if split {
            HStack(spacing: 0) {
                DiffColumn(
                    lines: visibleRows,
                    side: .old,
                    fontPreset: fontPreset,
                    collapsedHunks: collapsedHunks,
                    selectedHunkIndex: selectedHunkIndex,
                    focusSelectedHunk: focusSelectedHunk,
                    hoveredRowIndex: $hoveredRowIndex
                ) { hunk in
                    toggleHunk(hunk)
                }
                Rectangle().fill(AppTheme.chromeDivider).frame(width: 1)
                DiffColumn(
                    lines: visibleRows,
                    side: .new,
                    fontPreset: fontPreset,
                    collapsedHunks: collapsedHunks,
                    selectedHunkIndex: selectedHunkIndex,
                    focusSelectedHunk: focusSelectedHunk,
                    hoveredRowIndex: $hoveredRowIndex
                ) { hunk in
                    toggleHunk(hunk)
                }
            }
        } else {
            DiffColumn(
                lines: visibleRows,
                side: .merged,
                fontPreset: fontPreset,
                collapsedHunks: collapsedHunks,
                selectedHunkIndex: selectedHunkIndex,
                focusSelectedHunk: focusSelectedHunk,
                hoveredRowIndex: $hoveredRowIndex
            ) { hunk in
                toggleHunk(hunk)
            }
        }
    }

    private func toggleHunk(_ hunk: Int) {
        if collapsedHunks.contains(hunk) {
            collapsedHunks.remove(hunk)
        } else {
            collapsedHunks.insert(hunk)
        }
    }

    private enum Side { case old, new, merged }

    private struct DiffColumn: View {
        let lines: [AnnotatedDiffRow]
        let side: Side
        let fontPreset: DiffFontPreset
        let collapsedHunks: Set<Int>
        let selectedHunkIndex: Int
        let focusSelectedHunk: Bool
        @Binding var hoveredRowIndex: Int?
        let onToggleHunk: (Int) -> Void

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(lines) { annotated in
                            let row = annotated.row
                            if row.kind == .hunk {
                                HStack {
                                    if let hunkIndex = annotated.hunkIndex {
                                        Button {
                                            onToggleHunk(hunkIndex)
                                        } label: {
                                            Image(systemName: collapsedHunks.contains(hunkIndex) ? "chevron.right" : "chevron.down")
                                                .font(.system(size: 10.5, weight: .bold))
                                                .foregroundStyle(AppTheme.chromeMuted)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Text(side == .old ? row.oldText : row.newText)
                                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                        .foregroundStyle((annotated.hunkIndex == selectedHunkIndex) ? AppTheme.chromeText : AppTheme.accent.opacity(0.95))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 22)
                                .background((annotated.hunkIndex == selectedHunkIndex) ? AppTheme.diffHunkSelectedFill : AppTheme.diffHunkFill)
                                .overlay(alignment: .top) { Rectangle().fill(AppTheme.chromeDivider.opacity(0.65)).frame(height: 1) }
                                .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider.opacity(0.65)).frame(height: 1) }
                            } else {
                                let lineNum: Int? = {
                                    switch side {
                                    case .old:
                                        return row.oldNum
                                    case .new:
                                        return row.newNum
                                    case .merged:
                                        return row.newNum ?? row.oldNum
                                    }
                                }()
                                let text: String = {
                                    switch side {
                                    case .old:
                                        return row.oldText
                                    case .new:
                                        return row.newText
                                    case .merged:
                                        switch row.kind {
                                        case .added: return "+ \(row.newText)"
                                        case .removed: return "- \(row.oldText)"
                                        default: return row.newText
                                        }
                                    }
                                }()

                                HStack(spacing: 6) {
                                    Text(lineNum.map(String.init) ?? "")
                                        .font(.system(size: fontPreset.lineNumberSize, weight: .regular, design: .monospaced))
                                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.82))
                                        .frame(width: 32, alignment: .trailing)

                                    Text(text)
                                        .font(.system(size: fontPreset.codeSize, weight: .regular, design: .monospaced))
                                        .foregroundStyle(AppTheme.chromeText.opacity(0.94))
                                        .lineLimit(1)

                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 9)
                                .frame(height: fontPreset.rowHeight)
                                .background(backgroundColor(for: row, side: side))
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(stripeColor(for: row, side: side))
                                        .frame(width: 2)
                                }
                                .overlay(
                                    Rectangle()
                                        .fill((hoveredRowIndex == annotated.id) ? Color.white.opacity(0.05) : .clear)
                                )
                                .onHover { inside in
                                    if inside {
                                        hoveredRowIndex = annotated.id
                                    } else if hoveredRowIndex == annotated.id {
                                        hoveredRowIndex = nil
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    scrollToSelectedHunk(proxy)
                }
                .onChange(of: selectedHunkIndex) { _ in
                    scrollToSelectedHunk(proxy)
                }
                .onChange(of: focusSelectedHunk) { _ in
                    scrollToSelectedHunk(proxy)
                }
            }
            .background(AppTheme.editorBackground)
        }

        private func backgroundColor(for row: IDEDiffRow, side: Side) -> Color {
            switch row.kind {
            case .normal:
                return Color.clear
            case .added:
                return (side == .new || side == .merged) ? AppTheme.diffAddedFill : Color.clear
            case .removed:
                return (side == .old || side == .merged) ? AppTheme.diffRemovedFill : Color.clear
            case .hunk:
                return Color.clear
            }
        }

        private func stripeColor(for row: IDEDiffRow, side: Side) -> Color {
            switch row.kind {
            case .added:
                return (side == .new || side == .merged) ? AppTheme.diffAddedStripe : .clear
            case .removed:
                return (side == .old || side == .merged) ? AppTheme.diffRemovedStripe : .clear
            default:
                return .clear
            }
        }

        private func scrollToSelectedHunk(_ proxy: ScrollViewProxy) {
            guard let target = lines.first(where: { $0.hunkIndex == selectedHunkIndex }) else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(target.id, anchor: .top)
                }
            }
        }
    }
}

private struct HeaderAction: View {
    let symbol: String

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .background(AppTheme.chromeDarkElevated.opacity(0.75))
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }
}

private struct RightPaneHoverPressModifier: ViewModifier {
    let cornerRadius: CGFloat
    let hoverFillOpacity: Double
    let pressFillOpacity: Double

    @State private var isHovering: Bool = false
    @GestureState private var isPressing: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                (isPressing
                    ? AppTheme.chromeDarkElevated.opacity(pressFillOpacity)
                    : (isHovering ? AppTheme.chromeDarkElevated.opacity(hoverFillOpacity) : .clear)
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isHovering ? AppTheme.chromeDivider.opacity(0.55) : .clear, lineWidth: 1)
            )
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
}

private extension View {
    func hoverPressControl(cornerRadius: CGFloat, hoverFillOpacity: Double, pressFillOpacity: Double) -> some View {
        modifier(
            RightPaneHoverPressModifier(
                cornerRadius: cornerRadius,
                hoverFillOpacity: hoverFillOpacity,
                pressFillOpacity: pressFillOpacity
            )
        )
    }
}

private struct BreadcrumbPath: View {
    let path: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.7))
                }
                Text(segment)
                    .font(.system(size: 11, weight: index == segments.count - 1 ? .semibold : .medium))
                    .foregroundStyle(index == segments.count - 1 ? AppTheme.chromeText : AppTheme.chromeMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    private var segments: [String] {
        let parts = path.split(separator: "/").map(String.init)
        if parts.isEmpty { return [path] }
        if parts.count <= 4 { return parts }
        return [parts[0], "...", parts[parts.count - 2], parts[parts.count - 1]]
    }
}

private struct ChangeCountPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.chromeDarkElevated.opacity(0.85))
            .overlay(Rectangle().stroke(tint.opacity(0.35), lineWidth: 1))
    }
}

struct BottomPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var activeTab: BottomTab = .terminal

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                BottomTabButton(title: "Terminal", selected: activeTab == .terminal) {
                    activeTab = .terminal
                }
                BottomTabButton(title: "Output", selected: activeTab == .output) {
                    activeTab = .output
                }
                BottomTabButton(title: "Detail", selected: activeTab == .detail) {
                    activeTab = .detail
                }

                Spacer(minLength: 0)

                Button("Refresh") {
                    Task {
                        await viewModel.runStatus()
                        if viewModel.leftMode == .changes {
                            await viewModel.loadDiffForSelection()
                        } else {
                            await viewModel.loadFileForSelection()
                        }
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.chromeDarkElevated)
                .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                Text("New Tab")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.chromeDarkElevated)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
            }
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(AppTheme.chromeDark)
            .overlay(alignment: .top) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }

            Group {
                switch activeTab {
                case .terminal:
                    TerminalPanel(viewModel: viewModel)
                case .output:
                    ScrollView {
                        Text(viewModel.output.isEmpty ? "No output yet." : viewModel.output)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                case .detail:
                    ScrollView {
                        Text(viewModel.detailOutput.isEmpty ? "No detail output yet." : viewModel.detailOutput)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(AppTheme.chromeMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(6)
            .background(AppTheme.chromeDarkElevated)
        }
    }
}

private struct TerminalPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                TextField("Command", text: $viewModel.terminalCommand)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(.horizontal, 7)
                    .frame(height: 20)
                    .background(AppTheme.fieldFill)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                Button(viewModel.isTerminalRunning ? "Running..." : "Run") {
                    Task { await viewModel.runTerminalCommand() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(viewModel.isTerminalRunning ? AppTheme.chromeMuted : AppTheme.chromeText)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppTheme.chromeDarkElevated)
                .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
                .disabled(viewModel.isTerminalRunning)
            }

            ScrollView {
                Text(viewModel.terminalOutput)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.chromeMuted)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private enum BottomTab: String {
    case terminal
    case output
    case detail
}

private struct BottomTabButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(selected ? AppTheme.chromeText : AppTheme.chromeMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(selected ? AppTheme.accent : .clear).frame(height: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}
