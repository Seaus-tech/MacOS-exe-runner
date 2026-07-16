# 🍷 MACEXE: macOS Windows Executable Runner

<p align="center>
  <strong>Run Windows <code>.exe</code> binaries natively on macOS with isolated sandboxing and AI-powered log analysis.</strong>
</p>

<p align="center>
  <img src="https://img.shields.io/badge/Platform-macOS-blue?style=flat-square&logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/Language-SwiftUI-F54A46?style=flat-square&logo=swift" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Runtime-Wine-8B0000?style=flat-square&logo=wine" alt="Wine" />
  <img src="https://img.shields.io/badge/Assistant-AI%20Troubleshooter-00A67E?style=flat-square&logo=openai" alt="AI Troubleshooter" />
</p>

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Requirements](#requirements)
- [Usage](#usage)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Repository Structure](#repository-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Overview

**MACEXE** is a native macOS application that simplifies running Windows executables (`.exe`) on Apple Silicon and Intel Macs. It leverages an isolated Wine translation layer to run software without virtual machines, featuring a modern SwiftUI interface and real-time streaming logs.

When execution fails, MACEXE's built-in **AI Engine** analyzes your crash dumps and Wine output logs, automatically recommending startup arguments, DLL overrides (`WINEDLLOVERRIDES`), or library path settings to get the application working.

## Features

| Feature | Description |
|---------|-------------|
| 📦 **Isolated Sandboxing** | Dynamically creates dedicated prefix at `~/.macexe_prefix` |
| ⚡ **Asynchronous Execution** | Background process launching for smooth UI |
| 🪵 **Real-Time Logs** | Stdout/stderr streams in retro terminal log window |
| 🤖 **AI-Powered Diagnostics** | Cloudflare Worker backend analyzes crashes |
| 🧩 **Runtime Versatility** | Supports bundled Wine and Wine Devel.app |

## Screenshots

*(Coming soon)*

## Installation

1. **Clone and open** the project in **Xcode**:
   ```bash
   git clone https://github.com/Seaus-tech/MacOS-exe-runner.git
   cd MacOS-exe-runner
   open MacOS-exe-runner.xcodeproj
   ```

2. **Setup Runtimes** - Ensure a local `Runtimes/` folder with `bin/wine` is added to your app bundle resources, or install [Wine Devel](https://wiki.winehq.org/MacOS) on your Mac

3. Build and run with `Cmd + R`

## Requirements

- macOS 13.0 (Ventura) or later
- Wine (bundled or installed via Wine Devel)
- Xcode 15.0 or later (for building from source)

## Usage

1. Select your `.exe` file in the UI
2. Input any parameters in the text field
3. Click **Run** to launch the application
4. If a crash occurs, input your email and click **Ask AI** for recommendations

## Architecture

### Key Components

| File | Description |
|------|-------------|
| `WineExecutionManager.swift` | Handles process spawning via Apple's `Process` APIs, configures environmental variables (`WINEPREFIX`, `DYLD_FALLBACK_LIBRARY_PATH`), and manages non-blocking stream pipes |
| `AIEngine.swift` | Manages HTTP post requests to the Cloudflare diagnostic API, returning formatted JSON recommendations |
| `AIView.swift` | Displays the diagnostic assistant, listing recommended commands and developer logs |
| `ContentView.swift` | Main application dashboard |

## Troubleshooting

The AI Engine helps diagnose common issues:

| Issue | Solution |
|-------|----------|
| Missing DLL errors | AI suggests `WINEDLLOVERRIDES` settings |
| Wine prefix configuration | Automatic prefix repair recommendations |
| Graphics compatibility | DirectX/Vulkan compatibility solutions |
| Audio not working | Library path and driver recommendations |

## Repository Structure

```
MacOS-exe-runner/
├── MACEXE/                 # Main Xcode project
│   ├── WineExecutionManager.swift
│   ├── AIEngine.swift
│   ├── AIView.swift
│   └── ContentView.swift
├── Runtimes/               # Wine runtime binaries
├── Resources/              # App icons and assets
└── README.md               # This file
```

## Roadmap

- [ ] Add support for `.msi` installers
- [ ] Implement Wine version management
- [ ] Create application compatibility database
- [ ] Add batch file execution support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

© 2026 Seaus Tech. All rights reserved.