import Foundation

final class RepoViewModel: ObservableObject {
    @Published var repoPath: String
    @Published var output: String = ""
    @Published var isRepoOpen: Bool = false

    private let client = WorkspaceClient.shared

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.repoPath = home.hasSuffix("/") ? home : home + "/"
    }

    @MainActor
    func openRepo() async {
        let path = repoPath
        do {
            try await WorkspaceClient.shared.open(path: path)
            output = "Opened: \(path)"
            isRepoOpen = true
        } catch {
            output = String(describing: error)
            isRepoOpen = false
        }
    }

    @MainActor
    func runStatus() async {
        do {
            let result = try await WorkspaceClient.shared.status()
            output = result
        } catch {
            output = String(describing: error)
        }
    }

    @MainActor
    func runDiff() async {
        do {
            let result = try await WorkspaceClient.shared.diff()
            output = result
        } catch {
            output = String(describing: error)
        }
    }
}
