# ArtCraft Launcher Native Patch (`launcher-patch/`)

This folder archives the native Rust (`egui 0.37`) patch that embeds the **ArtCraft Unified Master Agent Control Board & Live AI Assistant Chat Panel** directly inside the main **ArtCraft Launcher** desktop window (`artcraft-launcher.exe`).

## What This Patch Adds Inside ArtCraft Launcher
- **Right Side Panel (`Ctrl+Shift+A` or Header `AI ASSISTANT` button):**
  - Open by default on launch (`MasterAssistant::open = true`)
  - **`MÓC NỐI: BẬT` (`CHAIN_MODE = ON`) / `TẮT (1 BƯỚC)` (`CHAIN_MODE = OFF`)** toggle switch
  - **Preset & Custom Workflow Selector** (`S01_CONCEPT`..`S12_SOUND_MASTER`) synced live from `board/master-board.json`
  - **Single-Stage Selector** when `CHAIN_MODE = OFF`
  - **`+ QUY TRÌNH MỚI` Builder Mode** delegating directly to `craft-workflow-builder` and auto-reloading `master-board.json`
  - **Multi-Backend Selector:** Claude Code (`FreeLLMAPI` / `1gw.gwai.cloud`, default), Gemini CLI (MCP), OpenCode (MCP), Hermes Agent
  - **Zero-Friction Autonomous Pipeline Prompt Wrapper:** Wraps any 1-line user prompt with Chrome Remote (`vionix-chrome`), web search, file downloads, full ArtCraft + SolidCraft suite + iterative editing, Live Agent Cursor, `--compact`, RTK, and `<= 300-token` handoff rules
  - **Live Streaming Output + Stop Process Tree + Board HTML Launcher**

## Files Patched in `storytold/craft-launcher`
1. `crates/ui-egui/Cargo.toml`: add `serde_json = { workspace = true }` under `[dependencies]`.
2. `crates/ui-egui/src/assistant.rs`: copy [`assistant.rs`](./assistant.rs) from this folder.
3. `crates/ui-egui/src/lib.rs`: declare `pub(crate) mod assistant;`.
4. `crates/ui-egui/src/app.rs`:
   - Add `pub(crate) assistant: crate::assistant::MasterAssistant` field to `LauncherUi` and initialize `MasterAssistant::new()` in `LauncherUi::new()`.
   - In `LauncherUi::ui()`: call `self.assistant.poll(&ctx)`, handle `Ctrl+Shift+A`, request repaint while `self.assistant.is_running()`, and render `egui::Panel::right("master_assistant")` when `self.assistant.open`.
5. `crates/ui-egui/src/views.rs`: add the `AI ASSISTANT` toggle button in `LauncherUi::header()`.

## Rebuild Commands
```powershell
git clone --depth 1 https://github.com/storytold/craft-launcher.git craft-launcher-custom
# Apply the 5 changes above, then:
cd craft-launcher-custom
cargo build --release -p artcraft-launcher
```
The compiled binary at `target\release\artcraft-launcher.exe` replaces `%LOCALAPPDATA%\Programs\ArtCraft\Launcher\artcraft-launcher.exe` (keep `.orig` backup first!).
