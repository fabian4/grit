import SwiftUI
import AppKit

struct TopBar: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "line.3.horizontal")
                Image(systemName: "folder")
                Text("untitled-project")
                    .font(.system(size: 12, weight: .semibold))

                HeaderIcon(symbol: "tray.and.arrow.up")
                HeaderIcon(symbol: "arrow.triangle.branch")
            }
            .foregroundStyle(AppTheme.chromeText)
            .frame(width: 292, alignment: .leading)
            .padding(.leading, 8)

            Rectangle()
                .fill(AppTheme.chromeDivider)
                .frame(width: 1, height: 18)
                .padding(.horizontal, 7)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.chromeMuted)
                Text("Search everywhere")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted)
                Spacer(minLength: 0)
                Text("Double Shift")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted)
            }
            .padding(.horizontal, 10)
            .frame(width: 356, height: 22)
            .background(AppTheme.fieldFill)
            .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

            Spacer(minLength: 0)

            Rectangle()
                .fill(AppTheme.chromeDivider)
                .frame(width: 1, height: 18)
                .padding(.horizontal, 8)

            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                    Text("master")
                }
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)

                HeaderIcon(symbol: "play.fill", tint: AppTheme.accent)
                HeaderIcon(symbol: "ladybug.fill")
                HeaderIcon(symbol: "gearshape")

                Button("Open") {
                    Task { await viewModel.openRepo() }
                }
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.accent)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 30)
        .background(AppTheme.chromeDark)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
    }
}

