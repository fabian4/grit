import Foundation

actor WorkspaceClient {
    static let shared = WorkspaceClient()

    private var repo: RepoService?

    func open(path: String) throws {
        repo = try RepoService(path: path)
    }

    func status() throws -> String {
        guard let repo else {
            throw AppError.Message(message: "Repo not opened")
        }
        return try repo.status()
    }

    func diff() throws -> String {
        guard let repo else {
            throw AppError.Message(message: "Repo not opened")
        }
        return try repo.diff()
    }

    func diff(path: String) throws -> String {
        guard let repo else {
            throw AppError.Message(message: "Repo not opened")
        }
        return try repo.diffPath(path: path)
    }

    func root() throws -> String {
        guard let repo else {
            throw AppError.Message(message: "Repo not opened")
        }
        return repo.root()
    }
}
