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
            if viewModel.fileTree.isEmpty {
                Task { await viewModel.refreshFiles() }
            }
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
    @GestureState private var isPressing: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: CGFloat(entry.depth) * 12, height: 1)

            Group {
                if entry.node.isDirectory {
                    Image(systemName: entry.isCollapsed ? "chevron.right" : "chevron.down")
                } else {
                    Color.clear
                }
            }
            .frame(width: 11, alignment: .center)
            .font(.system(size: 8.5, weight: .bold))
            .foregroundStyle(AppTheme.chromeMuted.opacity(0.60))

            Image(systemName: entry.node.isDirectory ? "folder.fill" : fileSymbol(entry.node.name))
                .font(.system(size: 10.0, weight: entry.node.isDirectory ? .medium : .regular))
                .foregroundStyle(fileColor(entry.node.name, isDirectory: entry.node.isDirectory))
                .frame(width: 12, alignment: .center)
                .padding(.leading, 3)
                .padding(.trailing, 6)

            Text(entry.node.name)
                .font(.system(size: 10.6, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? AppTheme.chromeText.opacity(0.92) : AppTheme.chromeText.opacity(0.68))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .contentShape(Rectangle())
        .background(
            isSelected
                ? Color(red: 0.205, green: 0.218, blue: 0.246).opacity(0.78)
                : (isPressing ? AppTheme.chromeDarkElevated.opacity(0.38) : (isHovering ? AppTheme.chromeDarkElevated.opacity(0.18) : .clear))
        )
        .clipShape(RoundedRectangle(cornerRadius: 2.5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .stroke(
                    isSelected ? AppTheme.chromeDivider.opacity(0.36) : (isHovering ? AppTheme.chromeDivider.opacity(0.24) : .clear),
                    lineWidth: 1
                )
        }
        .onTapGesture(perform: onTap)
        .onHover { inside in
            isHovering = inside
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressing) { _, state, _ in
                    state = true
                }
        )
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
        if isDirectory { return AppTheme.accentSecondary.opacity(0.66) }
        let lowered = name.lowercased()
        if lowered.hasSuffix(".swift") { return AppTheme.accent.opacity(0.72) }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return AppTheme.accentSecondary.opacity(0.64) }
        if lowered.hasSuffix(".md") { return AppTheme.chromeMuted.opacity(0.70) }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return AppTheme.chromeMuted.opacity(0.66) }
        if lowered == "makefile" { return AppTheme.chromeMuted.opacity(0.68) }
        if lowered.hasSuffix(".rs") { return AppTheme.accentSecondary.opacity(0.60) }
        return AppTheme.chromeMuted.opacity(0.62)
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
