//! Embedded ArtCraft Unified Master Agent Control Board & AI Assistant chat panel.
//!
//! Renders natively inside ArtCraft Launcher's right side panel (`Ctrl+Shift+A` or header toggle),
//! loads workflows & 12 stages from `board/master-board.json`, supports `CHAIN_MODE` (`ON` =
//! sequential workflow chain; `OFF` = single stage only), delegates custom workflow creation to
//! `craft-workflow-builder`, and streams output from installed agent CLIs without console flash.

use egui::{CornerRadius, RichText, ScrollArea, Stroke, Ui};

use crate::theme::{self, Tokens};
use crate::widgets::{self, Kind};

#[cfg(not(target_arch = "wasm32"))]
use std::collections::BTreeMap;
#[cfg(not(target_arch = "wasm32"))]
use std::io::{BufRead, BufReader, Write};
#[cfg(not(target_arch = "wasm32"))]
use std::path::{Path, PathBuf};
#[cfg(not(target_arch = "wasm32"))]
use std::process::{Child, Command, Stdio};
#[cfg(not(target_arch = "wasm32"))]
use std::sync::mpsc::{self, Receiver, Sender};

#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) struct StageItem {
    pub id: String,
    pub order: u32,
    pub name: String,
    pub agent: String,
    pub mcp: Vec<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) struct WorkflowItem {
    pub id: String,
    pub label: String,
    pub stages: Vec<String>,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub(crate) enum AgentBackend {
    #[default]
    Claude,
    Gemini,
    OpenCode,
    Hermes,
}

impl AgentBackend {
    pub const ALL: [Self; 4] = [Self::Claude, Self::Gemini, Self::OpenCode, Self::Hermes];

    pub fn label(self) -> &'static str {
        match self {
            Self::Gemini => "Gemini CLI (MCP)",
            Self::Claude => "Claude Code (FreeLLMAPI/1GW)",
            Self::OpenCode => "OpenCode (MCP)",
            Self::Hermes => "Hermes Agent",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum ChatRole {
    User,
    Assistant,
    System,
}

#[derive(Clone, Debug)]
pub(crate) struct ChatMessage {
    pub role: ChatRole,
    pub text: String,
}

#[cfg(not(target_arch = "wasm32"))]
enum WorkerEvent {
    OutputChunk { msg_idx: usize, chunk: String },
    Finished { msg_idx: usize, code: Option<i32> },
    Failed { msg_idx: usize, err: String },
}

#[cfg(not(target_arch = "wasm32"))]
struct RunningJob {
    rx: Receiver<WorkerEvent>,
    pid: u32,
}

pub(crate) struct MasterAssistant {
    pub open: bool,
    pub chain_mode: bool,
    pub workflow_builder_mode: bool,
    pub backend: AgentBackend,
    pub stages: Vec<StageItem>,
    pub workflows: Vec<WorkflowItem>,
    pub active_workflow_id: String,
    pub active_stage_id: String,
    pub input: String,
    pub messages: Vec<ChatMessage>,
    pub board_source: String,
    #[cfg(not(target_arch = "wasm32"))]
    running: Option<RunningJob>,
}

impl Default for MasterAssistant {
    fn default() -> Self {
        Self::new()
    }
}

impl MasterAssistant {
    pub fn new() -> Self {
        let mut me = Self {
            open: true,
            chain_mode: true,
            workflow_builder_mode: false,
            backend: AgentBackend::Claude,
            stages: default_stages(),
            workflows: default_workflows(),
            active_workflow_id: "full-product-launch".to_string(),
            active_stage_id: "S03_3D_MODEL".to_string(),
            input: String::new(),
            messages: vec![ChatMessage {
                role: ChatRole::System,
                text: "MASTER BOARD sẵn sàng. Nhập 1 yêu cầu ngắn bên dưới — khi CHAIN_MODE = ON, quy trình ngầm tự chạy qua Chrome Remote, Web Search, tải file và bộ ArtCraft + SolidCraft đến kết quả cuối."
                    .to_string(),
            }],
            board_source: "built-in defaults".to_string(),
            #[cfg(not(target_arch = "wasm32"))]
            running: None,
        };
        me.reload_board();
        me
    }

    pub fn is_running(&self) -> bool {
        #[cfg(not(target_arch = "wasm32"))]
        {
            self.running.is_some()
        }
        #[cfg(target_arch = "wasm32")]
        {
            false
        }
    }

    pub fn reload_board(&mut self) {
        #[cfg(not(target_arch = "wasm32"))]
        if let Some((path, raw)) = read_board_file() {
            if let Some((stages, workflows, active)) = parse_board_json(&raw) {
                if !stages.is_empty() {
                    self.stages = stages;
                }
                if !workflows.is_empty() {
                    self.workflows = workflows;
                }
                if let Some(wf) = active
                    && self.workflows.iter().any(|w| w.id == wf)
                {
                    self.active_workflow_id = wf;
                }
                self.board_source = path.display().to_string();
                return;
            }
        }
        self.stages = default_stages();
        self.workflows = default_workflows();
    }

    pub fn poll(&mut self, ctx: &egui::Context) {
        #[cfg(not(target_arch = "wasm32"))]
        {
            let mut finished = false;
            let mut should_reload = false;
            if let Some(job) = &self.running {
                while let Ok(ev) = job.rx.try_recv() {
                    match ev {
                        WorkerEvent::OutputChunk { msg_idx, chunk } => {
                            if let Some(msg) = self.messages.get_mut(msg_idx) {
                                if !msg.text.is_empty() && !msg.text.ends_with('\n') {
                                    msg.text.push('\n');
                                }
                                msg.text.push_str(&chunk);
                            }
                        }
                        WorkerEvent::Finished { msg_idx, code } => {
                            finished = true;
                            if let Some(msg) = self.messages.get_mut(msg_idx)
                                && msg.text.trim().is_empty()
                            {
                                msg.text = format!("[Hoàn tất — exit code {:?}]", code);
                            }
                            if self.workflow_builder_mode {
                                should_reload = true;
                            }
                        }
                        WorkerEvent::Failed { msg_idx, err } => {
                            finished = true;
                            if let Some(msg) = self.messages.get_mut(msg_idx) {
                                if !msg.text.is_empty() {
                                    msg.text.push('\n');
                                }
                                msg.text.push_str("[LỖI] ");
                                msg.text.push_str(&err);
                            }
                        }
                    }
                    ctx.request_repaint();
                }
            }
            if finished {
                self.running = None;
                if should_reload {
                    self.reload_board();
                    self.workflow_builder_mode = false;
                }
                ctx.request_repaint();
            }
        }
        #[cfg(target_arch = "wasm32")]
        let _ = ctx;
    }

    pub fn ui(&mut self, ui: &mut Ui) {
        let t = Tokens::get(ui.ctx());
        self.draw_header(ui, &t);
        ui.add_space(6.0);
        self.draw_mode_controls(ui, &t);
        ui.add_space(6.0);
        self.draw_selectors(ui, &t);
        ui.add_space(8.0);
        self.draw_transcript(ui, &t);
        ui.add_space(8.0);
        self.draw_composer(ui, &t);
    }

    fn draw_header(&mut self, ui: &mut Ui, t: &Tokens) {
        ui.horizontal(|ui| {
            ui.label(RichText::new("MASTER BOARD").family(theme::mono_bold()).size(12.0).color(t.ink_strong));
            if self.is_running() {
                widgets::tag(ui, "RUNNING", t.accent, egui::Color32::WHITE);
            } else {
                widgets::tag(ui, "READY", t.sunken, t.good);
            }
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                if widgets::glyph_button(ui, widgets::Glyph::Close, "Hide AI Assistant (Ctrl+Shift+A)").clicked() {
                    self.open = false;
                }
                if widgets::button(ui, "BOARD", Kind::Secondary, 0.0)
                    .on_hover_text("Open interactive HTML dashboard (board/dashboard.html)")
                    .clicked()
                {
                    open_dashboard_html();
                }
                if widgets::button(ui, "SYNC", Kind::Secondary, 0.0)
                    .on_hover_text("Reload board/master-board.json")
                    .clicked()
                {
                    self.reload_board();
                }
            });
        });
        widgets::hud_elided(ui, "TOKEN-OPT: --compact · RTK · <=300t · Chrome Remote", t.good, ui.available_width());
    }

    fn draw_mode_controls(&mut self, ui: &mut Ui, t: &Tokens) {
        ui.horizontal(|ui| {
            let (label, kind) = if self.chain_mode {
                ("MÓC NỐI: BẬT", Kind::Primary)
            } else {
                ("MÓC NỐI: TẮT (1 BƯỚC)", Kind::Secondary)
            };
            if widgets::button(ui, label, kind, 0.0)
                .on_hover_text("BẬT: chạy lần lượt cả quy trình. TẮT: chỉ chạy 1 stage đã chọn rồi dừng.")
                .clicked()
            {
                self.chain_mode = !self.chain_mode;
                self.workflow_builder_mode = false;
            }
            let builder_kind = if self.workflow_builder_mode { Kind::Primary } else { Kind::Secondary };
            if widgets::button(ui, "+ QUY TRÌNH MỚI", builder_kind, 0.0)
                .on_hover_text("Gọi agent phụ craft-workflow-builder để tạo thêm quy trình riêng vào master-board.json")
                .clicked()
            {
                self.workflow_builder_mode = !self.workflow_builder_mode;
            }
        });
        let _ = t;
    }

    fn draw_selectors(&mut self, ui: &mut Ui, t: &Tokens) {
        let w = ui.available_width();
        craft_ui::ComboBox::from_id_salt("master_assistant_backend")
            .selected_text(RichText::new(self.backend.label()).size(12.5))
            .width(w)
            .show_ui(ui, |ui| {
                for b in AgentBackend::ALL {
                    if ui.selectable_label(self.backend == b, b.label()).clicked() {
                        self.backend = b;
                    }
                }
            });
        ui.add_space(4.0);
        if self.workflow_builder_mode {
            widgets::hud_elided(
                ui,
                "BUILDER MODE: Mô tả quy trình mới -> @craft-workflow-builder tự lưu vào board.",
                t.accent_ink,
                w,
            );
            return;
        }
        if self.chain_mode {
            self.draw_workflow_picker(ui, t, w);
        } else {
            self.draw_stage_picker(ui, t, w);
        }
    }

    fn draw_workflow_picker(&mut self, ui: &mut Ui, t: &Tokens, width: f32) {
        let current = self.workflows.iter().find(|x| x.id == self.active_workflow_id).cloned();
        let selected_label = current.as_ref().map_or("Select workflow", |w| w.label.as_str());
        craft_ui::ComboBox::from_id_salt("master_assistant_workflow")
            .selected_text(RichText::new(selected_label).size(12.5))
            .width(width)
            .show_ui(ui, |ui| {
                for wf in &self.workflows {
                    if ui.selectable_label(self.active_workflow_id == wf.id, &wf.label).clicked() {
                        self.active_workflow_id = wf.id.clone();
                    }
                }
            });
        if let Some(wf) = current {
            let chain = wf.stages.join(" -> ");
            widgets::hud_elided(ui, &chain, t.muted, width);
        }
    }

    fn draw_stage_picker(&mut self, ui: &mut Ui, t: &Tokens, width: f32) {
        let current = self.stages.iter().find(|s| s.id == self.active_stage_id).cloned();
        let selected_label = current
            .as_ref()
            .map_or_else(|| "Select stage".to_string(), |s| format!("{} · {}", s.id, s.name));
        craft_ui::ComboBox::from_id_salt("master_assistant_stage")
            .selected_text(RichText::new(selected_label).size(12.5))
            .width(width)
            .show_ui(ui, |ui| {
                for s in &self.stages {
                    let text = format!("{} · {}", s.id, s.name);
                    if ui.selectable_label(self.active_stage_id == s.id, text).clicked() {
                        self.active_stage_id = s.id.clone();
                    }
                }
            });
        if let Some(s) = current {
            let info = format!("@{} | MCP: {}", s.agent, s.mcp.join(", "));
            widgets::hud_elided(ui, &info, t.warn, width);
        }
    }

    fn draw_transcript(&self, ui: &mut Ui, t: &Tokens) {
        let h = (ui.available_height() - 134.0).max(160.0);
        egui::Frame::new()
            .fill(t.sunken)
            .stroke(t.hairline())
            .inner_margin(egui::Margin::same(10))
            .show(ui, |ui| {
                ui.set_min_height(h);
                ui.set_max_height(h);
                ScrollArea::vertical()
                    .id_salt("master_assistant_scroll")
                    .stick_to_bottom(true)
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        for msg in &self.messages {
                            draw_chat_bubble(ui, t, msg);
                            ui.add_space(6.0);
                        }
                    });
            });
    }

    fn draw_composer(&mut self, ui: &mut Ui, t: &Tokens) {
        let enter_send = ui.input(|i| i.key_pressed(egui::Key::Enter) && !i.modifiers.shift);
        let resp = ui.add(
            egui::TextEdit::multiline(&mut self.input)
                .id_salt("master_assistant_input")
                .hint_text("Nhập yêu cầu (vd: thiết kế vỏ CNC ESP32, bản vẽ 2D, render & video)...")
                .desired_rows(3)
                .desired_width(f32::INFINITY),
        );
        let should_send = enter_send && resp.has_focus() && !self.is_running() && !self.input.trim().is_empty();
        ui.add_space(6.0);
        ui.horizontal(|ui| {
            let can_send = !self.is_running() && !self.input.trim().is_empty();
            let send_clicked = ui.add_enabled_ui(can_send, |ui| widgets::button(ui, "GỬI", Kind::Primary, 78.0)).inner.clicked();
            if send_clicked || should_send {
                self.submit_current(ui.ctx());
            }
            if self.is_running() && widgets::button(ui, "DỪNG", Kind::Danger, 78.0).clicked() {
                self.stop_running();
            }
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                if widgets::button(ui, "XÓA", Kind::Secondary, 0.0).clicked() {
                    self.messages.clear();
                }
            });
        });
        let _ = t;
    }

    fn submit_current(&mut self, ctx: &egui::Context) {
        let user_text = self.input.trim().to_string();
        if user_text.is_empty() || self.is_running() {
            return;
        }
        self.input.clear();
        self.messages.push(ChatMessage { role: ChatRole::User, text: user_text.clone() });
        let wrapped = self.build_master_prompt(&user_text);
        let msg_idx = self.messages.len();
        self.messages.push(ChatMessage { role: ChatRole::Assistant, text: "Đang khởi chạy quy trình...\n".to_string() });
        self.spawn_backend(ctx, wrapped, msg_idx);
    }

    fn build_master_prompt(&self, user_text: &str) -> String {
        if self.workflow_builder_mode {
            return format!(
                "Gọi agent `craft-workflow-builder` đọc `{}` và tạo thêm 1 quy trình mới phù hợp với nhu cầu: \"{}\". Lưu vào `board/master-board.json`, giữ nguyên tối ưu token (handoff <= 300 token) rồi báo lại danh sách bước ngắn gọn.",
                self.board_source, user_text
            );
        }
        let philosophy = "Nguyên tắc lõi (Zero-Friction Autonomous Pipeline): khung chat chính chỉ cần 1 yêu cầu này, tự chạy ngầm trọn gói đến kết quả cuối. Thực hiện mọi bước qua Chrome Remote (`vionix-chrome`), web search, tải file mẫu/tài nguyên, và bộ công cụ ArtCraft + SolidCraft rồi tự kiểm tra chỉnh sửa lại. Luôn bật Live Agent Cursor (`ui.agent_cursor`) khi dựng 3D, giữ `--compact`, RTK, handoff <= 300 token.";
        if self.chain_mode {
            let wf = self.workflows.iter().find(|w| w.id == self.active_workflow_id);
            let chain = wf.map_or_else(|| "S01_CONCEPT -> S12_SOUND_MASTER".to_string(), |w| w.stages.join(" -> "));
            return format!(
                "Sử dụng `craft-master-board` (`{}`).\nCHAIN_MODE = ON | WORKFLOW = \"{}\" ({})\n{}\nYêu cầu của người dùng: {}",
                self.board_source, self.active_workflow_id, chain, philosophy, user_text
            );
        }
        let st = self.stages.iter().find(|s| s.id == self.active_stage_id);
        let (agent, mcps) = st.map_or(("craft-master-board", String::new()), |s| (s.agent.as_str(), s.mcp.join(", ")));
        format!(
            "Sử dụng `craft-master-board` (`{}`).\nCHAIN_MODE = OFF | CHỈ CHẠY DUY NHẤT STAGE \"{}\" (@{}, MCP: {}).\n{}\nYêu cầu của người dùng: {}\nSau khi xuất artifact của stage này hãy DỪNG NGAY (không chạy stage tiếp theo).",
            self.board_source, self.active_stage_id, agent, mcps, philosophy, user_text
        )
    }

    #[cfg(not(target_arch = "wasm32"))]
    fn spawn_backend(&mut self, ctx: &egui::Context, prompt: String, msg_idx: usize) {
        let (tx, rx) = mpsc::channel();
        match spawn_agent_process(self.backend, &prompt) {
            Ok((mut child, pid)) => {
                self.running = Some(RunningJob { rx, pid });
                let ctx_clone = ctx.clone();
                std::thread::spawn(move || {
                    stream_child_output(&mut child, msg_idx, &tx, &ctx_clone);
                });
            }
            Err(err) => {
                if let Some(msg) = self.messages.get_mut(msg_idx) {
                    msg.text = format!("[Không khởi chạy được {:?}] {err}", self.backend);
                }
            }
        }
    }

    #[cfg(target_arch = "wasm32")]
    fn spawn_backend(&mut self, _ctx: &egui::Context, _prompt: String, msg_idx: usize) {
        if let Some(msg) = self.messages.get_mut(msg_idx) {
            msg.text = "Agent process execution is available in the desktop ArtCraft Launcher build.".to_string();
        }
    }

    fn stop_running(&mut self) {
        #[cfg(not(target_arch = "wasm32"))]
        if let Some(job) = self.running.take() {
            kill_process_tree(job.pid);
            self.messages.push(ChatMessage { role: ChatRole::System, text: "[Đã dừng tiến trình agent theo yêu cầu]".to_string() });
        }
    }
}

