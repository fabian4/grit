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
            viewModel.leftMode = .files
            if viewModel.fileTree.isEmpty {
                Task { await viewModel.refreshFiles() }
            } else if !hasInitializedCollapseState {
                applyDefaultCollapseState()
            }
        }
        .onChange(of: viewModel.fileTree) { _ in
            applyDefaultCollapseState()
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
                .padding(.vertical, 4)
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
            Color.clear.frame(width: CGFloat(entry.depth) * 13, height: 1)

            Group {
                if entry.node.isDirectory {
                    Image(systemName: entry.isCollapsed ? "chevron.right" : "chevron.down")
                } else {
                    Color.clear
                }
            }
            .frame(width: 12, alignment: .center)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(AppTheme.chromeMuted.opacity(0.58))

            Image(systemName: entry.node.isDirectory ? "folder.fill" : fileSymbol(entry.node.name))
                .font(.system(size: 11, weight: entry.node.isDirectory ? .medium : .regular))
                .foregroundStyle(fileColor(entry.node.name, isDirectory: entry.node.isDirectory))
                .frame(width: 13, alignment: .center)
                .padding(.leading, 2)
                .padding(.trailing, 7)

            Text(entry.node.name)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AppTheme.chromeText.opacity(0.98) : AppTheme.chromeText.opacity(0.75))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .frame(height: 24)
        .contentShape(Rectangle())
        .background(isSelected ? Color(red: 0.235, green: 0.245, blue: 0.278).opacity(0.72) : (isHovering ? AppTheme.chromeDarkElevated.opacity(0.16) : .clear))
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
        if isDirectory { return AppTheme.accentSecondary.opacity(0.72) }
        let lowered = name.lowercased()
        if lowered.hasSuffix(".swift") { return AppTheme.accent.opacity(0.78) }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return AppTheme.accentSecondary.opacity(0.68) }
        if lowered.hasSuffix(".md") { return AppTheme.chromeMuted.opacity(0.74) }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return AppTheme.chromeMuted.opacity(0.70) }
        if lowered == "makefile" { return AppTheme.chromeMuted.opacity(0.72) }
        if lowered.hasSuffix(".rs") { return AppTheme.accentSecondary.opacity(0.64) }
        return AppTheme.chromeMuted.opacity(0.66)
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
