import Foundation

struct StatusItem: Identifiable, Hashable {
    let id: String
    let status: String
    let path: String

    var display: String {
        if status == "??" {
            return "(·) \(path)"
        }
        return path
    }
}

struct StatusSection: Identifiable, Hashable {
    let id: String
    let title: String
    let items: [StatusItem]
}

struct StatusNode: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let children: [StatusNode]?
    let isLeaf: Bool
}

struct FileNode: Identifiable, Hashable {
    let id: String
    let name: String
    let relativePath: String
    let absolutePath: String
    let isDirectory: Bool
    let children: [FileNode]?
}

struct DiffHunk: Identifiable, Hashable {
    let id: String
    let header: String
    let body: String
}

enum LeftPanelMode: String, Hashable, CaseIterable, Identifiable {
    case changes
    case files

    var id: String { rawValue }

    var title: String {
        switch self {
        case .changes: return "Changes"
        case .files: return "Files"
        }
    }
}

final class RepoViewModel: ObservableObject {
    static let shared = RepoViewModel()
    @Published var repoPath: String
    @Published var output: String = ""
    @Published var isRepoOpen: Bool = false
    @Published var statusItems: [StatusItem] = []
    @Published var fileTree: [FileNode] = []
    @Published var selectedFileID: String? = nil
    @Published var fileContent: String = ""
    @Published var selectedPath: String? = nil
    @Published var detailOutput: String = ""
    @Published var hunks: [DiffHunk] = []
    @Published var selectedHunkID: String? = nil
    @Published var diffLines: [DiffLine] = []
    @Published var leftMode: LeftPanelMode = .changes
    @Published var diffMode: DiffViewMode = AppConfig.shared.diffView
    @Published var groupDiffByFolder: Bool = false
    @Published var isDetailEditable: Bool = false

