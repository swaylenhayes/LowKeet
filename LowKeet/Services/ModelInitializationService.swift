import Foundation
import os.log

/// Service responsible for initializing bundled models on first app launch
class ModelInitializationService {
    private let logger = Logger(subsystem: "com.swaylenhayes.apps.lowkeet", category: "ModelInitialization")
    private let fileManager = FileManager.default

    // MARK: - Directories

    private var appSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.swaylenhayes.apps.LowKeet")
    }

    private var whisperModelsDirectory: URL {
        appSupportDirectory.appendingPathComponent("WhisperModels")
    }

    private var fluidAudioDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FluidAudio")
            .appendingPathComponent("Models")
    }

    private var bundledResourcesDirectory: URL? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        return URL(fileURLWithPath: resourcePath)
    }

    // MARK: - Initialization Check

    /// Checks if models have been initialized and copies them if needed
    func initializeModelsIfNeeded() async throws {
        let modelsInitializedKey = "ModelsInitializedV1.1"

        // Check if we've already initialized models for this version
        if UserDefaults.standard.bool(forKey: modelsInitializedKey) {
            logger.info("Models already initialized for v1.1")
            return
        }

        logger.info("First launch detected - initializing models...")

        // Copy Whisper models
        try await copyWhisperModels()

        // Copy Parakeet models
        try await copyParakeetModels()

        // Mark as initialized
        UserDefaults.standard.set(true, forKey: modelsInitializedKey)
        logger.info("Model initialization complete")
    }

    // MARK: - Whisper Models

    private func copyWhisperModels() async throws {
        guard let resourcesDir = bundledResourcesDirectory else {
            logger.error("Bundle resources directory not found")
            throw ModelInitializationError.bundleNotFound
        }

        // Create Whisper models directory if needed
        try fileManager.createDirectory(at: whisperModelsDirectory, withIntermediateDirectories: true)

        // Whisper model files are directly in Resources folder (Xcode flattens the structure)
        let whisperModelFiles = ["ggml-base.en.bin", "ggml-large-v3-turbo-q5_0.bin"]

        for fileName in whisperModelFiles {
            let sourceURL = resourcesDir.appendingPathComponent(fileName)

            // Check if file exists in bundle
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                logger.warning("Whisper model not found in bundle: \(fileName)")
                continue
            }

            let destinationURL = whisperModelsDirectory.appendingPathComponent(fileName)

            // Skip if already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                logger.info("Whisper model already exists: \(fileName)")
                continue
            }

            logger.info("Copying Whisper model: \(fileName)")
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        logger.info("Whisper models copied successfully")
    }

    // MARK: - Parakeet Models

    private func copyParakeetModels() async throws {
        guard let resourcesDir = bundledResourcesDirectory else {
            logger.error("Bundle resources directory not found")
            throw ModelInitializationError.bundleNotFound
        }

        // Create FluidAudio models directory if needed
        try fileManager.createDirectory(at: fluidAudioDirectory, withIntermediateDirectories: true)

        // Parakeet model directories are directly in Resources folder (Xcode flattens the structure)
        let parakeetModelNames = ["parakeet-tdt-0.6b-v2-coreml", "parakeet-tdt-0.6b-v3-coreml"]

        for modelName in parakeetModelNames {
            let sourceURL = resourcesDir.appendingPathComponent(modelName)

            // Check if directory exists in bundle
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                logger.warning("Parakeet model not found in bundle: \(modelName)")
                continue
            }

            let destinationURL = fluidAudioDirectory.appendingPathComponent(modelName)

            // Skip if already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                logger.info("Parakeet model already exists: \(modelName)")
                continue
            }

            logger.info("Copying Parakeet model: \(modelName)")
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        logger.info("Parakeet models copied successfully")
    }
}

// MARK: - Errors

enum ModelInitializationError: Error, LocalizedError {
    case bundleNotFound
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:
            return "Could not find bundled models in application bundle"
        case .copyFailed(let details):
            return "Failed to copy models: \(details)"
        }
    }
}
