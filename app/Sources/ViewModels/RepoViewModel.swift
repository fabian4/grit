import Foundation

struct StatusItem: Identifiable, Hashable {
    let id: String
    let status: String
    let path: String
    let additions: Int
    let deletions: Int

    var stagedCode: Character {
        Array(status).first ?? " "
    }

    var unstagedCode: Character {
        if status.count < 2 { return " " }
        return Array(status)[1]
    }

    var isStaged: Bool {
        stagedCode != " " && stagedCode != "?"
    }

    var isUnstaged: Bool {
        status == "??" || unstagedCode != " "
    }

    var isUntracked: Bool {
        status == "??"
    }

    var isConflicted: Bool {
        status.contains("U")
    }

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
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .changes: return "Changes"
        case .files: return "Files"
        case .history: return "History"
        }
    }
}

enum DiffScope: String, Hashable, CaseIterable, Identifiable {
    case unstaged
    case staged

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unstaged: return "Unstaged"
        case .staged: return "Staged"
        }
    }
}

final class RepoViewModel: ObservableObject {
    static let shared = RepoViewModel()
    @Published var repoPath: String
    @Published var output: String = ""
    @Published var lastErrorMessage: String? = nil
    @Published var isRepoOpen: Bool = false
    @Published var isBusy: Bool = false
    @Published var statusItems: [StatusItem] = []
    @Published var fileTree: [FileNode] = []
    @Published var selectedFileID: String? = nil
    @Published var fileContent: String = ""
    @Published var selectedPath: String? = nil
    @Published var selectedDiffScope: DiffScope = .unstaged
    @Published var openTabs: [String] = []
    @Published var pinnedTabs: Set<String> = []
    @Published var detailOutput: String = ""
    @Published var hunks: [DiffHunk] = []
    @Published var selectedHunkID: String? = nil
    @Published var diffLines: [DiffLine] = []
    @Published var leftMode: LeftPanelMode = .changes
    @Published var diffMode: DiffViewMode = AppConfig.shared.diffView
    @Published var groupDiffByFolder: Bool = false
    @Published var isDetailEditable: Bool = false
    @Published var terminalOutput: String = "Grit terminal ready.\n"
    @Published var terminalCommand: String = "pwd"
    @Published var isTerminalRunning: Bool = false
    @Published var currentBranch: String = "-"
    @Published var commitMessage: String = ""
    @Published var filterQuery: String = ""

