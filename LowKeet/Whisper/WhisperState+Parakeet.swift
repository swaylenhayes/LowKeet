import Foundation
import FluidAudio
import AppKit

// OFFLINE MODE: Model downloading disabled
#if !ENABLE_AI_ENHANCEMENT
private let isOfflineMode = true
#else
private let isOfflineMode = false
#endif

extension WhisperState {
    private func parakeetDefaultsKey(for modelName: String) -> String {
        "ParakeetModelDownloaded_\(modelName)"
    }

    private func parakeetVersion(for modelName: String) -> AsrModelVersion {
        modelName.lowercased().contains("v2") ? .v2 : .v3
    }

    private func parakeetCacheDirectory(for version: AsrModelVersion) -> URL {
        AsrModels.defaultCacheDirectory(for: version)
    }

    func isParakeetModelDownloaded(named modelName: String) -> Bool {
        // OFFLINE MODE: Check bundled models first (directly in Resources)
        if let bundlePath = Bundle.main.resourcePath {
            let bundledParakeetPath = URL(fileURLWithPath: bundlePath)
                .appendingPathComponent("\(modelName)-coreml")
            if FileManager.default.fileExists(atPath: bundledParakeetPath.path) {
                return true
            }
        }

        // Then check UserDefaults (for downloaded models)
        return UserDefaults.standard.bool(forKey: parakeetDefaultsKey(for: modelName))
    }

    func isParakeetModelDownloaded(_ model: ParakeetModel) -> Bool {
        isParakeetModelDownloaded(named: model.name)
    }

    func isParakeetModelDownloading(_ model: ParakeetModel) -> Bool {
        parakeetDownloadStates[model.name] ?? false
    }

    @MainActor
    func downloadParakeetModel(_ model: ParakeetModel) async {
        // OFFLINE MODE: Model downloading disabled, all models pre-bundled
        if isOfflineMode {
            print("Parakeet model download disabled in offline mode - all models are pre-bundled")
            return
        }

        if isParakeetModelDownloaded(model) {
            return
        }

        let modelName = model.name
        parakeetDownloadStates[modelName] = true
        downloadProgress[modelName] = 0.0

        let timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            Task { @MainActor in
                if let currentProgress = self.downloadProgress[modelName], currentProgress < 0.9 {
                    self.downloadProgress[modelName] = currentProgress + 0.005
                }
            }
        }

        let version = parakeetVersion(for: modelName)

        do {
            _ = try await AsrModels.downloadAndLoad(version: version)

            _ = try await VadManager()

            UserDefaults.standard.set(true, forKey: parakeetDefaultsKey(for: modelName))
            downloadProgress[modelName] = 1.0
        } catch {
            UserDefaults.standard.set(false, forKey: parakeetDefaultsKey(for: modelName))
        }

        timer.invalidate()
        parakeetDownloadStates[modelName] = false
        downloadProgress[modelName] = nil

        refreshAllAvailableModels()
    }

    @MainActor
    func deleteParakeetModel(_ model: ParakeetModel) {
        if let currentModel = currentTranscriptionModel,
           currentModel.provider == .parakeet,
           currentModel.name == model.name {
            currentTranscriptionModel = nil
            UserDefaults.standard.removeObject(forKey: "CurrentTranscriptionModel")
        }

        let version = parakeetVersion(for: model.name)
        let cacheDirectory = parakeetCacheDirectory(for: version)

        do {
            if FileManager.default.fileExists(atPath: cacheDirectory.path) {
                try FileManager.default.removeItem(at: cacheDirectory)
            }
            UserDefaults.standard.set(false, forKey: parakeetDefaultsKey(for: model.name))
        } catch {
            // Silently ignore removal errors
        }

        refreshAllAvailableModels()
    }

    @MainActor
    func showParakeetModelInFinder(_ model: ParakeetModel) {
        let cacheDirectory = parakeetCacheDirectory(for: parakeetVersion(for: model.name))

        if FileManager.default.fileExists(atPath: cacheDirectory.path) {
            NSWorkspace.shared.selectFile(cacheDirectory.path, inFileViewerRootedAtPath: "")
        }
    }
}
