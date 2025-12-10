<div align="center">
  <img src="LowKeet/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="180" height="180" />
  <h1>LowKeet</h1>
  <p>Privacy-first voice-to-text for macOS - 100% offline transcription</p>

  ![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-brightgreen)
  [![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
</div>

---

## Overview

**LowKeet** is a fully open-source, privacy-focused macOS application that transcribes speech to text instantly using local AI models. Originally based on VoiceInk, LowKeet has been adapted for complete offline operation with all models bundled.

**Key Differences from VoiceInk:**
- ✅ **100% Open Source** - Build from source, no licenses required
- ✅ **Fully Offline** - All AI models bundled, no cloud services
- ✅ **No Auto-Updates** - You control when and how to update
- ✅ **Privacy Guaranteed** - Your data never leaves your device

![LowKeet Mac App](https://github.com/user-attachments/assets/12367379-83e7-48a6-b52c-4488a6a04bba)

## Features

- 🎙️ **Accurate Transcription**: Local AI models (Whisper & Parakeet) that transcribe speech to text with high accuracy
- 🔒 **Privacy First**: 100% offline processing - your data never leaves your device
- 🎯 **Global Shortcuts**: Configurable keyboard shortcuts for quick recording and push-to-talk functionality
- 📝 **Personal Dictionary**: Train the AI with custom words, industry terms, and smart text replacements
- 🔄 **Smart Modes**: Multiple transcription modes optimized for different writing styles and contexts
- 🎨 **Customizable Interface**: Choose between Notch Recorder and Mini Recorder styles
- ⚙️ **Audio Control**: System audio muting during recording, custom feedback sounds
- 💾 **Data Management**: Import/export settings, automatic transcript cleanup options

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- ~3GB of disk space (for models and build)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/swaylenhayes/LowKeet.git
   cd LowKeet
   ```

2. **Open in Xcode**
   ```bash
   open LowKeet.xcodeproj
   ```

3. **Configure Code Signing**
   - Select the LowKeet project in the navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team from the dropdown
   - Xcode will automatically manage provisioning

4. **Build and Run**
   - Press `⌘+B` to build
   - Press `⌘+R` to run

For detailed build instructions, troubleshooting, and project structure information, see [BUILDING.md](BUILDING.md).

## Project Structure

```
LowKeet/
├── LowKeet/                    # Main source code
│   ├── Models/                 # Data models
│   ├── Views/                  # SwiftUI views
│   │   ├── Settings/           # Settings screens
│   │   ├── Recorder/           # Recording UI
│   │   └── Components/         # Reusable components
│   ├── Services/               # Business logic & services
│   ├── Whisper/                # Whisper integration
│   └── Resources/              # Assets and models
│       └── BundledModels/      # AI models (1.6GB)
├── whisper.xcframework/        # Whisper C++ framework
├── BundledModels/              # Additional model files
└── LowKeet.xcodeproj/          # Xcode project
```

## Documentation

- [Building from Source](BUILDING.md) - Detailed build instructions and troubleshooting
- [Distribution Plan](GITHUB_DISTRIBUTION_PLAN.md) - GitHub distribution strategy

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

This means you can:
- ✅ Use the software for any purpose
- ✅ Study and modify the source code
- ✅ Distribute copies
- ✅ Distribute modified versions

Under the conditions that:
- ⚠️ You disclose the source code
- ⚠️ You license modifications under GPL v3.0
- ⚠️ You state changes made to the code
- ⚠️ You include the original license and copyright

## Support

**Having issues?**
1. Check the [BUILDING.md](BUILDING.md) troubleshooting section
2. Search existing [GitHub Issues](https://github.com/swaylenhayes/LowKeet/issues)
3. Create a new issue with:
   - macOS version
   - Xcode version
   - Steps to reproduce
   - Error messages or logs

## Bundled AI Models

LowKeet includes the following pre-trained models for offline transcription:

### Parakeet Models (~1.6GB)
- **parakeet-tdt-0.6b-v2-coreml** - Parakeet TDT v2 model
- **parakeet-tdt-0.6b-v3-coreml** - Parakeet TDT v3 model

These NVIDIA Parakeet models provide high-quality speech recognition optimized for Core ML.

### Whisper Framework
- **whisper.xcframework** (151MB) - High-performance Whisper inference via whisper.cpp

All models are bundled directly in the repository for complete offline functionality.

## Acknowledgments

### Originally Based On
**[VoiceInk](https://github.com/Beingpax/VoiceInk)** by Pax - LowKeet is a fork adapted for fully offline, open-source distribution.

### Core Technology
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - High-performance Whisper model inference
- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Parakeet model implementation
- [NVIDIA Parakeet](https://github.com/NVIDIA/NeMo) - Speech recognition models

### Essential Dependencies
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - User-customizable keyboard shortcuts
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Launch at login functionality
- [MediaRemoteAdapter](https://github.com/ejbills/mediaremote-adapter) - Media playback control during recording
- [Zip](https://github.com/marmelroy/Zip) - File compression and decompression
- [SelectedTextKit](https://github.com/tisfeng/SelectedTextKit) - Modern macOS library for getting selected text
- [Swift Atomics](https://github.com/apple/swift-atomics) - Thread-safe concurrent programming
- [Sparkle](https://github.com/sparkle-project/Sparkle) - Update framework (disabled in this build)

---

**LowKeet** - Privacy-first voice transcription for macOS
Open source • Offline • Free
