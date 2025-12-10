import SwiftUI
import SwiftData
import Sparkle
import AppKit
import OSLog
import AppIntents
import FluidAudio

@main
struct LowKeetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let container: ModelContainer
    let containerInitializationFailed: Bool
    
    @StateObject private var whisperState: WhisperState
    @StateObject private var hotkeyManager: HotkeyManager
    @StateObject private var updaterViewModel: UpdaterViewModel
    @StateObject private var menuBarManager: MenuBarManager
    // OFFLINE MODE: Removed aiService, enhancementService, activeWindowService, onboarding, announcements
    @State private var showMenuBarIcon = true
    
    // Audio cleanup manager for automatic deletion of old audio files
    private let audioCleanupManager = AudioCleanupManager.shared
    
    // Transcription auto-cleanup service for zero data retention
    private let transcriptionAutoCleanupService = TranscriptionAutoCleanupService.shared
    
    init() {
        // Configure FluidAudio logging subsystem
        AppLogger.defaultSubsystem = "com.swaylenhayes.apps.lowkeet.parakeet"

        // OFFLINE MODE: Removed PowerMode initialization

        let logger = Logger(subsystem: "com.swaylenhayes.apps.lowkeet", category: "Initialization")
        let schema = Schema([Transcription.self])
        var initializationFailed = false
        
        // Attempt 1: Try persistent storage
        if let persistentContainer = Self.createPersistentContainer(schema: schema, logger: logger) {
            container = persistentContainer
            
            #if DEBUG
            // Print SwiftData storage location in debug builds only
            if let url = persistentContainer.mainContext.container.configurations.first?.url {
                print("💾 SwiftData storage location: \(url.path)")
            }
            #endif
        }
        // Attempt 2: Try in-memory storage
        else if let memoryContainer = Self.createInMemoryContainer(schema: schema, logger: logger) {
            container = memoryContainer
            
            logger.warning("Using in-memory storage as fallback. Data will not persist between sessions.")
            
            // Show alert to user about storage issue
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Storage Warning"
                alert.informativeText = "LowKeet couldn't access its storage location. Your transcriptions will not be saved between sessions."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
        // Attempt 3: Try ultra-minimal default container
        else if let minimalContainer = Self.createMinimalContainer(schema: schema, logger: logger) {
            container = minimalContainer
            logger.warning("Using minimal emergency container")
        }
        // All attempts failed: Create disabled container and mark for termination
        else {
            logger.critical("All ModelContainer initialization attempts failed")
            initializationFailed = true
            
            // Create a dummy container to satisfy Swift's initialization requirements
            // App will show error and terminate in onAppear
            container = Self.createDummyContainer(schema: schema)
        }
        
        containerInitializationFailed = initializationFailed

        // OFFLINE MODE: Initialize only core services (no AI enhancement)
        let updaterViewModel = UpdaterViewModel()
        _updaterViewModel = StateObject(wrappedValue: updaterViewModel)

        let whisperState = WhisperState(modelContext: container.mainContext)
        _whisperState = StateObject(wrappedValue: whisperState)

        let hotkeyManager = HotkeyManager(whisperState: whisperState)
        _hotkeyManager = StateObject(wrappedValue: hotkeyManager)

        let menuBarManager = MenuBarManager()
        _menuBarManager = StateObject(wrappedValue: menuBarManager)
        appDelegate.menuBarManager = menuBarManager
        
        // Ensure no lingering recording state from previous runs
        Task {
            await whisperState.resetOnLaunch()
        }
        
        AppShortcuts.updateAppShortcutParameters()
    }
    
    // MARK: - Container Creation Helpers
    
    private static func createPersistentContainer(schema: Schema, logger: Logger) -> ModelContainer? {
        do {
            // Create app-specific Application Support directory URL
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("com.swaylenhayes.apps.lowkeet", isDirectory: true)
            
            // Create the directory if it doesn't exist
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            
            // Configure SwiftData to use the conventional location
            let storeURL = appSupportURL.appendingPathComponent("default.store")
            let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("Failed to create persistent ModelContainer: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func createInMemoryContainer(schema: Schema, logger: Logger) -> ModelContainer? {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger.error("Failed to create in-memory ModelContainer: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func createMinimalContainer(schema: Schema, logger: Logger) -> ModelContainer? {
        do {
            // Try default initializer without custom configuration
            return try ModelContainer(for: schema)
        } catch {
            logger.error("Failed to create minimal ModelContainer: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func createDummyContainer(schema: Schema) -> ModelContainer {
        // Create an absolute minimal container for initialization
        // This uses in-memory storage and will never actually be used
        // as the app will show an error and terminate in onAppear
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        // Note: In-memory containers should always succeed unless SwiftData itself is unavailable
        // (which would indicate a serious system-level issue). We use preconditionFailure here
        // rather than fatalError because:
        // 1. This code is only reached after 3 prior initialization attempts have failed
        // 2. An in-memory container failing indicates SwiftData is completely unavailable
        // 3. Swift requires non-optional container property to be initialized
        // 4. The app will immediately terminate in onAppear when containerInitializationFailed is checked
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // This indicates a system-level SwiftData failure - app cannot function
            preconditionFailure("Unable to create even a dummy ModelContainer. SwiftData is unavailable: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // OFFLINE MODE: No onboarding, always show main content
            ContentView()
                .environmentObject(whisperState)
                .environmentObject(hotkeyManager)
                .environmentObject(updaterViewModel)
                .environmentObject(menuBarManager)
                .modelContainer(container)
                    .onAppear {
                        // Check if container initialization failed
                        if containerInitializationFailed {
                            let alert = NSAlert()
                            alert.messageText = "Critical Storage Error"
                            alert.informativeText = "LowKeet cannot initialize its storage system. The app cannot continue.\n\nPlease try reinstalling the app or contact support if the issue persists."
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "Quit")
                            alert.runModal()
                            
                            NSApplication.shared.terminate(nil)
                            return
                        }
                        
                        updaterViewModel.silentlyCheckForUpdates()
                        // OFFLINE MODE: Removed announcements service

                        // Start the transcription auto-cleanup service (handles immediate and scheduled transcript deletion)
                        transcriptionAutoCleanupService.startMonitoring(modelContext: container.mainContext)
                        
                        // Start the automatic audio cleanup process only if transcript cleanup is not enabled
                        if !UserDefaults.standard.bool(forKey: "IsTranscriptionCleanupEnabled") {
                            audioCleanupManager.startAutomaticCleanup(modelContext: container.mainContext)
                        }
                        
                        // Process any pending open-file request now that the main ContentView is ready.
                        if let pendingURL = appDelegate.pendingOpenFileURL {
                            NotificationCenter.default.post(name: .navigateToDestination, object: nil, userInfo: ["destination": "Transcribe Audio"])
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(name: .openFileForTranscription, object: nil, userInfo: ["url": pendingURL])
                            }
                            appDelegate.pendingOpenFileURL = nil
                        }
                    }
                    .background(WindowAccessor { window in
                        WindowManager.shared.configureWindow(window)
                    })
                    .onDisappear {
                        // OFFLINE MODE: Removed announcements service
                        whisperState.unloadModel()

                        // Stop the transcription auto-cleanup service
                        transcriptionAutoCleanupService.stopMonitoring()
                        
                        // Stop the automatic audio cleanup process
                        audioCleanupManager.stopAutomaticCleanup()
                    }
            // OFFLINE MODE: Removed onboarding view
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterViewModel: updaterViewModel)
            }
        }
        
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarView()
                .environmentObject(whisperState)
                .environmentObject(hotkeyManager)
                .environmentObject(menuBarManager)
                .environmentObject(updaterViewModel)
                // OFFLINE MODE: Removed aiService and enhancementService
        } label: {
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 22
                $0.size.width = 22 / ratio
                return $0
            }(NSImage(named: "menuBarIcon")!)

            Image(nsImage: image)
        }
        .menuBarExtraStyle(.menu)
        
        #if DEBUG
        WindowGroup("Debug") {
            Button("Toggle Menu Bar Only") {
                menuBarManager.isMenuBarOnly.toggle()
            }
        }
        #endif
    }
}

class UpdaterViewModel: ObservableObject {
    @AppStorage("autoUpdateCheck") private var autoUpdateCheck = true
    
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Enable automatic update checking
        updaterController.updater.automaticallyChecksForUpdates = autoUpdateCheck
        updaterController.updater.updateCheckInterval = 24 * 60 * 60
        
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
    
    func toggleAutoUpdates(_ value: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = value
    }
    
    func checkForUpdates() {
        // This is for manual checks - will show UI
        updaterController.checkForUpdates(nil)
    }
    
    func silentlyCheckForUpdates() {
        // This checks for updates in the background without showing UI unless an update is found
        updaterController.updater.checkForUpdatesInBackground()
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel
    
    var body: some View {
        Button("Check for Updates…", action: updaterViewModel.checkForUpdates)
            .disabled(!updaterViewModel.canCheckForUpdates)
    }
}

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