    private let client = WorkspaceClient.shared
    private var fileIndex: [String: FileNode] = [:]
    private var treeOrder: [String] = []

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.repoPath = (home as NSString).appendingPathComponent("Projects/grit")
        Task { @MainActor in
            guard !self.isRepoOpen else { return }
            await self.openRepo(path: self.repoPath)
        }
    }

    @MainActor
    private func clearError() {
        lastErrorMessage = nil
    }

    @MainActor
    private func reportError(_ error: Error) {
        let message: String
        if let nserr = error as NSError?, let desc = nserr.userInfo[NSLocalizedDescriptionKey] as? String, !desc.isEmpty {
            message = desc
        } else {
            message = String(describing: error)
        }
        lastErrorMessage = message
    }

    @MainActor
    private func beginBusy() {
        isBusy = true
    }

    @MainActor
    private func endBusy() {
        isBusy = false
    }

    @MainActor
    func openRepo() async {
        await openRepo(path: repoPath)
    }

    @MainActor
    func openRepo(path: String) async {
        beginBusy()
        defer { endBusy() }
        do {
            try await WorkspaceClient.shared.open(path: path)
            let root = try await WorkspaceClient.shared.root()
            repoPath = root
            output = "Opened: \(root)"
            isRepoOpen = true
            clearError()
            await refreshStatus()
            await refreshFiles()
        } catch {
            output = String(describing: error)
            reportError(error)
            isRepoOpen = false
        }
    }

    @MainActor
    func runStatus() async {
        await refreshStatus()
    }

    @MainActor
    func refresh() async {
        beginBusy()
        defer { endBusy() }
        await refreshStatus()
        await refreshFiles()
    }

    @MainActor
    func refreshStatus() async {
        do {
            let result = try await WorkspaceClient.shared.status()
            let numstat = try await WorkspaceClient.shared.statusNumstat()
            output = result
            statusItems = parseStatus(result, numstat: numstat)
            currentBranch = (try? await WorkspaceClient.shared.branchName()) ?? "-"
            if statusItems.isEmpty {
                selectedPath = nil
                selectedFileID = nil
                detailOutput = ""
                fileContent = ""
                hunks = []
                selectedHunkID = nil
                diffLines = []
            } else if selectedPath == nil {
                selectedPath = statusItems.first?.path
            }
            if let path = selectedPath {
                activateTab(path)
            }
            await loadDiffForSelection()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
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
            clearError()
        } catch {
            fileTree = []
            fileIndex = [:]
            treeOrder = []
            reportError(error)
        }
    }

    @MainActor
    func runDiff() async {
        beginBusy()
        defer { endBusy() }
        do {
            let result = try await WorkspaceClient.shared.diff()
            detailOutput = result
            diffLines = parseDiffLines(result)
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
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
            let item = statusItems.first(where: { $0.path == path })
            let scope = selectedDiffScope
            let result: String
            switch scope {
            case .staged:
                if item?.isUntracked == true {
                    result = ""
                } else {
                    result = try await WorkspaceClient.shared.diffCached(path: path)
                }
            case .unstaged:
                result = try await WorkspaceClient.shared.diff(path: path)
            }
            detailOutput = result
            hunks = []
            selectedHunkID = nil
            diffLines = parseDiffLines(result)
            if diffLines.isEmpty, let item, item.isUntracked, scope == .unstaged {
                synthesizeUntrackedDiff(relativePath: path)
            }
            clearError()
        } catch {
            detailOutput = ""
            hunks = []
            selectedHunkID = nil
            diffLines = []
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    private func synthesizeUntrackedDiff(relativePath: String) {
        guard let node = fileIndex[relativePath], !node.isDirectory else { return }
        guard let content = try? String(contentsOfFile: node.absolutePath, encoding: .utf8) else { return }

        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var out: [DiffLine] = []
        var counter = 0

        func addLine(kind: DiffLine.Kind, old: Int?, new: Int?, text: String) {
            let id = "\(counter)-synth"
            counter += 1
            out.append(DiffLine(id: id, kind: kind, oldLine: old, newLine: new, text: text))
        }

        addLine(kind: .hunk, old: nil, new: nil, text: "@@ -0,0 +1,\(max(lines.count, 1)) @@")
        var newLine = 1
        for line in lines {
            addLine(kind: .added, old: nil, new: newLine, text: "+\(line)")
            newLine += 1
        }

        detailOutput = content
        diffLines = out
    }

    @MainActor
    func loadFileForSelection() async {
        let resolvedNode: FileNode? = {
            if let id = selectedFileID, let byID = fileIndex[id], !byID.isDirectory {
                return byID
            }
            if let path = selectedPath, let byPath = fileIndex[path], !byPath.isDirectory {
                return byPath
            }
            return nil
        }()

        guard let node = resolvedNode else {
            fileContent = ""
            diffLines = []
            return
        }
        // Keep both selectors in sync so panel switches do not lose context.
        selectedFileID = node.id
        selectedPath = node.relativePath
        activateTab(node.relativePath)
        do {
            fileContent = try String(contentsOfFile: node.absolutePath, encoding: .utf8)
            diffLines = parsePlainLines(fileContent, withLineNumbers: true)
            clearError()
        } catch {
            fileContent = "Unable to load file: \(node.relativePath)"
            diffLines = []
            reportError(error)
        }
    }

    @MainActor
    func selectAndLoadFile(path: String, id: String? = nil) async {
        let key = id ?? path
        let resolvedNode: FileNode? = {
            if let byKey = fileIndex[key], !byKey.isDirectory {
                return byKey
            }
            if let byPath = fileIndex[path], !byPath.isDirectory {
                return byPath
            }
            return nil
        }()

        guard let node = resolvedNode else {
            selectedFileID = id
            selectedPath = path
            fileContent = ""
            diffLines = []
            return
        }

        leftMode = .files
        selectedFileID = node.id
        selectedPath = node.relativePath
        activateTab(node.relativePath)

        do {
            fileContent = try String(contentsOfFile: node.absolutePath, encoding: .utf8)
            diffLines = parsePlainLines(fileContent, withLineNumbers: true)
            clearError()
        } catch {
            fileContent = "Unable to load file: \(node.relativePath)"
            diffLines = []
            reportError(error)
        }
    }

    @MainActor
    func activateTab(_ path: String) {
        guard !path.isEmpty else { return }
        if let index = openTabs.firstIndex(of: path) {
            openTabs.remove(at: index)
        }
        openTabs.append(path)
        if openTabs.count > 8 {
            openTabs.removeFirst(openTabs.count - 8)
        }
    }

    @MainActor
    func closeTab(_ path: String) {
        openTabs.removeAll { $0 == path }
        pinnedTabs.remove(path)
        guard selectedPath == path else { return }
        selectedPath = openTabs.last
        if let next = selectedPath {
            selectedFileID = fileIndex[next]?.id
        } else {
            selectedFileID = nil
        }
    }

    @MainActor
    func togglePinTab(_ path: String) {
        if pinnedTabs.contains(path) {
            pinnedTabs.remove(path)
        } else {
            pinnedTabs.insert(path)
        }
    }

    var displayedTabs: [String] {
        let recency = Array(openTabs.reversed())
        let pinned = recency.filter { pinnedTabs.contains($0) }
        let normal = recency.filter { !pinnedTabs.contains($0) }
        return pinned + normal
    }

    @MainActor
    func runTerminalCommand() async {
        let command = terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        guard !isTerminalRunning else { return }

        isTerminalRunning = true
        terminalOutput += "$ \(command)\n"
        do {
            let output = try await executeShellCommand(command, in: repoPath)
            terminalOutput += output.isEmpty ? "\n" : "\(output)\n"
        } catch {
            terminalOutput += "Error: \(error)\n"
        }
        isTerminalRunning = false
    }

    private func executeShellCommand(_ command: String, in directory: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", command]
            process.currentDirectoryURL = URL(fileURLWithPath: directory)

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { proc in
                let stdoutData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(decoding: stdoutData, as: UTF8.self)
                let stderr = String(decoding: stderrData, as: UTF8.self)
                let merged = stdout + stderr
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: merged.trimmingCharacters(in: .newlines))
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "TerminalError",
                        code: Int(proc.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: merged.trimmingCharacters(in: .newlines)]
                    ))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func parseStatus(_ raw: String, numstat: String) -> [StatusItem] {
        let stats = parseNumstat(numstat)
        return raw.split(separator: "\n").compactMap { line -> StatusItem? in
            if line.count < 3 { return nil }
            let status = String(line.prefix(2))
            var pathPart = String(line.dropFirst(3))
            if let arrowRange = pathPart.range(of: " -> ") {
                pathPart = String(pathPart[arrowRange.upperBound...])
            }
            let id = "\(status):\(pathPart)"
            let pair: (Int, Int) = stats[pathPart] ?? (0, 0)
            return StatusItem(
                id: id,
                status: status,
                path: pathPart,
                additions: pair.0,
                deletions: pair.1
            )
        }
    }

    private func parseNumstat(_ raw: String) -> [String: (Int, Int)] {
        var map: [String: (Int, Int)] = [:]
        for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
            if parts.count < 3 { continue }
            let adds = Int(parts[0]) ?? 0
            let dels = Int(parts[1]) ?? 0
            let path = String(parts[2])
            map[path] = (adds, dels)
        }
        return map
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
                let childIsDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if shouldIgnoreNode(
                    name: child.lastPathComponent,
                    relativePath: child.path.replacingOccurrences(of: rootURL.path + "/", with: ""),
                    isDirectory: childIsDirectory
                ) {
                    continue
                }
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

    private func shouldIgnoreNode(name: String, relativePath: String, isDirectory: Bool) -> Bool {
        if name == ".git" || name == ".DS_Store" { return true }

        let ignoredDirectories: Set<String> = [
            ".build",
            ".idea",
            ".swiftpm",
            ".vscode",
            "DerivedData",
            "node_modules",
            "Pods"
        ]
        if isDirectory && ignoredDirectories.contains(name) {
            return true
        }

        // Keep repo-level dotfiles and .github, but hide tooling/system hidden folders.
        if isDirectory && name.hasPrefix(".") && name != ".github" {
            let depth = relativePath.split(separator: "/").count
            if depth > 1 || name == ".idea" {
                return true
            }
        }

        return false
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

    var stagedCount: Int {
        statusItems.filter(\.isStaged).count
    }

    var stagedItems: [StatusItem] {
        statusItems.filter(\.isStaged)
    }

    var unstagedItems: [StatusItem] {
        statusItems.filter(\.isUnstaged)
    }

    var filteredStatusItems: [StatusItem] {
        let q = filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return sortedStatusItems }
        return sortedStatusItems.filter { $0.path.lowercased().contains(q) }
    }

    var unstagedCount: Int {
        statusItems.filter(\.isUnstaged).count
    }

    var untrackedCount: Int {
        statusItems.filter(\.isUntracked).count
    }

    var conflictedCount: Int {
        statusItems.filter(\.isConflicted).count
    }

    var totalAdditions: Int {
        statusItems.reduce(0) { $0 + $1.additions }
    }

    var totalDeletions: Int {
        statusItems.reduce(0) { $0 + $1.deletions }
    }

    @MainActor
    func toggleStage(item: StatusItem) async {
        beginBusy()
        defer { endBusy() }
        do {
            if item.isStaged {
                try await WorkspaceClient.shared.unstage(path: item.path)
            } else {
                try await WorkspaceClient.shared.stage(path: item.path)
            }
            await refreshStatus()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    func stageAll() async {
        beginBusy()
        defer { endBusy() }
        do {
            try await WorkspaceClient.shared.stageAll()
            await refreshStatus()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    func unstageAll() async {
        beginBusy()
        defer { endBusy() }
        do {
            try await WorkspaceClient.shared.unstageAll()
            await refreshStatus()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    func discard(path: String) async {
        beginBusy()
        defer { endBusy() }
        do {
            _ = try? await saveDiscardBackupIfNeeded(relativePath: path)
            try await WorkspaceClient.shared.discard(path: path)
            await refreshStatus()
            await refreshFiles()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    func discard(item: StatusItem) async {
        beginBusy()
        defer { endBusy() }
        do {
            if item.isUntracked {
                // Safer than `git clean`: send to Trash when possible.
                let absolute = URL(fileURLWithPath: repoPath).appendingPathComponent(item.path)
                do {
                    _ = try FileManager.default.trashItem(at: absolute, resultingItemURL: nil)
                } catch {
                    try await WorkspaceClient.shared.clean(path: item.path)
                }
            } else {
                _ = try? await saveDiscardBackupIfNeeded(relativePath: item.path)
                try await WorkspaceClient.shared.discard(path: item.path)
            }
            await refreshStatus()
            await refreshFiles()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    func discardAll() async {
        beginBusy()
        defer { endBusy() }
        do {
            try await WorkspaceClient.shared.discardAll()
            await refreshStatus()
            await refreshFiles()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    @MainActor
    func commit(title: String, body: String) async {
        beginBusy()
        defer { endBusy() }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        do {
            let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
            try await WorkspaceClient.shared.commit(
                title: trimmedTitle,
                body: trimmedBody.isEmpty ? nil : trimmedBody
            )
            await refreshStatus()
            await refreshFiles()
            clearError()
        } catch {
            output = String(describing: error)
            reportError(error)
        }
    }

    var commitTitle: String {
        commitMessage
            .split(separator: "\n", omittingEmptySubsequences: false)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var commitBody: String {
        let lines = commitMessage.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count > 1 else { return "" }
        return lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canCommit: Bool {
        isRepoOpen && !isBusy && stagedCount > 0 && !commitTitle.isEmpty
    }

    @MainActor
    func commitFromMessage() async {
        guard canCommit else { return }
        await commit(title: commitTitle, body: commitBody)
        if lastErrorMessage == nil {
            commitMessage = ""
        }
    }

    @MainActor
    private func saveDiscardBackupIfNeeded(relativePath: String) async throws -> String? {
        let patch = try await WorkspaceClient.shared.diff(path: relativePath)
        let trimmed = patch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let stamp = ISO8601DateFormatter().string(from: Date())
        let safePath = relativePath.replacingOccurrences(of: "/", with: "__")
        let fileName = "grit-discard-\(stamp)-\(safePath).patch"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try trimmed.write(to: url, atomically: true, encoding: .utf8)
        return url.path
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
