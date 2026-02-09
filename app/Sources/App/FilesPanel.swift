import SwiftUI

struct FilesPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var collapsed: Set<String> = []
    @State private var hasInitializedCollapseState: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            listBody
        }
        .background(AppTheme.sidebarDark)
        .onAppear {
            restoreCollapsedState()
            if viewModel.fileTree.isEmpty {
                Task { await viewModel.refreshFiles() }
            } else if !hasInitializedCollapseState {
                applyDefaultCollapseState()
            }
        }
        .onChange(of: viewModel.fileTree) { _ in
            applyDefaultCollapseState()
        }
        .onChange(of: collapsed) { _ in
            persistCollapsedState()
        }
        .onChange(of: viewModel.repoPath) { _ in
            hasInitializedCollapseState = false
            restoreCollapsedState()
        }
    }

    private var listBody: some View {
        ScrollView {
            if filteredRows.isEmpty {
                FilesEmptyState(
                    title: "No files",
                    subtitle: viewModel.filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "No matching files"
                )
                    .padding(.top, 14)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredRows, id: \.node.id) { entry in
                        FileTreeRow(
                            entry: entry,
                            isSelected: entry.node.id == viewModel.selectedFileID
                        ) {
                            if entry.node.isDirectory {
                                toggleCollapse(entry.node.id)
                            } else {
                                Task { await viewModel.selectAndLoadFile(path: entry.node.relativePath, id: entry.node.id) }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var filteredRows: [FileRowEntry] {
        let q = viewModel.filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let nodes = q.isEmpty ? viewModel.fileTree : filteredProjectNodes(viewModel.fileTree, query: q)
        return flattenProjectNodes(nodes, depth: 0, collapsed: collapsed)
    }

    private func flattenProjectNodes(_ nodes: [FileNode], depth: Int, collapsed: Set<String>) -> [FileRowEntry] {
        var out: [FileRowEntry] = []
        for node in nodes {
            out.append(FileRowEntry(node: node, depth: depth, isCollapsed: collapsed.contains(node.id)))
            if node.isDirectory, let children = node.children, !collapsed.contains(node.id) {
                out.append(contentsOf: flattenProjectNodes(children, depth: depth + 1, collapsed: collapsed))
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

    private func toggleCollapse(_ id: String) {
        if collapsed.contains(id) {
            collapsed.remove(id)
        } else {
            collapsed.insert(id)
        }
    }

    private func applyDefaultCollapseState() {
        let saved = savedCollapsedIDs()
        if !saved.isEmpty {
            let validIDs = Set(flattenProjectNodes(viewModel.fileTree, depth: 0, collapsed: []).map(\.node.id))
            collapsed = saved.intersection(validIDs)
            hasInitializedCollapseState = true
            return
        }

        var initial = allDirectoryIDs(in: viewModel.fileTree)

        // Expand ancestors of selected file so current context is visible.
        if let selectedID = viewModel.selectedFileID, !selectedID.isEmpty {
            for ancestor in ancestorDirectoryIDs(for: selectedID) {
                initial.remove(ancestor)
            }
        } else if let selectedPath = viewModel.selectedPath, !selectedPath.isEmpty {
            for ancestor in ancestorDirectoryIDs(for: selectedPath) {
                initial.remove(ancestor)
            }
        } else {
            // With no selection, keep top-level visible for quick scanning.
            for node in viewModel.fileTree where node.isDirectory {
                initial.remove(node.id)
            }
        }

        collapsed = initial
        hasInitializedCollapseState = true
    }

    private func collapseStorageKey() -> String {
        "session.files.collapsed.\(viewModel.repoPath)"
    }

    private func savedCollapsedIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: collapseStorageKey()) ?? [])
    }

    private func restoreCollapsedState() {
        let saved = savedCollapsedIDs()
        guard !saved.isEmpty else { return }
        collapsed = saved
        hasInitializedCollapseState = true
    }

    private func persistCollapsedState() {
        let key = collapseStorageKey()
        if collapsed.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(Array(collapsed), forKey: key)
        }
    }

    private func allDirectoryIDs(in nodes: [FileNode]) -> Set<String> {
        var ids: Set<String> = []
        for node in nodes where node.isDirectory {
            ids.insert(node.id)
            if let children = node.children {
                ids.formUnion(allDirectoryIDs(in: children))
            }
        }
        return ids
    }

    private func ancestorDirectoryIDs(for path: String) -> [String] {
        let parts = path.split(separator: "/").map(String.init)
        guard parts.count > 1 else { return [] }
        var result: [String] = []
        var current = ""
        for segment in parts.dropLast() {
            current = current.isEmpty ? segment : "\(current)/\(segment)"
            result.append(current)
        }
        return result
    }
}

private struct FileRowEntry: Hashable {
    let node: FileNode
    let depth: Int
    let isCollapsed: Bool
}

private struct FileTreeRow: View {
    let entry: FileRowEntry
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: CGFloat(entry.depth) * 10, height: 1)

            Group {
                if entry.node.isDirectory {
                    Image(systemName: entry.isCollapsed ? "chevron.right" : "chevron.down")
                } else {
                    Color.clear
                }
            }
            .frame(width: 10, alignment: .center)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(AppTheme.chromeMuted.opacity(0.46))

            Image(systemName: entry.node.isDirectory ? "folder.fill" : fileSymbol(entry.node.name))
                .font(.system(size: 10.5, weight: entry.node.isDirectory ? .medium : .regular))
                .foregroundStyle(fileColor(entry.node.name, isDirectory: entry.node.isDirectory))
                .frame(width: 12, alignment: .center)
                .padding(.leading, 2)
                .padding(.trailing, 5)

            Text(entry.node.name)
                .font(.system(size: 11.5, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AppTheme.chromeText.opacity(0.96) : AppTheme.chromeText.opacity(0.76))
                .lineLimit(1)

            Spacer(minLength: 0)

        }
        .padding(.horizontal, 7)
        .frame(height: 20)
        .contentShape(Rectangle())
        .background(
            isSelected
                ? Color(red: 0.218, green: 0.221, blue: 0.233).opacity(0.90)
                : (isHovering ? AppTheme.chromeDarkElevated.opacity(0.10) : .clear)
        )
        .onTapGesture(perform: onTap)
        .onHover { inside in
            isHovering = inside
        }
    }

    private func fileSymbol(_ name: String) -> String {
        let lowered = name.lowercased()
        if lowered.hasSuffix(".swift") { return "swift" }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return "curlybraces" }
        if lowered.hasSuffix(".md") { return "text.document" }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return "photo" }
        if lowered == "makefile" { return "hammer" }
        if lowered.hasSuffix(".rs") { return "r.square" }
        return "doc"
    }

    private func fileColor(_ name: String, isDirectory: Bool) -> Color {
        if isDirectory { return Color(red: 0.36, green: 0.57, blue: 0.92).opacity(0.90) }
        let lowered = name.lowercased()
        if lowered.hasSuffix(".swift") { return Color(red: 0.34, green: 0.63, blue: 0.97).opacity(0.84) }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return AppTheme.accentSecondary.opacity(0.58) }
        if lowered.hasSuffix(".md") { return AppTheme.chromeMuted.opacity(0.68) }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return AppTheme.chromeMuted.opacity(0.62) }
        if lowered == "makefile" { return AppTheme.chromeMuted.opacity(0.66) }
        if lowered.hasSuffix(".rs") { return AppTheme.accentSecondary.opacity(0.58) }
        return AppTheme.chromeMuted.opacity(0.58)
    }
}

private struct FilesEmptyState: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText.opacity(0.9))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}
