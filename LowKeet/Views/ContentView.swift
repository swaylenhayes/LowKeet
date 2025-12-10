import SwiftUI
import SwiftData
import KeyboardShortcuts

// OFFLINE MODE: Detect offline mode
#if !ENABLE_AI_ENHANCEMENT
private let isOfflineMode = true
#else
private let isOfflineMode = false
#endif

// ViewType enum (OFFLINE MODE: Removed enhancement, powerMode, license, metrics)
enum ViewType: String, CaseIterable, Identifiable {
    case transcribeAudio = "Transcribe Audio"
    case history = "History"
    case models = "AI Models"
    case permissions = "Permissions"
    case audioInput = "Audio Input"
    case dictionary = "Dictionary"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transcribeAudio: return "waveform.circle.fill"
        case .history: return "doc.text.fill"
        case .models: return "brain.head.profile"
        case .permissions: return "shield.fill"
        case .audioInput: return "mic.fill"
        case .dictionary: return "character.book.closed.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    // OFFLINE MODE: Default to transcribeAudio
    @State private var selectedView: ViewType? = .transcribeAudio
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    private var visibleViewTypes: [ViewType] {
        ViewType.allCases
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                Section {
                    // App Header
                    HStack(spacing: 9) {
                        if let appIcon = NSImage(named: "AppIcon") {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .cornerRadius(8)
                                .padding(.leading, -3)
                        }

                        Text("LowKeet")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                ForEach(visibleViewTypes) { viewType in
                    Section {
                        NavigationLink(value: viewType) {
                            HStack(spacing: 12) {
                                Image(systemName: viewType.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 24, height: 24)

                                Text(viewType.rawValue)
                                    .font(.system(size: 14, weight: .medium))

                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 1)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("LowKeet")
            .navigationSplitViewColumnWidth(210)
        } detail: {
            if let selectedView = selectedView {
                detailView(for: selectedView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle(selectedView.rawValue)
            } else {
                Text("Select a view")
                    .foregroundColor(.secondary)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 940, minHeight: 730)
        // OFFLINE MODE: Removed LowKeet Pro, Enhancement, Power Mode destinations
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                switch destination {
                case "Settings":
                    selectedView = .settings
                case "AI Models":
                    selectedView = .models
                case "History":
                    selectedView = .history
                case "Permissions":
                    selectedView = .permissions
                case "Transcribe Audio":
                    selectedView = .transcribeAudio
                default:
                    break
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailView(for viewType: ViewType) -> some View {
        // OFFLINE MODE: Removed enhancement, powerMode, license, metrics cases
        switch viewType {
        case .models:
            ModelManagementView(whisperState: whisperState)
        case .transcribeAudio:
            AudioTranscribeView()
        case .history:
            TranscriptionHistoryView()
        case .audioInput:
            AudioInputSettingsView()
        case .dictionary:
            DictionarySettingsView()
        case .settings:
            SettingsView()
                .environmentObject(whisperState)
        case .permissions:
            PermissionsView()
        }
    }
}

 