fn draw_chat_bubble(ui: &mut Ui, t: &Tokens, msg: &ChatMessage) {
    let (title, accent) = match msg.role {
        ChatRole::User => ("BẠN", t.accent_ink),
        ChatRole::Assistant => ("MASTER BOARD", t.good),
        ChatRole::System => ("HỆ THỐNG", t.muted),
    };
    egui::Frame::new()
        .fill(t.bg)
        .stroke(Stroke::new(1.0, t.line))
        .corner_radius(CornerRadius::ZERO)
        .inner_margin(egui::Margin::same(8))
        .show(ui, |ui| {
            ui.set_width(ui.available_width());
            widgets::hud(ui, title, accent);
            ui.add_space(2.0);
            ui.add(egui::Label::new(RichText::new(&msg.text).size(12.5).color(t.ink)).wrap().selectable(true));
        });
}

#[cfg(not(target_arch = "wasm32"))]
fn spawn_agent_process(backend: AgentBackend, prompt: &str) -> Result<(Child, u32), String> {
    let mut cmd = build_backend_command(backend, prompt)?;
    cmd.env("SOLIDCRAFT_MCP_COMPACT", "1");
    cmd.env("GEMINI_CLI_TRUST_WORKSPACE", "true");
    cmd.env("PYTHONIOENCODING", "utf-8");
    cmd.env("PYTHONUTF8", "1");
    cmd.stdout(Stdio::piped()).stderr(Stdio::piped());
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        cmd.creation_flags(0x0800_0000);
    }

    let uses_stdin = matches!(backend, AgentBackend::Gemini | AgentBackend::Claude);
    if uses_stdin {
        cmd.stdin(Stdio::piped());
    } else {
        cmd.stdin(Stdio::null());
    }

    let mut child = cmd.spawn().map_err(|e| format!("Spawn failed: {e}"))?;
    let pid = child.id();
    if uses_stdin && let Some(mut stdin) = child.stdin.take() {
        let bytes = prompt.as_bytes().to_vec();
        std::thread::spawn(move || {
            let _ = stdin.write_all(&bytes);
            let _ = stdin.flush();
        });
    }
    Ok((child, pid))
}

