import SwiftUI

struct DictionarySettingsView: View {
    // OFFLINE MODE: Removed "Correct Spellings" section (requires AI enhancement)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var heroSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .padding(20)
                .background(Circle()
                    .fill(Color(.windowBackgroundColor).opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5))

            VStack(spacing: 8) {
                Text("Word Replacements")
                    .font(.system(size: 28, weight: .bold))
                Text("Automatically replace specific words or phrases in your transcriptions")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    private var mainContent: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Replacements")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        DictionaryImportExportService.shared.importDictionary()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Import word replacements")

                    Button(action: {
                        DictionaryImportExportService.shared.exportDictionary()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Export word replacements")
                }
            }
            .padding(.horizontal, 32)

            WordReplacementView()
                .background(CardBackground(isSelected: false))
        }
        .padding(.vertical, 40)
    }
} 
