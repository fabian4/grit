import SwiftUI

struct LeftPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Mode", selection: $viewModel.leftMode) {
                ForEach(LeftPanelMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Divider()
            switch viewModel.leftMode {
            case .changes:
                if viewModel.statusItems.isEmpty {
                    Text("No changes")
                        .foregroundStyle(.secondary)
                } else {
                    Toggle("Group by Folder", isOn: $viewModel.groupDiffByFolder)
                        .toggleStyle(.switch)
                    List(selection: $viewModel.selectedPath) {
                        if viewModel.groupDiffByFolder {
                            OutlineGroup(viewModel.statusTree, children: \.children) { node in
                                Text(node.name)
                                    .tag(node.path)
                                    .opacity(node.isLeaf ? 1.0 : 0.85)
                            }
                        } else {
                            ForEach(viewModel.sortedStatusItems) { item in
                                Text(item.display)
                                    .tag(item.path)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .transaction { $0.animation = nil }
                    .onChange(of: viewModel.selectedPath) { _ in
                        if viewModel.isSelectedLeaf {
                            Task { await viewModel.loadDiffForSelection() }
                        }
                    }
                }
            case .files:
                if viewModel.fileTree.isEmpty {
                    Text("No files")
                        .foregroundStyle(.secondary)
                } else {
                    List(selection: $viewModel.selectedFileID) {
                        OutlineGroup(viewModel.fileTree, children: \.children) { node in
                            Text(node.name)
                                .tag(node.id)
                        }
                    }
                    .listStyle(.sidebar)
                    .onChange(of: viewModel.selectedFileID) { _ in
                        Task { await viewModel.loadFileForSelection() }
                    }
                }
            }
            Spacer()
        }
        .padding(8)
    }
}


struct MainPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detail")
                .font(.headline)
            Picker("Diff View", selection: $viewModel.diffMode) {
                ForEach(DiffViewMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Toggle("Editable", isOn: $viewModel.isDetailEditable)
                .toggleStyle(.switch)
            Divider()
            switch viewModel.leftMode {
            case .changes:
                if viewModel.detailOutput.isEmpty {
                    Text("Select an item to view details")
                        .foregroundStyle(.secondary)
                } else {
                    DiffTextView(
                        text: $viewModel.detailOutput,
                        lines: viewModel.diffLines,
                        mode: viewModel.diffMode,
                        isEditable: viewModel.isDetailEditable
                    )
                }
            case .files:
                if viewModel.fileContent.isEmpty {
                    Text("Select a file to view contents")
                        .foregroundStyle(.secondary)
                } else {
                    DiffTextView(
                        text: $viewModel.fileContent,
                        lines: viewModel.diffLines,
                        mode: .unified,
                        isEditable: viewModel.isDetailEditable
                    )
                }
            }
            Spacer()
        }
        .padding(8)
    }

}

struct BottomPanel: View {
    @State private var selection: Int = 0
    @State private var tabs: [String] = ["Terminal 1"]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Terminal")
                    .font(.headline)
                Spacer()
                Button("New Tab") {
                    tabs.append("Terminal \(tabs.count + 1)")
                    selection = max(0, tabs.count - 1)
                }
            }

            TabView(selection: $selection) {
                ForEach(tabs.indices, id: \.self) { index in
                    Text("Terminal tab \(index + 1) not wired yet")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(8)
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
        }
        .padding(8)
    }
}