#[cfg(not(target_arch = "wasm32"))]
fn build_backend_command(backend: AgentBackend, prompt: &str) -> Result<Command, String> {
    match backend {
        AgentBackend::Gemini => build_gemini_command(),
        AgentBackend::Claude => build_claude_command(),
        AgentBackend::OpenCode => build_opencode_command(prompt),
        AgentBackend::Hermes => build_hermes_command(prompt),
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn build_gemini_command() -> Result<Command, String> {
    if let (Some(node), Some(js)) = (find_node_exe(), find_gemini_js()) {
        let mut c = Command::new(node);
        c.arg(js).args(["--yolo", "--output-format", "text"]);
        return Ok(c);
    }
    let mut c = Command::new("cmd");
    c.args(["/C", "gemini.cmd", "--yolo", "--output-format", "text"]);
    Ok(c)
}

#[cfg(not(target_arch = "wasm32"))]
fn build_claude_command() -> Result<Command, String> {
    let exe = find_claude_exe().ok_or_else(|| "Không tìm thấy claude.exe".to_string())?;
    let mut c = Command::new(exe);
    c.args(["-p", "--dangerously-skip-permissions"]);
    Ok(c)
}

#[cfg(not(target_arch = "wasm32"))]
fn build_opencode_command(prompt: &str) -> Result<Command, String> {
    if let Some(exe) = find_opencode_exe() {
        let mut c = Command::new(exe);
        c.args(["run", prompt]);
        return Ok(c);
    }
    let mut c = Command::new("cmd");
    c.args(["/C", "opencode.cmd", "run", prompt]);
    Ok(c)
}

#[cfg(not(target_arch = "wasm32"))]
fn build_hermes_command(prompt: &str) -> Result<Command, String> {
    let exe = find_hermes_exe().ok_or_else(|| "Không tìm thấy hermes.exe".to_string())?;
    let mut c = Command::new(exe);
    c.args(["chat", "--oneshot", "--yolo", "-q", prompt]);
    Ok(c)
}

#[cfg(not(target_arch = "wasm32"))]
fn stream_child_output(child: &mut Child, msg_idx: usize, tx: &Sender<WorkerEvent>, ctx: &egui::Context) {
    let out_handle = child.stdout.take().map(|stdout| spawn_pipe_reader(stdout, msg_idx, tx.clone(), ctx.clone()));
    let err_handle = child.stderr.take().map(|stderr| spawn_pipe_reader(stderr, msg_idx, tx.clone(), ctx.clone()));
    if let Some(h) = out_handle {
        let _ = h.join();
    }
    if let Some(h) = err_handle {
        let _ = h.join();
    }
    match child.wait() {
        Ok(status) => {
            let _ = tx.send(WorkerEvent::Finished { msg_idx, code: status.code() });
        }
        Err(err) => {
            let _ = tx.send(WorkerEvent::Failed { msg_idx, err: err.to_string() });
        }
    }
    ctx.request_repaint();
}

#[cfg(not(target_arch = "wasm32"))]
fn spawn_pipe_reader<R: std::io::Read + Send + 'static>(
    pipe: R,
    msg_idx: usize,
    tx: Sender<WorkerEvent>,
    ctx: egui::Context,
) -> std::thread::JoinHandle<()> {
    std::thread::spawn(move || {
        let reader = BufReader::new(pipe);
        for line in reader.lines().map_while(Result::ok) {
            if tx.send(WorkerEvent::OutputChunk { msg_idx, chunk: line }).is_err() {
                break;
            }
            ctx.request_repaint();
        }
    })
}

#[cfg(not(target_arch = "wasm32"))]
fn kill_process_tree(pid: u32) {
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        let _ = Command::new("taskkill")
            .args(["/F", "/T", "/PID", &pid.to_string()])
            .creation_flags(0x0800_0000)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
    #[cfg(not(windows))]
    {
        let _ = Command::new("kill").args(["-TERM", &pid.to_string()]).status();
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn first_existing(paths: &[PathBuf]) -> Option<PathBuf> {
    paths.iter().find(|p| p.is_file()).cloned()
}

#[cfg(not(target_arch = "wasm32"))]
fn user_dir_join(sub: &str) -> Option<PathBuf> {
    std::env::var_os("USERPROFILE")
        .or_else(|| std::env::var_os("HOME"))
        .map(|home| PathBuf::from(home).join(sub))
}

#[cfg(not(target_arch = "wasm32"))]
fn local_appdata_join(sub: &str) -> Option<PathBuf> {
    std::env::var_os("LOCALAPPDATA").map(|dir| PathBuf::from(dir).join(sub))
}

#[cfg(not(target_arch = "wasm32"))]
fn find_node_exe() -> Option<PathBuf> {
    let mut cands = Vec::new();
    if let Some(p) = local_appdata_join(r"hermes\tools\node-26.12.1-win32-x64\node.exe") {
        cands.push(p);
    }
    cands.push(PathBuf::from(r"C:\Program Files\nodejs\node.exe"));
    first_existing(&cands)
}

#[cfg(not(target_arch = "wasm32"))]
fn find_gemini_js() -> Option<PathBuf> {
    local_appdata_join(r"hermes\tools\node-26.12.1-win32-x64\node_modules\@google\gemini-cli\bundle\gemini.js").filter(|p| p.is_file())
}

#[cfg(not(target_arch = "wasm32"))]
fn find_opencode_exe() -> Option<PathBuf> {
    local_appdata_join(r"hermes\tools\node-26.12.1-win32-x64\node_modules\opencode-ai\bin\opencode.exe").filter(|p| p.is_file())
}

#[cfg(not(target_arch = "wasm32"))]
fn find_claude_exe() -> Option<PathBuf> {
    let mut cands = Vec::new();
    if let Some(p) = local_appdata_join(
        r"hermes\tools\node-26.12.1-win32-x64\node_modules\@agentclientprotocol\claude-agent-acp\node_modules\@anthropic-ai\claude-agent-sdk-win32-x64\claude.exe",
    ) {
        cands.push(p);
    }
    if let Some(p) = user_dir_join(r".local\bin\claude.exe") {
        cands.push(p);
    }
    first_existing(&cands)
}

#[cfg(not(target_arch = "wasm32"))]
fn find_hermes_exe() -> Option<PathBuf> {
    let mut cands = vec![PathBuf::from(r"D:\hermes\bin\hermes.exe")];
    if let Some(p) = local_appdata_join(r"hermes\bin\hermes.exe") {
        cands.push(p);
    }
    first_existing(&cands)
}

#[cfg(not(target_arch = "wasm32"))]
fn board_candidates() -> Vec<PathBuf> {
    let mut out = Vec::new();
    if let Some(p) = user_dir_join(r".gemini\antigravity\scratch\cad-agent-swarm\board\master-board.json") {
        out.push(p);
    }
    if let Some(p) = user_dir_join(r".cad-agent-swarm\board\master-board.json") {
        out.push(p);
    }
    if let Some(p) = local_appdata_join(r"SolidCraft\agent-chat\work\board\master-board.json") {
        out.push(p);
    }
    out
}

#[cfg(not(target_arch = "wasm32"))]
fn read_board_file() -> Option<(PathBuf, String)> {
    for p in board_candidates() {
        if let Ok(raw) = std::fs::read_to_string(&p) {
            return Some((p, raw.trim_start_matches('\u{feff}').to_string()));
        }
    }
    None
}

#[cfg(not(target_arch = "wasm32"))]
fn parse_board_json(raw: &str) -> Option<(Vec<StageItem>, Vec<WorkflowItem>, Option<String>)> {
    let root: serde_json::Value = serde_json::from_str(raw).ok()?;
    let stages = parse_stages_value(root.get("stages")?);
    let workflows = parse_workflows_value(root.get("workflows")?);
    let active = root.get("active_workflow").and_then(serde_json::Value::as_str).map(str::to_string);
    Some((stages, workflows, active))
}

#[cfg(not(target_arch = "wasm32"))]
fn parse_stages_value(val: &serde_json::Value) -> Vec<StageItem> {
    let Some(arr) = val.as_array() else { return Vec::new() };
    let mut out = Vec::new();
    for item in arr {
        let Some(id) = item.get("id").and_then(serde_json::Value::as_str) else { continue };
        let order = item.get("order").and_then(serde_json::Value::as_u64).unwrap_or(0) as u32;
        let name = item.get("name").and_then(serde_json::Value::as_str).unwrap_or(id);
        let agent = item.get("agent").and_then(serde_json::Value::as_str).unwrap_or("craft-master-board");
        let mcp = item
            .get("mcp")
            .and_then(serde_json::Value::as_array)
            .map(|m| m.iter().filter_map(serde_json::Value::as_str).map(str::to_string).collect())
            .unwrap_or_default();
        out.push(StageItem { id: id.to_string(), order, name: name.to_string(), agent: agent.to_string(), mcp });
    }
    out
}

#[cfg(not(target_arch = "wasm32"))]
fn parse_workflows_value(val: &serde_json::Value) -> Vec<WorkflowItem> {
    let Some(obj) = val.as_object() else { return Vec::new() };
    let mut map = BTreeMap::new();
    for (id, item) in obj {
        let label = item.get("label").and_then(serde_json::Value::as_str).unwrap_or(id);
        let stages = item
            .get("stages")
            .and_then(serde_json::Value::as_array)
            .map(|a| a.iter().filter_map(serde_json::Value::as_str).map(str::to_string).collect())
            .unwrap_or_default();
        map.insert(id.clone(), WorkflowItem { id: id.clone(), label: label.to_string(), stages });
    }
    map.into_values().collect()
}

fn open_dashboard_html() {
    #[cfg(not(target_arch = "wasm32"))]
    {
        for p in board_candidates() {
            if let Some(dash) = p.parent().map(|d| Path::new(d).join("dashboard.html"))
                && dash.is_file()
            {
                #[cfg(windows)]
                {
                    let _ = Command::new("explorer.exe").arg(&dash).spawn();
                }
                #[cfg(target_os = "macos")]
                {
                    let _ = Command::new("open").arg(&dash).spawn();
                }
                #[cfg(all(unix, not(target_os = "macos")))]
                {
                    let _ = Command::new("xdg-open").arg(&dash).spawn();
                }
                break;
            }
        }
    }
}

fn default_stages() -> Vec<StageItem> {
    let rows = [
        ("S01_CONCEPT", 1, "Concept & Creative Brief", "craft-concept-director", &["designcraft", "vectorcraft"][..]),
        ("S02_SPEC_CONTRACT", 2, "Engineering Spec, SOW & Contract", "craft-spec-contract", &["designcraft"][..]),
        ("S03_3D_MODEL", 3, "3D Parametric Modeling (Live Cursor)", "cad-swarm-orchestrator", &["solidcraft"][..]),
        ("S04_2D_SHOP_CNC", 4, "2D Shop Drawings & CNC DXF", "cad-sketcher-2d", &["cadcraft", "cadcraft-live"][..]),
        ("S05_BOM_COSTING", 5, "Material Take-off, BOM & Costing", "cad-export-bom", &["solidcraft", "cadcraft"][..]),
        ("S06_3D_RENDER", 6, "Studio Photorealistic 3D Render", "craft-studio-renderer", &["solidcraft"][..]),
        ("S07_PHOTO_POST", 7, "Photo Post-Processing & Key Visuals", "craft-photo-retoucher", &["photocraft"][..]),
        ("S08_VECTOR_BRAND", 8, "Vector Brand & Packaging Die-Lines", "craft-vector-brand", &["vectorcraft"][..]),
        ("S09_LAYOUT_DECK", 9, "Pitch Deck, Contract PDF & Posters", "craft-layout-publisher", &["designcraft"][..]),
        ("S10_VFX_MOTION", 10, "Motion Graphics & Exploded VFX", "craft-vfx-film-sound", &["effectcraft"][..]),
        ("S11_VIDEO_EDIT", 11, "Commercial Video Editing", "craft-vfx-film-sound", &["filmcraft"][..]),
        ("S12_SOUND_MASTER", 12, "SFX, Voiceover & Audio Mastering", "craft-vfx-film-sound", &["soundcraft"][..]),
    ];
    rows.into_iter()
        .map(|(id, order, name, agent, mcp)| StageItem {
            id: id.to_string(),
            order,
            name: name.to_string(),
            agent: agent.to_string(),
            mcp: mcp.iter().map(|s| (*s).to_string()).collect(),
        })
        .collect()
}

fn default_workflows() -> Vec<WorkflowItem> {
    vec![
        WorkflowItem {
            id: "full-product-launch".to_string(),
            label: "Full Product Launch (Concept -> CAD -> Render -> Video)".to_string(),
            stages: default_stages().into_iter().map(|s| s.id).collect(),
        },
        WorkflowItem {
            id: "cnc-manufacturing-pack".to_string(),
            label: "CNC & Manufacturing Pack (Spec -> 3D -> CNC DXF -> BOM)".to_string(),
            stages: ["S01_CONCEPT", "S02_SPEC_CONTRACT", "S03_3D_MODEL", "S04_2D_SHOP_CNC", "S05_BOM_COSTING"]
                .into_iter()
                .map(str::to_string)
                .collect(),
        },
        WorkflowItem {
            id: "ad-commercial-video".to_string(),
            label: "Commercial Ad Video (Concept -> Render -> VFX -> Film -> Sound)".to_string(),
            stages: ["S01_CONCEPT", "S06_3D_RENDER", "S07_PHOTO_POST", "S10_VFX_MOTION", "S11_VIDEO_EDIT", "S12_SOUND_MASTER"]
                .into_iter()
                .map(str::to_string)
                .collect(),
        },
    ]
}
