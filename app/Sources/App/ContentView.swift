import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = RepoViewModel.shared
    @FocusState private var isPathFocused: Bool
    @State private var splitRatio: CGFloat = CGFloat(AppConfig.shared.splitRatio)

    var body: some View {
        WorkspaceShell(viewModel: viewModel, splitRatio: $splitRatio)
            .padding(0)
            .background(AppTheme.mainDark.ignoresSafeArea())
            .frame(minWidth: 900, minHeight: 600)
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
                isPathFocused = true
            }
    }
}
