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

    @State private var selectedFilter: ModelFilter = .recommended
    @State private var isShowingSettings = false
    
    // State for the unified alert
    @State private var isShowingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                defaultModelSection
                availableModelsSection
            }
            .padding(40)
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
    
    private var defaultModelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Model")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(whisperState.currentTranscriptionModel?.displayName ?? "No model selected")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(isSelected: false))
        .cornerRadius(10)
    }
    
    private var availableModelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Modern compact pill switcher
                HStack(spacing: 12) {
                    ForEach(ModelFilter.availableFilters, id: \.self) { filter in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedFilter = filter
                                isShowingSettings = false
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .medium))
                                .foregroundColor(selectedFilter == filter ? .primary : .primary.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    CardBackground(isSelected: selectedFilter == filter, cornerRadius: 22)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingSettings.toggle()
                    }
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isShowingSettings ? .accentColor : .primary.opacity(0.7))
                        .padding(12)
                        .background(
                            CardBackground(isSelected: isShowingSettings, cornerRadius: 22)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 12)
            
            if isShowingSettings {
            } else {
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
                                    await whisperState.setDefaultTranscriptionModel(model)
                                }
                            },
                            downloadAction: {
                                if let localModel = model as? LocalModel {
                                    Task { await whisperState.downloadModel(localModel) }
                                }
                            }
                        )
                    }
                    
                    // OFFLINE MODE: Import button disabled in offline mode
                    #if ENABLE_AI_ENHANCEMENT
                    if selectedFilter == .local {
                        HStack(spacing: 8) {
                            Button(action: { presentImportPanel() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import Local Model…")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(CardBackground(isSelected: false))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            InfoTip(
                                title: "Import local Whisper models",
                                message: "Add a custom fine-tuned whisper model to use with Voice Memo. Select the downloaded .bin file.",
                                learnMoreURL: "https://google.com"
                            )
                            .help("Read more about custom local models")
                        }
                    }
                    #endif
                }
            }
        }
        .padding()
    }

    private var filteredModels: [any TranscriptionModel] {
        switch selectedFilter {
        case .recommended:
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
        case .local:
            return whisperState.allAvailableModels.filter { $0.provider == .local || $0.provider == .parakeet }
        case .cloud:
            #if ENABLE_CLOUD_TRANSCRIPTION
            let cloudProviders: [ModelProvider] = [.groq, .elevenLabs, .deepgram, .mistral, .gemini, .soniox]
            return whisperState.allAvailableModels.filter { cloudProviders.contains($0.provider) }
            #else
            return []
            #endif
        case .custom:
            #if ENABLE_CLOUD_TRANSCRIPTION
            return whisperState.allAvailableModels.filter { $0.provider == .custom }
            #else
            return []
            #endif
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
