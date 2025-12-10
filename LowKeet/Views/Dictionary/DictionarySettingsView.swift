import SwiftUI

struct DictionarySettingsView: View {
    // OFFLINE MODE: Removed "Correct Spellings" section (requires AI enhancement)
    
    var body: some View {
        ScrollView {
            mainContent
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
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
            

            WordReplacementView()
                .background(CardBackground(isSelected: false))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
} 
