import Foundation
import SwiftUI
import AVFoundation
import SwiftData
import os

@MainActor
class AudioTranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var currentError: TranscriptionError?

    private let modelContext: ModelContext
    private let whisperState: WhisperState
    private let logger = Logger(subsystem: "com.swaylenhayes.apps.lowkeet", category: "AudioTranscriptionService")
    
    // Transcription services (OFFLINE MODE: Only local services)
    private let localTranscriptionService: LocalTranscriptionService
    private lazy var parakeetTranscriptionService = ParakeetTranscriptionService()
    
    enum TranscriptionError: Error {
        case noAudioFile
        case transcriptionFailed
        case modelNotLoaded
        case invalidAudioFormat
    }
    
    init(modelContext: ModelContext, whisperState: WhisperState) {
        self.modelContext = modelContext
        self.whisperState = whisperState
        self.localTranscriptionService = LocalTranscriptionService(modelsDirectory: whisperState.modelsDirectory, whisperState: whisperState)
    }
    
    func retranscribeAudio(from url: URL, using model: any TranscriptionModel) async throws -> Transcription {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.noAudioFile
        }
        
        await MainActor.run {
            isTranscribing = true
        }
        
        do {
            // Delegate transcription to appropriate service
            let transcriptionStart = Date()
            var text: String
            
            // OFFLINE MODE: Only local and parakeet models supported
            switch model.provider {
            case .local:
                text = try await localTranscriptionService.transcribe(audioURL: url, model: model)
            case .parakeet:
                text = try await parakeetTranscriptionService.transcribe(audioURL: url, model: model)
            }
            
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)
            text = TranscriptionOutputFilter.filter(text)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if UserDefaults.standard.object(forKey: "IsTextFormattingEnabled") as? Bool ?? true {
                text = WhisperTextFormatter.format(text)
            }

            text = WordReplacementService.shared.applyReplacements(to: text)
            logger.notice("✅ Word replacements applied")
            
            // Get audio duration
            let audioAsset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(try await audioAsset.load(.duration))
            
            // Create a permanent copy of the audio file
            let recordingsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("com.swaylenhayes.apps.LowKeet")
                .appendingPathComponent("Recordings")
            
            let fileName = "retranscribed_\(UUID().uuidString).wav"
            let permanentURL = recordingsDirectory.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.copyItem(at: url, to: permanentURL)
            } catch {
                logger.error("❌ Failed to create permanent copy of audio: \(error.localizedDescription)")
                isTranscribing = false
                throw error
            }
            
            let permanentURLString = permanentURL.absoluteString

            // OFFLINE MODE: Removed prompt detection and AI enhancement

            // Create transcription without enhancement
            let newTranscription = Transcription(
                text: text,
                duration: duration,
                audioFileURL: permanentURLString,
                transcriptionModelName: model.displayName,
                promptName: nil,
                transcriptionDuration: transcriptionDuration,
                powerModeName: nil,
                powerModeEmoji: nil
            )
            modelContext.insert(newTranscription)
            do {
                try modelContext.save()
                NotificationCenter.default.post(name: .transcriptionCreated, object: newTranscription)
            } catch {
                logger.error("❌ Failed to save transcription: \(error.localizedDescription)")
            }

            await MainActor.run {
                isTranscribing = false
            }

            return newTranscription
        } catch {
            logger.error("❌ Transcription failed: \(error.localizedDescription)")
            currentError = .transcriptionFailed
            isTranscribing = false
            throw error
        }
    }
}
