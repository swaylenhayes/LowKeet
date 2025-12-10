# LowKeet

**LowKeet** is a free, open-source, offline-first macOS voice transcription app powered by local AI models. Record or transcribe audio files directly on your Mac with complete privacy - no internet required, no data ever leaves your machine.

## Features

- 🎙️ **Real-time Voice Recording** - Record and transcribe audio in real-time
- 📁 **Audio File Transcription** - Transcribe existing audio files (MP3, M4A, WAV, and more)
- 🔒 **100% Offline & Private** - All processing happens locally on your Mac
- 🤖 **Multiple AI Models** - Choose between Whisper and Parakeet models
- ⌨️ **Keyboard Shortcuts** - Global hotkeys for quick recording
- 📋 **Auto-paste** - Automatically paste transcriptions where you need them
- 🎨 **Mini Recorder** - Compact floating recorder window
- 📝 **Word Replacement Dictionary** - Customize transcription output
- 🗑️ **Auto-cleanup** - Automatically manage storage of old transcriptions
- 🎯 **Menu Bar Access** - Quick access from your menu bar

## System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Disk Space**: ~2.5 GB for bundled AI models
- **Permissions**: Microphone access (for recording)

## Building from Source

### Prerequisites

1. Install [Xcode](https://developer.apple.com/xcode/) from the Mac App Store
2. Ensure you have an Apple Developer account (free tier is sufficient for local builds)

### Build Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/lowkeet.git
   cd lowkeet
   ```

2. **Open in Xcode**
   ```bash
   open LowKeet.xcodeproj
   ```

3. **Configure Code Signing**
   - Select the `LowKeet` project in the navigator (blue icon at top)
   - Select the `LowKeet` target
   - Go to the "Signing & Capabilities" tab
   - Change the "Team" dropdown to your Apple Developer account
   - If needed, change the "Bundle Identifier" to something unique (e.g., `com.yourname.lowkeet`)

4. **Verify Package Dependencies**
   - Xcode should automatically resolve Swift Package Manager dependencies
   - If not, go to File → Packages → Resolve Package Versions

5. **Build and Run**
   - Select "My Mac" as the run destination
   - Press `Cmd + R` to build and run
   - Or press `Cmd + B` to just build

### Bundled AI Models

LowKeet comes with 4 pre-bundled AI models (no additional downloads required):

1. **ggml-base.en** - Fast, English-only Whisper model
2. **ggml-large-v3-turbo** - High-quality, fast Whisper model
3. **Parakeet TDT v2** - NVIDIA's streaming speech recognition model
4. **Parakeet TDT v3** - Latest version with improved accuracy

All models are located in the `BundledModels/` directory and total ~1.6 GB.

## Usage

### First Launch

1. Grant microphone permission when prompted
2. Select your preferred AI model from Settings
3. Start recording with the keyboard shortcut or menu bar icon

### Recording Audio

- **Global Shortcut**: Press `Cmd + Shift + Space` (customizable in settings)
- **Menu Bar**: Click the LowKeet icon → "Start Recording"
- **Mini Recorder**: Enable in Settings for a floating recorder window

### Transcribing Files

1. Go to "Transcribe Audio" tab
2. Drag and drop audio files or click "Select Files"
3. Wait for transcription to complete
4. Copy or save the transcription

## Configuration

### Settings

Access settings from the main window or menu bar:

- **AI Models**: Switch between Whisper and Parakeet models
- **Audio Input**: Select your preferred microphone
- **Keyboard Shortcuts**: Customize global hotkeys
- **Dictionary**: Add custom word replacements
- **Auto-cleanup**: Configure automatic deletion of old transcriptions

### Keyboard Shortcuts

| Action | Default Shortcut | Customizable |
|--------|-----------------|--------------|
| Start/Stop Recording | `Cmd + Shift + Space` | ✅ |
| Toggle Mini Recorder | `Cmd + Shift + M` | ✅ |
| Dismiss Mini Recorder | `Escape` | ❌ |

## Project Structure

```
LowKeet/
├── LowKeet/              # Source code
│   ├── Views/           # SwiftUI views
│   ├── Services/        # Core services
│   ├── Whisper/         # Whisper integration
│   ├── Models/          # Data models
│   ├── Resources/       # Sounds and bundled models
│   └── Assets.xcassets/ # App icons and images
├── BundledModels/       # Pre-bundled AI models
│   ├── Whisper/        # Whisper .bin files
│   ├── Parakeet/       # Parakeet CoreML models
│   └── ggml-base.en-encoder.mlmodelc/
└── LowKeet.xcodeproj/  # Xcode project
```

## Dependencies

LowKeet uses the following open-source Swift packages:

- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Audio processing for Parakeet models
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Global keyboard shortcut management
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin-Modern) - Launch at login functionality
- [AXSwift](https://github.com/clavierorg/AXSwift) - Accessibility API wrapper
- [KeySender](https://github.com/jordanbaird/KeySender) - Keyboard event simulation
- [SelectedTextKit](https://github.com/tisfeng/SelectedTextKit) - Selected text capture
- [MediaRemoteAdapter](https://github.com/ejbills/mediaremote-adapter) - Media control integration
- [Zip](https://github.com/marmelroy/Zip) - Archive management
- [swift-atomics](https://github.com/apple/swift-atomics) - Low-level atomic operations

All dependencies are managed via Swift Package Manager and will be automatically downloaded during the first build.

## Troubleshooting

### Build Errors

**"No signing certificate found"**
- Solution: Go to Signing & Capabilities and select your developer team

**"Package resolution failed"**
- Solution: File → Packages → Reset Package Caches, then resolve again

**"Models not found"**
- Solution: Ensure the `BundledModels/` directory exists and contains all model files

### Runtime Issues

**"Microphone permission denied"**
- Solution: System Settings → Privacy & Security → Microphone → Enable LowKeet

**"Models failed to load"**
- Solution: Check that model files weren't corrupted during download. Re-clone the repository if needed.

**"Transcription is very slow"**
- Solution: Try switching to the `ggml-base.en` model for faster performance on older Macs

## Contributing

Contributions are welcome! This project is licensed under the GNU General Public License v3.0.

### Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

### What this means:

- ✅ You can use, study, and modify this software freely
- ✅ You can distribute modified versions
- ❌ You cannot use this software in proprietary/closed-source applications
- ❌ You cannot sublicense under different terms
- ✅ All derivatives must also be open source under GPL v3

## Acknowledgments

- Built on [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) for Whisper model inference
- Parakeet models from [NVIDIA NeMo](https://github.com/NVIDIA/NeMo)
- Special thanks to all open-source dependencies and their maintainers

## Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/lowkeet/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/lowkeet/discussions)

---

**Made with ❤️ for privacy-conscious Mac users**
