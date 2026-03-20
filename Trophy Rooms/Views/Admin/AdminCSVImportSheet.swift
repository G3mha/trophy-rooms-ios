import SwiftUI
import UniformTypeIdentifiers

struct AdminCSVImportSheet: View {
    @ObservedObject var viewModel: AdminAchievementsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.csvPreviewData.isEmpty {
                    // No data - show file picker prompt
                    ContentUnavailableView(
                        "Select a CSV File",
                        systemImage: "doc.badge.plus",
                        description: Text("Choose a CSV file with achievements to import.\n\nRequired columns: title (or name)\nOptional columns: description, points, tier, iconUrl")
                    )
                    .padding()

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Choose File", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    // Show preview
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preview")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.csvPreviewData.count - 1) rows")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        if let headers = viewModel.csvPreviewData.first {
                            ScrollView(.horizontal) {
                                HStack(spacing: 4) {
                                    ForEach(headers, id: \.self) { header in
                                        Text(header)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    List {
                        ForEach(Array(viewModel.csvPreviewData.dropFirst().prefix(10).enumerated()), id: \.offset) { index, row in
                            VStack(alignment: .leading, spacing: 4) {
                                if let headers = viewModel.csvPreviewData.first {
                                    ForEach(Array(zip(headers, row).enumerated()), id: \.offset) { _, pair in
                                        HStack {
                                            Text(pair.0)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 80, alignment: .leading)
                                            Text(pair.1)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if viewModel.csvPreviewData.count > 11 {
                            Text("... and \(viewModel.csvPreviewData.count - 11) more rows")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let result = viewModel.importResult {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(result.success ? "Import Complete" : "Import Failed")
                                    .font(.headline)
                                Text("Created: \(result.createdCount), Skipped: \(result.skippedCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                    }

                    HStack(spacing: 12) {
                        Button {
                            viewModel.clearImportState()
                        } label: {
                            Text("Clear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showingFilePicker = true
                        } label: {
                            Text("Choose Different File")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            importData()
                        } label: {
                            if isImporting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Import")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isImporting)
                    }
                    .padding()
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
        .onDisappear {
            viewModel.clearImportState()
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                viewModel.previewCSV(content)
            } catch {
                DispatchQueue.main.async {
                    viewModel.errorMessage = "Failed to read file: \(error.localizedDescription)"
                }
            }
        case .failure(let error):
            DispatchQueue.main.async {
                viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }

    private func importData() {
        isImporting = true

        Task {
            _ = await viewModel.importCSV(achievementSetId: viewModel.selectedSetId)
            DispatchQueue.main.async {
                isImporting = false
            }
        }
    }
}

#Preview {
    AdminCSVImportSheet(viewModel: AdminAchievementsViewModel())
}
