import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// OFFLINE MODE: Detect offline mode
#if !ENABLE_AI_ENHANCEMENT
private let isOfflineMode = true
#else
private let isOfflineMode = false
#endif

enum ModelFilter: String, CaseIterable, Identifiable {
    case recommended = "Recommended"
    case local = "Local"
    case cloud = "Cloud"
    case custom = "Custom"
    var id: String { self.rawValue }

    // OFFLINE MODE: Filter out cloud and custom in offline mode
    static var availableFilters: [ModelFilter] {
        if isOfflineMode {
            return [.recommended, .local]
        }
        return ModelFilter.allCases
    }
}

struct ModelManagementView: View {
    @ObservedObject var whisperState: WhisperState
    // OFFLINE MODE: No custom models to edit
    @Environment(\.modelContext) private var modelContext

    // State for the unified alert
    @State private var isShowingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("AI Models")
                    .font(.title2)
                    .fontWeight(.semibold)

                availableModelsSection
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .destructive(Text("Delete"), action: deleteActionClosure),
                secondaryButton: .cancel()
            )
        }
    }

    private var availableModelsSection: some View {
        VStack(spacing: 12) {
            ForEach(filteredModels, id: \.id) { model in
                let isWarming = (model as? LocalModel).map { localModel in
                    WhisperModelWarmupCoordinator.shared.isWarming(modelNamed: localModel.name)
                } ?? false

                ModelCardRowView(
                    model: model,
                    whisperState: whisperState,
                    isDownloaded: whisperState.availableModels.contains { $0.name == model.name },
                    isCurrent: whisperState.currentTranscriptionModel?.name == model.name,
                    downloadProgress: whisperState.downloadProgress,
                    modelURL: whisperState.availableModels.first { $0.name == model.name }?.url,
                    isWarming: isWarming,
                    deleteAction: {
                        // OFFLINE MODE: Only local model deletion supported
                        if let downloadedModel = whisperState.availableModels.first(where: { $0.name == model.name }) {
                            alertTitle = "Delete Model"
                            alertMessage = "Are you sure you want to delete the model '\(downloadedModel.name)'?"
                            deleteActionClosure = {
                                Task {
                                    await whisperState.deleteModel(downloadedModel)
                                }
                            }
                            isShowingDeleteAlert = true
                        }
                    },
                    setDefaultAction: {
                        Task {
                            whisperState.setDefaultTranscriptionModel(model)
                        }
                    },
                    downloadAction: {
                        if let localModel = model as? LocalModel {
                            Task { await whisperState.downloadModel(localModel) }
                        }
                    }
                )
            }
        }
    }

    private var filteredModels: [any TranscriptionModel] {
        // OFFLINE MODE: Show only pre-bundled models
        let recommendedNames = isOfflineMode
            ? ["parakeet-tdt-0.6b-v3", "parakeet-tdt-0.6b-v2", "ggml-large-v3-turbo-q5_0", "ggml-base.en"]
            : ["ggml-base.en", "ggml-large-v3-turbo-q5_0", "ggml-large-v3-turbo", "whisper-large-v3-turbo"]

        return whisperState.allAvailableModels.filter {
            return recommendedNames.contains($0.name)
        }.sorted { model1, model2 in
            let index1 = recommendedNames.firstIndex(of: model1.name) ?? Int.max
            let index2 = recommendedNames.firstIndex(of: model2.name) ?? Int.max
            return index1 < index2
        }
    }

    // MARK: - Import Panel
    private func presentImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "bin")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.title = "Select a Whisper ggml .bin model"
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                await whisperState.importLocalModel(from: url)
            }
        }
    }
}
