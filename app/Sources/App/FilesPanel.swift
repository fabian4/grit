import SwiftUI

struct FilesPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var collapsed: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            listBody
        }
        .background(AppTheme.sidebarDark)
        .onAppear {
            viewModel.leftMode = .files
            if viewModel.isRepoOpen, viewModel.fileTree.isEmpty {
                Task { await viewModel.refreshFiles() }
            }
        }
    }

    private var listBody: some View {
        ScrollView {
            if !viewModel.isRepoOpen {
                FilesEmptyState(title: "No repo open", subtitle: "Use Open in the top bar")
                    .padding(.top, 18)
            } else if filteredRows.isEmpty {
                FilesEmptyState(
                    title: "No files",
                    subtitle: viewModel.filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "No matching files"
                )
                    .padding(.top, 18)
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

    var body: some View {
        HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(entry.depth) * 8, height: 1)

            if entry.node.isDirectory {
                Image(systemName: entry.isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                Image(systemName: "folder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.accentSecondary.opacity(0.95))
            } else {
                Image(systemName: fileSymbol(entry.node.name))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(fileColor(entry.node.name))
            }

            Text(entry.node.name)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(isSelected ? AppTheme.chromeText : AppTheme.chromeMuted)
                .lineLimit(1)

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
}

private struct FilesEmptyState: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText.opacity(0.9))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}
