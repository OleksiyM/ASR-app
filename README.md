# ASR-app 🎙️✨

ASR-app is a lightweight, blazing-fast, and aesthetically stunning native macOS menu bar application designed for instant speech-to-text input across any application. Press a global hotkey, dictate your thoughts, and the transcribed text will be automatically typed directly into your active text field.

Designed with modern **macOS LiquidGlass** principles, combining deep translucency, vibrant neon gradients, and organic micro-animations.

---

## 🌟 Key Features

- **🎙️ Blazing-Fast Transcription (Whisper Turbo)**:
  Audio is sent directly to the Groq Whisper Large V3 Turbo API, ensuring near-instant transcription (under one second) and maximum accuracy.
  
- **✍️ Whisper Prompting & Punctuation Guide**:
  Uses a hidden high-quality style template to guide the model to automatically format the transcribed text with perfect grammar, capitals, and punctuation (commas, periods, dashes, and question marks).

- **📚 Custom Vocabulary Support**:
  Add custom terms, names, or technical slang separated by commas directly in the Settings panel (up to 30-50 words). The application seamlessly appends these terms to the transcription prompt, ensuring 100% recognition accuracy.

- **📋 Smart Auto-Paste**:
  Once transcription is complete, the text is copied to your clipboard and immediately pasted into your active application (web browser, IDE, chat app) using a simulated `Cmd+V` keystroke.

- **🎨 Premium LiquidGlass UI**:
  - A beautiful, adaptive translucent Menu Bar Popover that fits perfectly on your screen.
  - An interactive animated real-time volume indicator (Neon Wave) with glowing reflections.
  - A gorgeous borderless **«About» (About ASR-app)** window featuring dynamic animated liquid glass gradient blobs.

- **⏱️ Auto-Stop Timer & Warm Warning**:
  Set your preferred maximum recording duration (1, 2, 3, 5, or 10 minutes) in Settings. When recording gets within 30 seconds of the auto-stop limit, the popover transitions into a warm neon-orange color scheme with an active countdown timer to prevent text truncation.

- **🌐 Complete Multilingual Support (En, Ru, Ua)**:
  - Matches your macOS system language by default.
  - Dynamic on-the-fly UI language switching (English, Russian, Ukrainian) without app restarts.
  - Choice of dictation language (Auto-detect or specific languages, including complete support for Ukrainian `uk`).

- **🌗 Adaptive Themes**:
  - Integration with **System** (inherits macOS settings), **Dark**, and **Light** themes.
  - Adapts translucency, materials, and glows instantly.

- **⌨️ Global Hotkeys**:
  Dictate from anywhere in macOS without opening the popover. Pick your preferred global shortcut (e.g., `⌥ + Space`) in settings to start and stop recording seamlessly.

---

## 🛠️ Tech Stack

* **Language**: Swift 5.10+
* **Frameworks**: SwiftUI & AppKit
* **System Integration**:
  * `AVFoundation` — high-fidelity audio capture and real-time decibel level monitoring.
  * `Carbon API` — low-level global shortcut tracking from anywhere.
  * `CoreGraphics` (`CGEvent`) — secure keyboard emulation for Smart Auto-Paste.
* **Build System**: XcodeGen (dynamic `.xcodeproj` generation from `project.yml` for a clean Git repository).

---

## 🚀 Getting Started

### 📋 Requirements
* macOS 14.0 or newer.
* [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed on your system.

### ⚙️ How to Build and Run Locally

1. Install **XcodeGen** using Homebrew:
   ```bash
   brew install xcodegen
   ```

2. Clone the repository and navigate to its folder:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ASR-app.git
   cd ASR-app
   ```

3. Generate the Xcode project from `project.yml`:
   ```bash
   xcodegen generate
   ```

4. Open the newly generated project file:
   ```bash
   open ASRApp.xcodeproj
   ```

5. Press **`Cmd + R`** in Xcode to compile and run!

> [!IMPORTANT]
> On the first launch, the application will request access to the **Microphone** (for voice recording) and **Accessibility** permissions (required for keyboard simulation to support the Smart Auto-Paste feature). Please grant these permissions in your macOS System Settings.

---

## 🔑 API Key Configuration

To enable speech-to-text recognition, you need a free API key from Groq:
1. Log in or sign up at [console.groq.com](https://console.groq.com).
2. Generate a new API key in the **API Keys** section.
3. Click the waveform icon in the macOS status bar ➔ Open Settings (gear icon ⚙️) ➔ Paste your API key into the field.

---

## ⚙️ Automated CI/CD (GitHub Actions)

This project features a fully automated DevOps pipeline:
* When you push a Git version tag starting with `v` (e.g., `v1.2.3`), the GitHub Actions release workflow is triggered.
* On a high-performance cloud runner (**`macos-15`** with Xcode 16+), the pipeline installs XcodeGen and compiles the application.
* **Matrix Architecture**: Builds independent, native binaries for **Apple Silicon (arm64)** and **Intel (x86_64)** to keep the application lightweight without code bloat.
* **Ad-Hoc Signing**: Automatically applies ad-hoc codesigning (`codesign --force --deep --sign -`) to allow seamless launching by bypassing macOS Gatekeeper blockades.
* **Premium DMG Packaging**: Instead of basic ZIP archives, the pipeline uses `create-dmg` to package the `.app` into a gorgeous, customized DMG installer with a custom layout and drag-and-drop support.
* Detailed release notes (Release Notes / Changelog) are auto-generated based on commit logs, and assets are uploaded directly to the GitHub Release.

---

## 🫂 Authors & Contributions

* **Alex** — Product visionary, co-creator, and lead QA engineer.
* **Eva** — Your AI pair-programmer, developer, and visual designer 🫂🍵✨.

Created with love, hot tea, and deep care for every pixel! 🍵✨
