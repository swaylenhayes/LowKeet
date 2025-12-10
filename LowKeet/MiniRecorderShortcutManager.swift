import Foundation
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let escapeRecorder = Self("escapeRecorder")
    static let cancelRecorder = Self("cancelRecorder")
    // OFFLINE MODE: Removed enhancement and PowerMode shortcuts
}

@MainActor
class MiniRecorderShortcutManager: ObservableObject {
    private var whisperState: WhisperState
    private var visibilityTask: Task<Void, Never>?
    
    private var isCancelHandlerSetup = false
    
    // Double-tap Escape handling
    private var escFirstPressTime: Date? = nil
    private let escSecondPressThreshold: TimeInterval = 1.5
    private var isEscapeHandlerSetup = false
    private var escapeTimeoutTask: Task<Void, Never>?
    
    init(whisperState: WhisperState) {
        self.whisperState = whisperState
        setupVisibilityObserver()
        setupEscapeHandlerOnce()
        setupCancelHandlerOnce()
        // OFFLINE MODE: Removed setupEnhancementShortcut
        NotificationCenter.default.addObserver(self, selector: #selector(settingsDidChange), name: .AppSettingsDidChange, object: nil)
    }

    @objc private func settingsDidChange() {
        // OFFLINE MODE: Removed enhancement settings handling
    }

    private func setupVisibilityObserver() {
        visibilityTask = Task { @MainActor in
            for await isVisible in whisperState.$isMiniRecorderVisible.values {
                if isVisible {
                    activateEscapeShortcut()
                    activateCancelShortcut()
                    // OFFLINE MODE: Removed enhancement and PowerMode shortcut setup
                } else {
                    deactivateEscapeShortcut()
                    deactivateCancelShortcut()
                    // OFFLINE MODE: Removed enhancement and PowerMode shortcut removal
                }
            }
        }
    }
    
    // Setup escape handler once
    private func setupEscapeHandlerOnce() {
        guard !isEscapeHandlerSetup else { return }
        isEscapeHandlerSetup = true
        
        KeyboardShortcuts.onKeyDown(for: .escapeRecorder) { [weak self] in
            Task { @MainActor in
                guard let self = self,
                      await self.whisperState.isMiniRecorderVisible else { return }
                
                // Don't process if custom shortcut is configured
                guard KeyboardShortcuts.getShortcut(for: .cancelRecorder) == nil else { return }
                
                let now = Date()
                if let firstTime = self.escFirstPressTime,
                   now.timeIntervalSince(firstTime) <= self.escSecondPressThreshold {
                    self.escFirstPressTime = nil
                    await self.whisperState.cancelRecording()
                } else {
                    self.escFirstPressTime = now
                    SoundManager.shared.playEscSound()
                    NotificationManager.shared.showNotification(
                        title: "Press ESC again to cancel recording",
                        type: .info,
                        duration: self.escSecondPressThreshold
                    )
                    self.escapeTimeoutTask = Task { [weak self] in
                        try? await Task.sleep(nanoseconds: UInt64((self?.escSecondPressThreshold ?? 1.5) * 1_000_000_000))
                        await MainActor.run {
                            self?.escFirstPressTime = nil
                        }
                    }
                }
            }
        }
    }
    
    private func activateEscapeShortcut() {
        // Don't activate if custom shortcut is configured
        guard KeyboardShortcuts.getShortcut(for: .cancelRecorder) == nil else { return }
        KeyboardShortcuts.setShortcut(.init(.escape), for: .escapeRecorder)
    }
    
    // Setup cancel handler once
    private func setupCancelHandlerOnce() {
        guard !isCancelHandlerSetup else { return }
        isCancelHandlerSetup = true
        
        KeyboardShortcuts.onKeyDown(for: .cancelRecorder) { [weak self] in
            Task { @MainActor in
                guard let self = self,
                      await self.whisperState.isMiniRecorderVisible,
                      KeyboardShortcuts.getShortcut(for: .cancelRecorder) != nil else { return }

                await self.whisperState.cancelRecording()
            }
        }
    }
    
    private func activateCancelShortcut() {
        // Handler checks if shortcut exists
    }
    
    private func deactivateEscapeShortcut() {
        KeyboardShortcuts.setShortcut(nil, for: .escapeRecorder)
        escFirstPressTime = nil
        escapeTimeoutTask?.cancel()
        escapeTimeoutTask = nil
    }
    
    private func deactivateCancelShortcut() {
        // Shortcut managed by user settings
    }

    // OFFLINE MODE: Removed all enhancement and PowerMode shortcut functions
    
    deinit {
        visibilityTask?.cancel()
        NotificationCenter.default.removeObserver(self)
        Task { @MainActor in
            deactivateEscapeShortcut()
            deactivateCancelShortcut()
            // OFFLINE MODE: Removed enhancement and PowerMode shortcut removal
        }
    }
} 