# 🍷 MACEXE: macOS Windows Executable Runner

<p align="center>
  <strong>Run Windows <code>.exe</code> binaries natively on macOS with isolated sandboxing and AI-powered log analysis.</strong>
</p>

<p align="center>
  <img src="https://img.shields.io/badge/Platform-macOS-blue?style=flat-square&logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/Language-SwiftUI-orange?style=flat-square&logo=swift" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Runtime-Wine-red?style=flat-square&logo=wine" alt="Wine" />
  <img src="https://img.shields.io/badge/Assistant-AI%20Troubleshooter-purple?style=flat-square&logo=openai" alt="AI Troubleshooter" />
</p>

---

## 🌌 Overview

**MACEXE** is a native macOS application that simplifies running Windows executables (`.exe`) on Apple Silicon and Intel Macs. It leverages an isolated Wine translation layer to run software without virtual machines, featuring a modern SwiftUI interface and real-time streaming logs.

When execution fails, MACEXE's built-in **AI Engine** analyzes your crash dumps and Wine output logs, automatically recommending startup arguments, DLL overrides (`WINEDLLOVERRIDES`), or library path settings to get the application working.

---

## ✨ Features

- 📦 **Isolated Sandboxing** — Dynamically creates and manages a dedicated prefix at `~/.macexe_prefix` to keep your system clean
- ⚡ **Asynchronous Execution** — Launches processes on background threads to keep the macOS UI butter-smooth
- 🪵 **Real-Time Logs** — Captures stdout and stderr streams in a retro, copyable terminal log window
- 🤖 **AI-Powered Diagnostics** — Streams logs to a Cloudflare Worker backend to analyze crashes and suggest fixes
- 🧩 **Runtime Versatility** — Supports both local bundled Wine runtimes and system-level Wine Devel.app

---

## 🛠️ Architecture & Codebase

- [**WineExecutionManager.swift**](file:///Users/YashB/seaus/MacOS-exe-runner/MACEXE/MACEXE/WineExecutionManager.swift) — Handles process spawning via Apple's `Process` APIs, configures custom environmental variables (`WINEPREFIX`, `DYLD_FALLBACK_LIBRARY_PATH`), and manages non-blocking stream pipes
- [**AIEngine.swift**](file:///Users/YashB/seaus/MacOS-exe-runner/MACEXE/MACEXE/AIEngine.swift) — Manages HTTP post requests to the Cloudflare diagnostic API, returning formatted JSON recommendations
- [**AIView.swift**](file:///Users/YashB/seaus/MacOS-exe-runner/MACEXE/MACEXE/AIView.swift) — Displays the diagnostic assistant, listing recommended commands and developer logs
- [**ContentView.swift**](file:///Users/YashB/seaus/MacOS-exe-runner/MACEXE/MACEXE/ContentView.swift) — The main application dashboard

---

## 🚀 Getting Started

1. **Clone and open** the project in **Xcode**
2. **Setup Runtimes** — Ensure a local `Runtimes/` folder with `bin/wine` is added to your app bundle resources, or install [Wine Devel](https://wiki.winehq.org/MacOS) on your Mac
3. Select your `.exe` file in the UI, input any parameters, and click **Run**
4. If a crash or warning occurs, input your email and click **Ask AI** to receive a tailored recommendation

---

## 📦 Requirements

- macOS 13.0 (Ventura) or later
- Wine (bundled or installed via Wine Devel)
- Xcode 15.0 or later (for building from source)

---

## 🔧 Troubleshooting

The AI Engine helps diagnose common issues:
- Missing DLL errors
- Wine prefix configuration problems
- Graphics and audio compatibility

---

## 📂 Repository Structure

```
MacOS-exe-runner/
├── MACEXE/                 # Main Xcode project
│   ├── WineExecutionManager.swift
│   ├── AIEngine.swift
│   ├── AIView.swift
│   └── ContentView.swift
├── Runtimes/               # Wine runtime binaries
└── README.md               # This file
```

---

<p align="center>
  <sub>© 2026 Seaus Tech. All rights reserved.</sub>
</p>