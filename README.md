<div align="center">
  <img src="LowKeet/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="180" height="180" />
  <h1>LowKeet</h1>
  <p>Privacy-first voice-to-text for macOS - 100% offline transcription</p>

  ![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-brightgreen)
  [![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
</div>

---

## Overview

**LowKeet** is a fully open-source, privacy-focused macOS application that transcribes speech to text instantly using local AI models.

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

**For source releases:**

1. **Download and extract** the latest source release from [GitHub Releases](https://github.com/swaylenhayes/lowkeet/releases)
   ```bash
   unzip v1.1-source.zip
   cd LowKeet-v1.1-source
   ```

2. **Install dependencies** (framework & models)
   ```bash
   # Download v1.1-framework-models.zip from releases
   unzip v1.1-framework-models.zip

   # Copy to project
   cp -r whisper.xcframework ./
   cp -r BundledModels ./LowKeet/Resources/
   ```

3. **Open in Xcode**
   ```bash
   open LowKeet.xcodeproj
   ```

4. **Configure Code Signing**
   - Select the LowKeet project in the navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team

5. **Build and Run**
   - Press `⌘+R` to build and run
   - On first launch, models are automatically copied to Application Support

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

## Framework & AI Models

### Included Framework

- **whisper.xcframework** (161MB) - High-performance inference via [whisper.cpp](https://github.com/ggerganov/whisper.cpp)

### Included AI Models

- **Whisper base.en** (141 MB) - English-only base model (GGML)
- **Whisper large-v3-turbo** (547 MB) - 99 languages supported (GGML)
- **Parakeet TDT v2** (443 MB) - NVIDIA English-only model (CoreML)
- **Parakeet TDT v3** (461 MB) - NVIDIA English + 25 European languages (CoreML)

### v1.1 Feature: Automatic Model Initialization

On first launch, models are automatically copied from the app bundle to:
- **Whisper models**: `~/Library/Application Support/com.swaylenhayes.apps.LowKeet/WhisperModels/`
- **Parakeet models**: `~/Library/Application Support/FluidAudio/Models/`

This ensures models work correctly even after app updates or reinstalls.

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

## Acknowledgments & References

### Originally Based On

**[VoiceInk](https://github.com/Beingpax/VoiceInk)** by Pax - LowKeet is adapted for fully offline, open-source distribution.

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

---

**LowKeet** - Privacy-first voice transcription for macOS
Open source • Offline • Free
