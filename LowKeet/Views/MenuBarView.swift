import SwiftUI
import LaunchAtLogin

struct MenuBarView: View {
    @EnvironmentObject var whisperState: WhisperState
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @EnvironmentObject var menuBarManager: MenuBarManager
    @EnvironmentObject var updaterViewModel: UpdaterViewModel
    // OFFLINE MODE: Removed enhancementService and aiService
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var menuRefreshTrigger = false
    @State private var isHovered = false
    
    var body: some View {
        VStack {
            Menu {
                ForEach(whisperState.usableModels, id: \.id) { model in
                    Button {
                        Task {
                            await whisperState.setDefaultTranscriptionModel(model)
                        }
                    } label: {
                        HStack {
                            Text(model.displayName)
                            if whisperState.currentTranscriptionModel?.id == model.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Manage Models") {
                    menuBarManager.openMainWindowAndNavigate(to: "AI Models")
                }
            } label: {
                HStack {
                    Text("Transcription Model: \(whisperState.currentTranscriptionModel?.displayName ?? "None")")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                }
            }
            
            // OFFLINE MODE: Removed AI Enhancement, Prompt, Provider, and Model menus

            Divider()

            LanguageSelectionView(whisperState: whisperState, displayMode: .menuItem)

            Menu {
                ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                    Button {
                        audioDeviceManager.selectDeviceAndSwitchToCustomMode(id: device.id)
                    } label: {
                        HStack {
                            Text(device.name)
                            if audioDeviceManager.getCurrentDevice() == device.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                if audioDeviceManager.availableDevices.isEmpty {
                    Text("No devices available")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack {
                    Text("Audio Input")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                }
            }

            // OFFLINE MODE: Removed "Additional" menu (clipboard/screen capture context)

            Divider()
            
            Button("Retry Last Transcription") {
                LastTranscriptionService.retryLastTranscription(from: whisperState.modelContext, whisperState: whisperState)
            }
            
            Button("Copy Last Transcription") {
                LastTranscriptionService.copyLastTranscription(from: whisperState.modelContext)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            
            Button("History") {
                menuBarManager.openMainWindowAndNavigate(to: "History")
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Button("Settings") {
                menuBarManager.openMainWindowAndNavigate(to: "Settings")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button(menuBarManager.isMenuBarOnly ? "Show Dock Icon" : "Hide Dock Icon") {
                menuBarManager.toggleMenuBarOnly()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            
            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { oldValue, newValue in
                    LaunchAtLogin.isEnabled = newValue
                }
            
            Divider()
            
            Button("Check for Updates") {
                updaterViewModel.checkForUpdates()
            }
            .disabled(!updaterViewModel.canCheckForUpdates)
            
            
            Divider()
            
            Button("Quit LowKeet") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
