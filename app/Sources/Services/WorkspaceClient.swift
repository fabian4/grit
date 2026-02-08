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

    func diff() throws -> String {
        let root = try requireRoot()
        return try runGit(["diff", "--no-ext-diff"], in: root)
    }

    func diff(path: String) throws -> String {
        let root = try requireRoot()
        return try runGit(["diff", "--no-ext-diff", "--", path], in: root)
    }

    func root() throws -> String {
        try requireRoot()
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
