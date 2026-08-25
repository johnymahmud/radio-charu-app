# 🤖 AGENTS.md — AI Agent Operating System & Project Rules
**Target Audience:** All AI Coding Assistants (Google Antigravity, Cursor, Claude Code, GitHub Copilot, Gemini CLI, etc.)  
**Project:** RADIO CHARU (Flutter Android / Multiplatform Live Radio App)  
**Last Updated:** 2026-08-24  
**Primary Architect & Owner:** Johny Mahmud  

---

> [!CAUTION]
> ### 🛑 3 GOLDEN INVIOLABLE RULES FOR ALL AI AGENTS
>
> 1. **DO NOT REMOVE THE WEBVIEW AUDIO ENGINE:**  
>    This project operates 100% on **Caster.fm Free Tier**. Caster.fm does NOT provide direct MP3/Icecast mountpoint stream URLs or API keys. Never replace the WebView controller with `just_audio`, `audioplayers`, or native audio HTTP streaming. Doing so will immediately break live audio streaming.
>
> 2. **DO NOT TOUCH OR MODIFY `main` DIRECTLY:**  
>    The `main` branch contains the proven working baseline ("Golden State"). All new features, refactoring, and experimental bug fixes MUST be done on a dedicated branch (e.g., `git checkout -b feature/...`).
>
> 3. **NO UNAUTHORIZED COMMITS OR PUSHES:**  
>    Never execute `git commit` or `git push` autonomously. Always present `git status` / `git diff`, allow the user to test and verify on an emulator/device, and wait for explicit user approval before committing or pushing.

---

## ⚡ Fast-Boot Session Protocol (Start of Every New Session)

Whenever a new chat session starts or context is resumed, the AI Agent MUST:

1. **Read Core Context:**
   - Read [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md) to understand current progress and pending next steps.
   - Read [docs/AUDIO_STREAMING_BLUEPRINT.md](docs/AUDIO_STREAMING_BLUEPRINT.md) for technical audio streaming and bypass logic.
   - Read [docs/DECISION_LOG.md](docs/DECISION_LOG.md) to understand why past architectural choices were made.

2. **Acknowledge Current State to Developer:**
   - Greet the user in friendly, polite Bengali.
   - State the current Git branch and summarize the next planned action item from `docs/PROJECT_STATE.md`.
   - Ask for confirmation before modifying any code.

3. **Follow the Standard 6-Step Workflow:**
   - Follow [docs/WORKFLOW_AND_SAFETY_GUIDELINES.md](docs/WORKFLOW_AND_SAFETY_GUIDELINES.md).

---

## 🗺️ Project Navigation Sitemap

| Category | File Path | Purpose |
| :--- | :--- | :--- |
| **Living State** | [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md) | Current status, roadmap, known warnings, next steps |
| **Technical Blueprint** | [docs/AUDIO_STREAMING_BLUEPRINT.md](docs/AUDIO_STREAMING_BLUEPRINT.md) | Caster.fm bypass, DOM selectors, regex, smart resume |
| **Non-Tech Guide** | [docs/SYSTEM_WALKTHROUGH_NON_TECH.md](docs/SYSTEM_WALKTHROUGH_NON_TECH.md) | Plain-language story, zero-cost setup, owner FAQ |
| **Workflow Policy** | [docs/WORKFLOW_AND_SAFETY_GUIDELINES.md](docs/WORKFLOW_AND_SAFETY_GUIDELINES.md) | Branch isolation, testing, commit authorization |
| **Decisions (ADR)** | [docs/DECISION_LOG.md](docs/DECISION_LOG.md) | Architecture Decision Records & rationale |
| **Changelog / History** | [docs/ACTIVITY_LOG.md](docs/ACTIVITY_LOG.md) | Chronological session activity and changes |
| **Design System** | [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Folk theme colors, typography, UI components |
| **App Entrypoint** | [lib/main.dart](lib/main.dart) | Main Flutter app, WebView player, lifecycle observer |
| **Community Panel** | [lib/community_panel.dart](lib/community_panel.dart) | Firebase Firestore shouts, comments, admin auth |
| **Web Bridge** | [docs/index.html](docs/index.html) | GitHub Pages host for Caster.fm embed player |
| **Security Rules** | [firestore.rules](firestore.rules) | Cloud Firestore security rules for comments/admins |
| **1-Click Launcher** | [run_app.bat](run_app.bat) | All-in-one 1-click AVD boot, lock cleaner, & Flutter runner |

---

## 🎨 UI & Aesthetics Guardrails
- **Theme:** Folk-inspired solid pop aesthetic celebrating Bangladeshi culture.
- **Palette:** Reference [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) for exact color tokens (`folkRed`, `folkYellow`, `folkOrange`, `folkGreen`, `folkCream`, `folkWhite`, `folkInk`).
- **Do not introduce generic primary colors (plain blue, plain red).** Always use the curated palette.

---

## 💻 Autonomous Terminal Execution & Multi-PC Self-Healing SOP

Whenever the user asks to run the live emulator or test the app in any session or on any machine:

1. **Autonomous Terminal Execution:**
   - The AI Agent MUST proactively execute terminal commands to launch the emulator, resolve AVD lock conflicts, and run the app.
   - Clean stale AVD lock files (`*.lock` in `~/.android/avd/*.avd/`) automatically if a previous session terminated uncleanly.

2. **Multi-PC Setup & Environment Self-Healing:**
   - If the project is opened on a new or different PC, run an environment audit (`flutter doctor -v`, `flutter devices`, `flutter emulators`).
   - If Android Studio, Android SDK, or Platform Tools paths are missing, configure them via terminal (`flutter config`, PATH resolution).
   - If no AVD/Emulator exists, use `avdmanager` / `sdkmanager` via terminal to install system images and create an AVD (e.g., Pixel 7), or guide the user step-by-step.
   - If Gradle, Java, or Flutter dependencies are out of sync, automatically run `flutter pub get` and sync tools.
   - **Reporting Rule:** Always report detected environment status clearly to the user, autonomously solve what can be automated via CLI, and explicitly specify any manual action required by the user (e.g., USB Debugging permission click, Hardware Virtualization in BIOS).

---

## 🔄 End-of-Session Handover Protocol
At the end of any significant coding session:
1. Update [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md) with newly completed tasks and next priorities.
2. Update [docs/ACTIVITY_LOG.md](docs/ACTIVITY_LOG.md) with a short session summary.
3. Sync technical changes into [docs/AUDIO_STREAMING_BLUEPRINT.md](docs/AUDIO_STREAMING_BLUEPRINT.md) and [docs/SYSTEM_WALKTHROUGH_NON_TECH.md](docs/SYSTEM_WALKTHROUGH_NON_TECH.md).

