import Foundation

actor WorkspaceClient {
    static let shared = WorkspaceClient()

    private var repoRoot: String?

    func open(path: String) throws {
        let root = try runGit(["rev-parse", "--show-toplevel"], in: path)
        repoRoot = root.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func status() throws -> String {
        let root = try requireRoot()
        return try runGit(["status", "--porcelain=v1"], in: root)
    }

    func statusNumstat() throws -> String {
        let root = try requireRoot()
        return try runGit(["diff", "--numstat"], in: root)
    }

    func diff() throws -> String {
        let root = try requireRoot()
        return try runGit(["diff", "--no-ext-diff"], in: root)
    }

    func diff(path: String) throws -> String {
        let root = try requireRoot()
        return try runGit(["diff", "--no-ext-diff", "--", path], in: root)
    }

    func diffCached(path: String) throws -> String {
        let root = try requireRoot()
        return try runGit(["diff", "--cached", "--no-ext-diff", "--", path], in: root)
    }

    func root() throws -> String {
        try requireRoot()
    }

    func branchName() throws -> String {
        let root = try requireRoot()
        return try runGit(["rev-parse", "--abbrev-ref", "HEAD"], in: root)
    }

    func stage(path: String) throws {
        let root = try requireRoot()
        _ = try runGit(["add", "--", path], in: root)
    }

    func unstage(path: String) throws {
        let root = try requireRoot()
        _ = try runGit(["restore", "--staged", "--", path], in: root)
    }

    func stageAll() throws {
        let root = try requireRoot()
        _ = try runGit(["add", "-A"], in: root)
    }

    func unstageAll() throws {
        let root = try requireRoot()
        _ = try runGit(["restore", "--staged", "."], in: root)
    }

    func discard(path: String) throws {
        let root = try requireRoot()
        _ = try runGit(["restore", "--", path], in: root)
    }

    func clean(path: String) throws {
        let root = try requireRoot()
        _ = try runGit(["clean", "-f", "--", path], in: root)
    }

    func discardAll() throws {
        let root = try requireRoot()
        _ = try runGit(["restore", "."], in: root)
    }

    func commit(title: String, body: String?) throws {
        let root = try requireRoot()
        var args = ["commit", "-m", title]
        if let body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(contentsOf: ["-m", body])
        }
        _ = try runGit(args, in: root)
    }

    private func requireRoot() throws -> String {
        guard let repoRoot, !repoRoot.isEmpty else {
            throw WorkspaceClientError.repoNotOpened
        }
        return repoRoot
    }

    private func runGit(_ args: [String], in directory: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + args
        process.currentDirectoryURL = URL(fileURLWithPath: directory)

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let merged = (stdout + stderr).trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            throw WorkspaceClientError.gitFailed(message: merged.isEmpty ? "git command failed" : merged)
        }
        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum WorkspaceClientError: LocalizedError {
    case repoNotOpened
    case gitFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .repoNotOpened:
            return "Repo not opened"
        case .gitFailed(let message):
            return message
        }
    }
}