private struct HeaderIcon: View {
    let symbol: String
    var tint: Color = AppTheme.chromeText

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 14, height: 14)
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
        VStack(spacing: 7) {
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
        .padding(.top, 8)
        .frame(width: 36)
        .background(AppTheme.chromeDark)
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(active ? AppTheme.chromeText : AppTheme.chromeMuted)
                .frame(width: 24, height: 24)
                .background(active ? AppTheme.chromeDarkElevated.opacity(0.95) : .clear)
                .overlay(Rectangle().stroke(active ? AppTheme.accent.opacity(0.45) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct LeftPanel: View {
    private enum PrefKey {
        static let commitScope = "ui.commit.scope"
        static let projectChangedOnly = "ui.project.changedOnly"
    }

    @ObservedObject var viewModel: RepoViewModel
    @State private var sidebarMode: SidebarMode = .project
    @State private var commitScope: CommitScope = {
        let raw = UserDefaults.standard.string(forKey: PrefKey.commitScope)
        return CommitScope(rawValue: raw ?? "") ?? .unstaged
    }()
    @State private var showChangedOnly: Bool = UserDefaults.standard.bool(forKey: PrefKey.projectChangedOnly)
    @State private var amendCommit: Bool = false
    @State private var commitMessage: String = "Add AppTheme and enhance UI components with new styling, and layout"
    @State private var fileQuery: String = ""
    @State private var collapsedProjectDirectories: Set<String> = []
    @State private var collapsedCommitDirectories: Set<String> = []

    var body: some View {
        HStack(spacing: 0) {
            ToolWindowRail(selected: sidebarMode, onSelect: switchMode)

            VStack(alignment: .leading, spacing: 0) {
                if sidebarMode == .project {
                    projectPanel
                } else {
                    commitPanel
                }
            }
            .background(AppTheme.chromeDark)
            .overlay(alignment: .trailing) { Rectangle().fill(AppTheme.chromeDivider).frame(width: 1) }
        }
        .onAppear {
            switchMode(.project)
            prepareInitialCollapsedState()
        }
        .onChange(of: commitScope) { newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: PrefKey.commitScope)
        }
        .onChange(of: showChangedOnly) { newValue in
            UserDefaults.standard.set(newValue, forKey: PrefKey.projectChangedOnly)
        }
        .onChange(of: viewModel.selectedFileID) { _ in
            guard sidebarMode == .project else { return }
            guard viewModel.leftMode == .files else { return }
            Task { await viewModel.loadFileForSelection() }
        }
    }

    @ViewBuilder
    private var projectPanel: some View {
        panelHeader(title: "Project", leadingIcon: "folder", trailingIcon: "plus")

        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            TextField("Filter files", text: $fileQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.chromeText)
        }
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(AppTheme.fieldFill)
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)

        HStack(spacing: 8) {
            Button {
                showChangedOnly.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showChangedOnly ? "checkmark.circle.fill" : "circle")
                    Text("Changed only")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(showChangedOnly ? AppTheme.accent : AppTheme.chromeMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(showChangedOnly ? AppTheme.chromeDarkElevated : Color.clear)
                .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)

        Divider().overlay(AppTheme.chromeDivider)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: isProjectCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted)
                    Image(systemName: "folder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted)
                    Text("grit")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.chromeText)
                    Text("~/Projects/grit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 9)
                .frame(height: 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleProjectDirectory(id: "__root__")
                }

                if !isProjectCollapsed {
                    ForEach(filteredProjectTreeRows, id: \.node.id) { entry in
                        ProjectTreeRow(
                            entry: entry,
                            fileStatus: statusByPath[entry.node.relativePath],
                            isCollapsed: collapsedProjectDirectories.contains(entry.node.id),
                            isSelected: entry.node.id == viewModel.selectedFileID,
                            onTap: {
                                if entry.node.isDirectory {
                                    toggleProjectDirectory(id: entry.node.id)
                                } else {
                                    Task { await viewModel.selectAndLoadFile(path: entry.node.relativePath, id: entry.node.id) }
                                }
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var commitPanel: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            Text("Commit")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.chromeText)
            Button("Commit") {}
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(AppTheme.chromeDarkElevated)
                .overlay(Rectangle().stroke(AppTheme.accent.opacity(0.55), lineWidth: 1))
            Spacer(minLength: 0)
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted)
        }
        .padding(.horizontal, 9)
        .frame(height: 32)

        Divider().overlay(AppTheme.chromeDivider)

        HStack(spacing: 7) {
            Image(systemName: "square")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppTheme.chromeMuted)
            Rectangle()
                .fill(AppTheme.chromeDivider.opacity(0.8))
                .frame(width: 1, height: 12)
            CommitToolIcon(symbol: "arrow.triangle.2.circlepath")
            CommitToolIcon(symbol: "arrow.uturn.backward")
            CommitToolIcon(symbol: "tray.and.arrow.down")
            CommitToolIcon(symbol: "infinity", tint: Color.purple.opacity(0.85))
            CommitToolIcon(symbol: "eye")
            CommitToolIcon(symbol: "chevron.down")
            CommitToolIcon(symbol: "xmark")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(height: 25)

        Divider().overlay(AppTheme.chromeDivider)

        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    CommitSectionHeader(
                        title: "Changes",
                        count: changedStatusItems.count,
                        expanded: !collapsedCommitDirectories.contains("__section_changed__")
                    ) {
                        toggleCommitDirectory(id: "__section_changed__")
                    }
                    if !collapsedCommitDirectories.contains("__section_changed__") {
                        ForEach(changedCommitTreeRows, id: \.id) { entry in
                            CommitTreeRow(
                                entry: entry,
                                isCollapsed: collapsedCommitDirectories.contains(entry.id),
                                isSelected: entry.statusItem?.path == viewModel.selectedPath,
                                onTap: {
                                    if entry.isDirectory {
                                        toggleCommitDirectory(id: entry.id)
                                    } else if let item = entry.statusItem {
                                        viewModel.leftMode = .changes
                                        viewModel.selectedPath = item.path
                                        viewModel.activateTab(item.path)
                                        Task { await viewModel.loadDiffForSelection() }
                                    }
                                }
                            )
                        }
                    }

                    CommitSectionHeader(
                        title: "Unversioned Files",
                        count: untrackedStatusItems.count,
                        expanded: !collapsedCommitDirectories.contains("__section_untracked__")
                    ) {
                        toggleCommitDirectory(id: "__section_untracked__")
                    }
                    if !collapsedCommitDirectories.contains("__section_untracked__") {
                        ForEach(untrackedCommitTreeRows, id: \.id) { entry in
                            CommitTreeRow(
                                entry: entry,
                                isCollapsed: collapsedCommitDirectories.contains(entry.id),
                                isSelected: entry.statusItem?.path == viewModel.selectedPath,
                                onTap: {
                                    if entry.isDirectory {
                                        toggleCommitDirectory(id: entry.id)
                                    } else if let item = entry.statusItem {
                                        viewModel.leftMode = .changes
                                        viewModel.selectedPath = item.path
                                        viewModel.activateTab(item.path)
                                        Task { await viewModel.loadDiffForSelection() }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 5)
            }

            Divider().overlay(AppTheme.chromeDivider)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Toggle("Amend", isOn: $amendCommit)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted)
                    Image(systemName: "circle")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                    Image(systemName: "clock")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted)
                    Image(systemName: "sparkles")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted)
                    Spacer(minLength: 0)
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted)
                }
                .frame(height: 19)

                TextEditor(text: $commitMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(5)
                    .frame(height: 90)
                    .background(AppTheme.editorBackground)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                HStack(spacing: 7) {
                    Button("Commit") {}
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 24)
                        .background(AppTheme.accent)

                    Button("Commit and Push...") {}
                        .buttonStyle(.plain)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeText)
                        .frame(width: 128, height: 24)
                        .background(AppTheme.chromeDarkElevated)
                        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                    Spacer(minLength: 0)
                    Image(systemName: "gearshape")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppTheme.chromeDark.opacity(0.65))
        }
    }

    @ViewBuilder
    private func panelHeader(title: String, leadingIcon: String, trailingIcon: String?) -> some View {
        HStack(spacing: 7) {
            Image(systemName: leadingIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.chromeText)
            Spacer(minLength: 0)
            if let trailingIcon {
                Button {} label: {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 34)
    }

    private func switchMode(_ mode: SidebarMode) {
        sidebarMode = mode
        switch mode {
        case .project:
            viewModel.leftMode = .files
            ensureProjectSelection()
            Task { await viewModel.loadFileForSelection() }
        case .commit:
            commitScope = .all
            viewModel.leftMode = .changes
            ensureCommitSelection()
            Task { await viewModel.loadDiffForSelection() }
        }
    }

    private func ensureProjectSelection() {
        if let selectedID = viewModel.selectedFileID,
           let node = findNode(id: selectedID, in: viewModel.fileTree),
           !node.isDirectory {
            viewModel.selectedPath = node.relativePath
            viewModel.activateTab(node.relativePath)
            return
        }

        if let firstFile = firstFileNode(in: viewModel.fileTree) {
            Task { await viewModel.selectAndLoadFile(path: firstFile.relativePath, id: firstFile.id) }
        }
    }

    private func ensureCommitSelection() {
        if let selected = viewModel.selectedPath,
           scopedStatusItems.contains(where: { $0.path == selected }) {
            viewModel.activateTab(selected)
            return
        }

        if let first = scopedStatusItems.first?.path ?? viewModel.sortedStatusItems.first?.path {
            viewModel.selectedPath = first
            viewModel.activateTab(first)
        }
    }

    private func firstFileNode(in nodes: [FileNode]) -> FileNode? {
        for node in nodes {
            if node.isDirectory {
                if let child = firstFileNode(in: node.children ?? []) {
                    return child
                }
            } else {
                return node
            }
        }
        return nil
    }

    private func findNode(id: String, in nodes: [FileNode]) -> FileNode? {
        for node in nodes {
            if node.id == id { return node }
            if let children = node.children,
               let match = findNode(id: id, in: children) {
                return match
            }
        }
        return nil
    }

    private func prepareInitialCollapsedState() {
        guard collapsedProjectDirectories.isEmpty else { return }
        collapsedProjectDirectories = Set(collectDirectoryIDs(nodes: viewModel.fileTree))
        collapsedProjectDirectories.insert("__root__")
        collapsedCommitDirectories.insert("__section_untracked__")
        collapsedCommitDirectories.insert("dir:untracked:__repo_root__")
    }

    private func collectDirectoryIDs(nodes: [FileNode]) -> [String] {
        var out: [String] = []
        for node in nodes {
            if node.isDirectory {
                out.append(node.id)
                out.append(contentsOf: collectDirectoryIDs(nodes: node.children ?? []))
            }
        }
        return out
    }

    private var isProjectCollapsed: Bool {
        collapsedProjectDirectories.contains("__root__")
    }

    private var filteredProjectTreeRows: [FileTreeEntry] {
        let query = fileQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let prefiltered = showChangedOnly ? filterNodesByChanged(viewModel.fileTree) : viewModel.fileTree
        let nodes = query.isEmpty ? prefiltered : filteredProjectNodes(prefiltered, query: query)
        return flattenProjectNodes(nodes, depth: 0)
    }

    private var statusByPath: [String: String] {
        Dictionary(uniqueKeysWithValues: viewModel.sortedStatusItems.map { ($0.path, $0.status) })
    }

    private func flattenProjectNodes(_ nodes: [FileNode], depth: Int) -> [FileTreeEntry] {
        var out: [FileTreeEntry] = []
        for node in nodes {
            out.append(FileTreeEntry(node: node, depth: depth))
            if node.isDirectory,
               !collapsedProjectDirectories.contains(node.id),
               let children = node.children {
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

    private func filterNodesByChanged(_ nodes: [FileNode]) -> [FileNode] {
        nodes.compactMap { node in
            if node.isDirectory {
                let children = filterNodesByChanged(node.children ?? [])
                return children.isEmpty ? nil : FileNode(
                    id: node.id,
                    name: node.name,
                    relativePath: node.relativePath,
                    absolutePath: node.absolutePath,
                    isDirectory: true,
                    children: children
                )
            }
            return statusByPath[node.relativePath] != nil ? node : nil
        }
    }

    private func toggleProjectDirectory(id: String) {
        if collapsedProjectDirectories.contains(id) {
            collapsedProjectDirectories.remove(id)
        } else {
            collapsedProjectDirectories.insert(id)
        }
    }

    private var changedStatusItems: [StatusItem] {
        scopedStatusItems.filter { $0.status != "??" }
    }

    private var untrackedStatusItems: [StatusItem] {
        scopedStatusItems.filter { $0.status == "??" }
    }

    private var scopedStatusItems: [StatusItem] {
        switch commitScope {
        case .all:
            return viewModel.sortedStatusItems
        case .staged:
            return viewModel.sortedStatusItems.filter { isStaged($0.status) }
        case .unstaged:
            return viewModel.sortedStatusItems.filter { isUnstaged($0.status) }
        }
    }

    private func isStaged(_ status: String) -> Bool {
        guard status.count >= 1 else { return false }
        let chars = Array(status)
        let x = chars[0]
        return x != " " && x != "?"
    }

    private func isUnstaged(_ status: String) -> Bool {
        guard status.count >= 2 else { return false }
        if status == "??" { return true }
        let chars = Array(status)
        let y = chars[1]
        return y != " "
    }

    private var changedCommitTreeRows: [CommitTreeEntry] {
        flattenCommitItems(changedStatusItems, sectionID: "changed")
    }

    private var untrackedCommitTreeRows: [CommitTreeEntry] {
        let base = flattenCommitItems(untrackedStatusItems, sectionID: "untracked")
        let rootID = "dir:untracked:__repo_root__"
        let root = CommitTreeEntry(
            id: rootID,
            name: "grit",
            fullPath: "__repo_root__",
            depth: 1,
            isDirectory: true,
            fileCount: untrackedStatusItems.count,
            statusItem: nil
        )
        if collapsedCommitDirectories.contains(rootID) {
            return [root]
        }
        let shifted = base.map { entry in
            CommitTreeEntry(
                id: entry.id,
                name: entry.name,
                fullPath: entry.fullPath,
                depth: entry.depth + 1,
                isDirectory: entry.isDirectory,
                fileCount: entry.fileCount,
                statusItem: entry.statusItem
            )
        }
        return [root] + shifted
    }

    private func flattenCommitItems(_ items: [StatusItem], sectionID: String) -> [CommitTreeEntry] {
        var rows: [CommitTreeEntry] = []
        var seenDirectories: Set<String> = []
        var dirCount: [String: Int] = [:]

        for item in items {
            let parts = item.path.split(separator: "/").map(String.init)
            if parts.count > 1 {
                for idx in 0..<(parts.count - 1) {
                    let dirPath = parts[0...idx].joined(separator: "/")
                    dirCount[dirPath, default: 0] += 1
                }
            }
        }

        for item in items.sorted(by: { $0.path.lowercased() < $1.path.lowercased() }) {
            let parts = item.path.split(separator: "/").map(String.init)
            if parts.count > 1 {
                for idx in 0..<(parts.count - 1) {
                    let dirPath = parts[0...idx].joined(separator: "/")
                    let dirID = "dir:\(sectionID):\(dirPath)"
                    if !seenDirectories.contains(dirID) {
                        rows.append(
                            CommitTreeEntry(
                                id: dirID,
                                name: parts[idx],
                                fullPath: dirPath,
                                depth: idx + 1,
                                isDirectory: true,
                                fileCount: dirCount[dirPath, default: 0],
                                statusItem: nil
                            )
                        )
                        seenDirectories.insert(dirID)
                    }
                }
            }

            let fileName = parts.last ?? item.path
            rows.append(
                CommitTreeEntry(
                    id: "file:\(sectionID):\(item.path)",
                    name: fileName,
                    fullPath: item.path,
                    depth: max(parts.count, 1),
                    isDirectory: false,
                    fileCount: 0,
                    statusItem: item
                )
            )
        }

        return rows.filter { row in
            isCommitRowVisible(row, sectionID: sectionID)
        }
    }

    private func isCommitRowVisible(_ row: CommitTreeEntry, sectionID: String) -> Bool {
        if sectionID == "untracked" && collapsedCommitDirectories.contains("dir:untracked:__repo_root__") {
            return row.id == "dir:untracked:__repo_root__"
        }
        let parts = row.fullPath.split(separator: "/").map(String.init)
        guard parts.count > 1 else { return true }
        var path = ""
        let upto = row.isDirectory ? parts.count - 1 : parts.count - 2
        if upto < 0 { return true }
        for idx in 0...upto {
            path = path.isEmpty ? parts[idx] : "\(path)/\(parts[idx])"
            let id = "dir:\(sectionID):\(path)"
            if id != row.id && collapsedCommitDirectories.contains(id) {
                return false
            }
        }
        return true
    }

    private func toggleCommitDirectory(id: String) {
        if collapsedCommitDirectories.contains(id) {
            collapsedCommitDirectories.remove(id)
        } else {
            collapsedCommitDirectories.insert(id)
        }
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
            Color.clear.frame(width: CGFloat(entry.depth) * 10, height: 1)

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
                .font(.system(size: 14, weight: .regular))
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
        .padding(.horizontal, 9)
        .frame(height: 25)
        .contentShape(Rectangle())
        .background(isSelected ? AppTheme.chromeDarkElevated.opacity(0.74) : .clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isSelected ? AppTheme.accent : .clear)
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
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.chromeText)
            Text("\(count) files")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(height: 25)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct CommitTreeRow: View {
    let entry: CommitTreeEntry
    let isCollapsed: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(entry.depth - 1) * 11, height: 1)

            if entry.isDirectory {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.chromeMuted)
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted)
                Image(systemName: "folder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
                Text(entry.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeText.opacity(0.9))
                    .lineLimit(1)
                Text("\(entry.fileCount) file\(entry.fileCount == 1 ? "" : "s")")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            } else {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.chromeMuted)
                Image(systemName: statusIcon(entry.statusItem?.status ?? ""))
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(statusColor(entry.statusItem?.status ?? ""))
                Text(entry.name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isSelected ? AppTheme.chromeText : statusTextColor(entry.statusItem?.status ?? ""))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(height: 22)
        .contentShape(Rectangle())
        .background(isSelected ? AppTheme.chromeDarkElevated.opacity(0.74) : .clear)
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

struct MainPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    private let diffFontPreset: DiffFontPreset = .large
    @State private var selectedHunkIndex: Int = 0
    @State private var focusSelectedHunk: Bool = false
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            EditorTabs(viewModel: viewModel)

            if viewModel.leftMode == .changes {
                IDEUnifiedDiff(
                    lines: mapLines(viewModel.diffLines),
                    split: viewModel.diffMode == .sideBySide,
                    fontPreset: diffFontPreset,
                    selectedHunkIndex: selectedHunkIndex,
                    focusSelectedHunk: focusSelectedHunk
                )
            } else {
                FileDetailView(
                    text: $viewModel.fileContent,
                    path: viewModel.selectedPath,
                    isEditable: viewModel.isDetailEditable
                )
            }
        }
        .background(AppTheme.editorBackground)
        .onChange(of: viewModel.selectedPath) { _ in
            selectedHunkIndex = 0
        }
        .onChange(of: viewModel.diffLines) { _ in
            selectedHunkIndex = 0
        }
        .onAppear {
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
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

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard viewModel.leftMode == .changes else { return event }
            guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return event }
            if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView || responder is NSTextField {
                return event
            }
            guard let chars = event.charactersIgnoringModifiers, chars.count == 1 else { return event }
            switch chars {
            case "]", "j":
                jumpToNextHunk()
                return nil
            case "[", "k":
                jumpToPrevHunk()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func mapLines(_ lines: [DiffLine]) -> [IDEDiffRow] {
        if lines.isEmpty {
            return demoRows
        }

        let mapped = lines.map { line in
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

        let visibleCount = mapped.filter {
            !($0.oldText.trimmingCharacters(in: .whitespaces).isEmpty &&
              $0.newText.trimmingCharacters(in: .whitespaces).isEmpty)
        }.count
        return visibleCount < 4 ? demoRows : mapped
    }

    private var demoRows: [IDEDiffRow] {
        [
                IDEDiffRow(oldNum: 1, oldText: "package com.example.app", newNum: 1, newText: "package com.example.app", kind: .normal),
                IDEDiffRow(oldNum: 2, oldText: "", newNum: 2, newText: "", kind: .normal),
                IDEDiffRow(oldNum: 3, oldText: "import java.util.Scanner", newNum: 3, newText: "import java.util.Scanner", kind: .normal),
                IDEDiffRow(oldNum: nil, oldText: "", newNum: 4, newText: "val greeting = \"Welcome back\"", kind: .added),
                IDEDiffRow(oldNum: 4, oldText: "val greeting = \"Hello, User\"", newNum: nil, newText: "", kind: .removed),
                IDEDiffRow(oldNum: 5, oldText: "", newNum: 5, newText: "fun main() {", kind: .normal),
                IDEDiffRow(oldNum: 6, oldText: "println(greeting)", newNum: 6, newText: "println(greeting)", kind: .normal)
        ]
    }
}

private struct FileDetailView: View {
    @Binding var text: String
    let path: String?
    let isEditable: Bool

    var body: some View {
        if isEditable {
            TextEditor(text: $text)
                .font(.system(size: 13.5, weight: .regular, design: .monospaced))
                .foregroundStyle(AppTheme.chromeText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(AppTheme.editorBackground)
        } else {
            ScrollView {
                Text(displayText)
                    .font(.system(size: 13.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(AppTheme.chromeText)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(AppTheme.editorBackground)
        }
    }

    private var displayText: String {
        if text.isEmpty {
            return "No file content loaded.\n\nPath: \(path ?? "(none)")"
        }
        return text
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
        case .small: return 12.0
        case .medium: return 12.5
        case .large: return 13.5
        }
    }

    var rowHeight: CGFloat {
        switch self {
        case .small: return 21
        case .medium: return 22
        case .large: return 24
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
        .frame(height: 28)
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
                        .font(.system(size: 12, weight: .semibold))
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
        .frame(height: 27)
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
                                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                        .foregroundStyle((annotated.hunkIndex == selectedHunkIndex) ? AppTheme.chromeText : AppTheme.accent.opacity(0.95))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 24)
                                .background((annotated.hunkIndex == selectedHunkIndex) ? AppTheme.accent.opacity(0.18) : AppTheme.chromeDarkElevated.opacity(0.55))
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

                                HStack(spacing: 7) {
                                    Text(lineNum.map(String.init) ?? "")
                                        .font(.system(size: fontPreset.lineNumberSize, weight: .regular, design: .monospaced))
                                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                                        .frame(width: 34, alignment: .trailing)

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
                                        .fill((hoveredRowIndex == annotated.id) ? AppTheme.chromeDarkElevated.opacity(0.35) : .clear)
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
                return (side == .new || side == .merged) ? Color.green.opacity(0.15) : Color.clear
            case .removed:
                return (side == .old || side == .merged) ? Color.red.opacity(0.15) : Color.clear
            case .hunk:
                return Color.clear
            }
        }

        private func stripeColor(for row: IDEDiffRow, side: Side) -> Color {
            switch row.kind {
            case .added:
                return (side == .new || side == .merged) ? Color.green.opacity(0.85) : .clear
            case .removed:
                return (side == .old || side == .merged) ? Color.red.opacity(0.85) : .clear
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
            HStack(spacing: 14) {
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
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(AppTheme.chromeDarkElevated)
                .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                Text("New Tab")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppTheme.chromeDarkElevated)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
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
            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
            .foregroundStyle(AppTheme.chromeMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(7)
            .background(AppTheme.chromeDarkElevated)
        }
    }
}

private struct TerminalPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                TextField("Command", text: $viewModel.terminalCommand)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(AppTheme.fieldFill)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

                Button(viewModel.isTerminalRunning ? "Running..." : "Run") {
                    Task { await viewModel.runTerminalCommand() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(viewModel.isTerminalRunning ? AppTheme.chromeMuted : AppTheme.chromeText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.chromeDarkElevated)
                .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
                .disabled(viewModel.isTerminalRunning)
            }

            ScrollView {
                Text(viewModel.terminalOutput)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
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
