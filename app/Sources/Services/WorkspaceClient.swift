import Foundation

actor WorkspaceClient {
    static let shared = WorkspaceClient()

    private var repo: RepoService?

    func open(path: String) throws {
        repo = try RepoService.open(path: path)
    }

    func status() throws -> String {
        guard let repo else {
            throw AppError(message: "Repo not opened")
        }
        return try repo.status()
    }

    func diff() throws -> String {
        guard let repo else {
            throw AppError(message: "Repo not opened")
        }
        return try repo.diff()
    }
}