    private let client = WorkspaceClient.shared
    private var fileIndex: [String: FileNode] = [:]
    private var treeOrder: [String] = []

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.repoPath = (home as NSString).appendingPathComponent("Projects/grit")
    }

    @MainActor
    func openRepo() async {
        let path = repoPath
        do {
            try await WorkspaceClient.shared.open(path: path)
            let root = try await WorkspaceClient.shared.root()
            repoPath = root
            output = "Opened: \(root)"
            isRepoOpen = true
            await refreshStatus()
            await refreshFiles()
        } catch {
            output = String(describing: error)
            isRepoOpen = false
        }
    }

    @MainActor
    func runStatus() async {
        await refreshStatus()
    }

    @MainActor
    func refreshStatus() async {
        do {
            let result = try await WorkspaceClient.shared.status()
            output = result
            statusItems = parseStatus(result)
            if selectedPath == nil {
                selectedPath = statusItems.first?.path
            }
            await loadDiffForSelection()
        } catch {
            output = String(describing: error)
        }
    }

    @MainActor
    func refreshFiles() async {
        do {
            let fm = FileManager.default
            let rootURL = URL(fileURLWithPath: repoPath)
            let rootNode = try buildTree(url: rootURL, rootURL: rootURL, fm: fm)
            fileTree = rootNode.children ?? []
            fileIndex = buildIndex(from: fileTree)
            treeOrder = flattenTree(fileTree)
        } catch {
            fileTree = []
            fileIndex = [:]
            treeOrder = []
        }
    }

    @MainActor
    func runDiff() async {
        do {
            let result = try await WorkspaceClient.shared.diff()
            detailOutput = result
            diffLines = parseDiffLines(result)
        } catch {
            output = String(describing: error)
        }
    }

    @MainActor
    func loadDiffForSelection() async {
        guard let path = selectedPath, !path.isEmpty else {
            detailOutput = ""
            hunks = []
            selectedHunkID = nil
            diffLines = []
            return
        }
        do {
            let result = try await WorkspaceClient.shared.diff(path: path)
            detailOutput = result
            hunks = []
            selectedHunkID = nil
            diffLines = parseDiffLines(result)
            if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let node = fileIndex[path], !node.isDirectory {
                    if let content = try? String(contentsOfFile: node.absolutePath, encoding: .utf8) {
                        detailOutput = content
                        diffLines = parsePlainLines(content, withLineNumbers: true)
                    }
                }
            }
        } catch {
            detailOutput = ""
            hunks = []
            selectedHunkID = nil
            diffLines = []
            output = String(describing: error)
        }
    }

    @MainActor
    func loadFileForSelection() async {
        guard let id = selectedFileID, let node = fileIndex[id], !node.isDirectory else {
            fileContent = ""
            diffLines = []
            return
        }
        do {
            fileContent = try String(contentsOfFile: node.absolutePath, encoding: .utf8)
            diffLines = parsePlainLines(fileContent, withLineNumbers: true)
        } catch {
            fileContent = "Unable to load file: \(node.relativePath)"
            diffLines = []
        }
    }

    private func parseStatus(_ raw: String) -> [StatusItem] {
        raw.split(separator: "\n").compactMap { line in
            if line.count < 3 { return nil }
            let status = String(line.prefix(2))
            var pathPart = String(line.dropFirst(3))
            if let arrowRange = pathPart.range(of: " -> ") {
                pathPart = String(pathPart[arrowRange.upperBound...])
            }
            let id = "\(status):\(pathPart)"
            return StatusItem(id: id, status: status, path: pathPart)
        }
    }

    private func parseHunks(_ raw: String) -> [DiffHunk] {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var hunks: [DiffHunk] = []
        var currentHeader: String? = nil
        var currentLines: [String] = []

        func flush() {
            guard let header = currentHeader else { return }
            let body = currentLines.joined(separator: "\n")
            let id = "\(header):\(hunks.count)"
            hunks.append(DiffHunk(id: id, header: header, body: body))
            currentHeader = nil
            currentLines = []
        }

        for line in lines {
            if line.hasPrefix("@@") {
                flush()
                currentHeader = line
                currentLines = [line]
            } else if currentHeader != nil {
                currentLines.append(line)
            }
        }
        flush()
        return hunks
    }

    private func parseDiffLines(_ raw: String) -> [DiffLine] {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var result: [DiffLine] = []
        var oldLine: Int? = nil
        var newLine: Int? = nil
        var counter = 0

        func addLine(kind: DiffLine.Kind, text: String, old: Int?, new: Int?) {
            let id = "\(counter)-\(kind)"
            counter += 1
            result.append(DiffLine(id: id, kind: kind, oldLine: old, newLine: new, text: text))
        }

        for line in lines {
            if line.hasPrefix("diff --git") || line.hasPrefix("index ") || line.hasPrefix("+++") || line.hasPrefix("---") {
                continue
            }
            if line.hasPrefix("@@") {
                let numbers = parseHunkHeader(line)
                oldLine = numbers.old
                newLine = numbers.new
                addLine(kind: .hunk, text: line, old: nil, new: nil)
                continue
            }
            if line.hasPrefix("+") {
                addLine(kind: .added, text: line, old: nil, new: newLine)
                newLine = newLine.map { $0 + 1 }
                continue
            }
            if line.hasPrefix("-") {
                addLine(kind: .removed, text: line, old: oldLine, new: nil)
                oldLine = oldLine.map { $0 + 1 }
                continue
            }
            addLine(kind: .context, text: line, old: oldLine, new: newLine)
            oldLine = oldLine.map { $0 + 1 }
            newLine = newLine.map { $0 + 1 }
        }

        return result
    }

    private func parsePlainLines(_ raw: String, withLineNumbers: Bool) -> [DiffLine] {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var result: [DiffLine] = []
        var counter = 0
        var lineNumber = 1
        for line in lines {
            let id = "\(counter)-plain"
            counter += 1
            let old = withLineNumbers ? lineNumber : nil
            let new = withLineNumbers ? lineNumber : nil
            result.append(DiffLine(id: id, kind: .context, oldLine: old, newLine: new, text: line))
            lineNumber += 1
        }
        return result
    }

    private func parseHunkHeader(_ line: String) -> (old: Int?, new: Int?) {
        // Example: @@ -1,7 +1,6 @@
        guard let minusRange = line.range(of: "-"),
              let plusRange = line.range(of: "+") else {
            return (nil, nil)
        }
        let afterMinus = line[minusRange.upperBound...]
        let afterPlus = line[plusRange.upperBound...]
        let oldPart = afterMinus.split(separator: " ").first ?? ""
        let newPart = afterPlus.split(separator: " ").first ?? ""
        let oldLine = Int(oldPart.split(separator: ",").first ?? "")
        let newLine = Int(newPart.split(separator: ",").first ?? "")
        return (oldLine, newLine)
    }

    private func buildTree(url: URL, rootURL: URL, fm: FileManager) throws -> FileNode {
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let relative = url.path.replacingOccurrences(of: rootURL.path + "/", with: "")
        let name = url.lastPathComponent
        let id = relative.isEmpty ? "/" : relative
        if isDir {
            let childrenUrls = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: []
            )
            var children: [FileNode] = []
            for child in childrenUrls {
                if child.lastPathComponent == ".git" { continue }
                if let node = try? buildTree(url: child, rootURL: rootURL, fm: fm) {
                    children.append(node)
                }
            }
            children.sort {
                if $0.isDirectory != $1.isDirectory {
                    return $0.isDirectory && !$1.isDirectory
                }
                return $0.name.lowercased() < $1.name.lowercased()
            }
            return FileNode(
                id: id,
                name: name,
                relativePath: relative,
                absolutePath: url.path,
                isDirectory: true,
                children: children
            )
        } else {
            return FileNode(
                id: id,
                name: name,
                relativePath: relative,
                absolutePath: url.path,
                isDirectory: false,
                children: nil
            )
        }
    }

    private func buildIndex(from nodes: [FileNode]) -> [String: FileNode] {
        var map: [String: FileNode] = [:]
        for node in nodes {
            map[node.id] = node
            if let children = node.children {
                for (k, v) in buildIndex(from: children) {
                    map[k] = v
                }
            }
        }
        return map
    }

    private func flattenTree(_ nodes: [FileNode]) -> [String] {
        var result: [String] = []
        for node in nodes {
            if !node.isDirectory {
                result.append(node.relativePath)
            }
            if let children = node.children {
                result.append(contentsOf: flattenTree(children))
            }
        }
        return result
    }

    var sortedStatusItems: [StatusItem] {
        if groupDiffByFolder {
            return statusItems.sorted { lhs, rhs in
                let lhsParts = lhs.path.split(separator: "/")
                let rhsParts = rhs.path.split(separator: "/")
                let lhsInFolder = lhsParts.count > 1
                let rhsInFolder = rhsParts.count > 1
                if lhsInFolder != rhsInFolder {
                    return lhsInFolder && !rhsInFolder
                }
                let lhsTop = lhsParts.first.map(String.init) ?? lhs.path
                let rhsTop = rhsParts.first.map(String.init) ?? rhs.path
                if lhsTop != rhsTop {
                    return lhsTop.lowercased() < rhsTop.lowercased()
                }
                return lhs.path.lowercased() < rhs.path.lowercased()
            }
        }
        return statusItems.sorted { $0.path.lowercased() < $1.path.lowercased() }
    }

    var groupedStatusSections: [StatusSection] {
        var rootItems: [StatusItem] = []
        var groups: [String: [StatusItem]] = [:]

        for item in statusItems {
            let parts = item.path.split(separator: "/")
            if parts.count <= 1 {
                rootItems.append(item)
            } else {
                let key = String(parts.first ?? "")
                groups[key, default: []].append(item)
            }
        }

        rootItems.sort { $0.path.lowercased() < $1.path.lowercased() }
        let groupSections = groups.keys.sorted { $0.lowercased() < $1.lowercased() }.map { key in
            let items = (groups[key] ?? []).sorted { $0.path.lowercased() < $1.path.lowercased() }
            return StatusSection(id: key, title: key, items: items)
        }

        var sections: [StatusSection] = []
        if !rootItems.isEmpty {
            sections.append(StatusSection(id: "__root__", title: "Root", items: rootItems))
        }
        sections.append(contentsOf: groupSections)
        return sections
    }

    var statusTree: [StatusNode] {
        buildStatusTree()
    }

    var isSelectedLeaf: Bool {
        guard let path = selectedPath else { return false }
        return statusItems.contains { $0.path == path }
    }

    private func buildStatusTree() -> [StatusNode] {
        var root: [String: [StatusItem]] = [:]
        var filesAtRoot: [StatusItem] = []

        for item in statusItems {
            let parts = item.path.split(separator: "/").map(String.init)
            if parts.count <= 1 {
                filesAtRoot.append(item)
            } else {
                let key = parts.first ?? ""
                root[key, default: []].append(item)
            }
        }

        var nodes: [StatusNode] = []
        let folderKeys = root.keys.sorted { $0.lowercased() < $1.lowercased() }
        for folder in folderKeys {
            let items = root[folder] ?? []
            let children = buildStatusTreeFromItems(items, prefix: folder)
            nodes.append(StatusNode(id: folder, name: folder, path: folder, children: children, isLeaf: false))
        }

        let rootFiles = filesAtRoot.sorted { $0.path.lowercased() < $1.path.lowercased() }
        for file in rootFiles {
            nodes.append(StatusNode(id: file.path, name: file.display, path: file.path, children: nil, isLeaf: true))
        }

        return nodes
    }

    private func buildStatusTreeFromItems(_ items: [StatusItem], prefix: String) -> [StatusNode] {
        var grouped: [String: [StatusItem]] = [:]
        var files: [StatusItem] = []

        for item in items {
            var rel = item.path
            if rel.hasPrefix(prefix + "/") {
                rel = String(rel.dropFirst(prefix.count + 1))
            }
            let parts = rel.split(separator: "/").map(String.init)
            if parts.count <= 1 {
                files.append(item)
            } else {
                let key = parts.first ?? ""
                grouped[key, default: []].append(item)
            }
        }

        var nodes: [StatusNode] = []
        let folderKeys = grouped.keys.sorted { $0.lowercased() < $1.lowercased() }
        for folder in folderKeys {
            let childItems = grouped[folder] ?? []
            let newPrefix = prefix + "/" + folder
            let children = buildStatusTreeFromItems(childItems, prefix: newPrefix)
            nodes.append(StatusNode(id: newPrefix, name: folder, path: newPrefix, children: children, isLeaf: false))
        }

        let fileNodes = files.sorted { $0.path.lowercased() < $1.path.lowercased() }.map {
            let base = $0.path.split(separator: "/").last.map(String.init) ?? $0.path
            let name = $0.status == "??" ? "(·) \(base)" : base
            return StatusNode(id: $0.path, name: name, path: $0.path, children: nil, isLeaf: true)
        }
        nodes.append(contentsOf: fileNodes)

        return nodes
    }
}
