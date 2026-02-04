import Foundation

@MainActor
final class RepoViewModel: ObservableObject {
    @Published var repoPath: String
    @Published var output: String = ""
    @Published var isRepoOpen: Bool = false

    private let client = WorkspaceClient.shared

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.repoPath = home.hasSuffix("/") ? home : home + "/"
    }

    func openRepo() async {
        let path = repoPath
        do {
            try await Task.detached { try WorkspaceClient.shared.open(path: path) }.value
            output = "Opened: \(path)"
            isRepoOpen = true
        } catch {
            output = String(describing: error)
            isRepoOpen = false
        }
    }

    func runStatus() async {
        do {
            let result = try await Task.detached { try WorkspaceClient.shared.status() }.value
            output = result
        } catch {
            output = String(describing: error)
        }
    }

    func runDiff() async {
        do {
            let result = try await Task.detached { try WorkspaceClient.shared.diff() }.value
            output = result
        } catch {
            output = String(describing: error)
        }
    }
}
