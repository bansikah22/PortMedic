//! PortMedic for Linux — entry point.
//!
mod framework_detection;
mod login_item;
mod model;
mod proc_scanner;
mod process_control;
mod quick_actions;
mod settings;
mod tray;
mod watched_ports;

fn main() -> iced::Result {
    iced::application("PortMedic", PortMedic::update, PortMedic::view)
        .theme(PortMedic::theme)
        .run_with(PortMedic::new)
}

struct PortMedic {
    ports: Vec<model::PortProcessInfo>,
    force_kill_pid: Option<i32>,
    status: String,
    search: String,
    selected_pid: Option<i32>,
    log: Vec<String>,
    show_log: bool,
    watched_ports: Vec<watched_ports::WatchedPort>,
    show_watched: bool,
    show_settings: bool,
    auto_refresh: bool,
    launch_at_login: bool,
    appearance: settings::AppearancePreference,
    tray_receiver: std::sync::Arc<std::sync::Mutex<std::sync::mpsc::Receiver<tray::TrayCommand>>>,
    tray_updates: std::sync::mpsc::Sender<tray::TrayUpdate>,
}

impl Default for PortMedic {
    fn default() -> Self {
        let tray = tray::start();
        Self {
            ports: Vec::new(),
            force_kill_pid: None,
            status: String::new(),
            search: String::new(),
            selected_pid: None,
            log: Vec::new(),
            show_log: false,
            watched_ports: Vec::new(),
            show_watched: false,
            show_settings: false,
            auto_refresh: false,
            launch_at_login: false,
            appearance: settings::AppearancePreference::default(),
            tray_receiver: tray.commands,
            tray_updates: tray.updates,
        }
    }
}

#[derive(Debug, Clone)]
enum Message {
    Refresh,
    Refreshed(Vec<model::PortProcessInfo>),
    SearchChanged(String),
    Select(i32),
    ShowDashboard,
    ShowLog,
    ShowWatched,
    ShowSettings,
    ToggleAutoRefresh(bool),
    ToggleLaunchAtLogin(bool),
    SetAppearance(settings::AppearancePreference),
    CopyToClipboard(String),
    OpenInBrowser(String),
    ToggleWatched(u16),
    Terminate(i32),
    RequestForceKill(i32),
    CancelForceKill,
    ForceKill(i32),
    ActionCompleted(String),
    TrayPolled,
}

impl PortMedic {
    fn new() -> (Self, iced::Task<Message>) {
        let state = Self {
            watched_ports: watched_ports::load().unwrap_or_default(),
            launch_at_login: login_item::is_enabled(),
            appearance: settings::load().appearance,
            ..Self::default()
        };
        (
            state,
            iced::Task::batch([iced::Task::done(Message::Refresh), Self::poll_tray()]),
        )
    }

    fn poll_tray() -> iced::Task<Message> {
        iced::Task::perform(
            async { tokio::time::sleep(std::time::Duration::from_millis(100)).await },
            |_| Message::TrayPolled,
        )
    }

    fn update(&mut self, message: Message) -> iced::Task<Message> {
        match message {
            Message::Refresh => iced::Task::perform(
                async { proc_scanner::scan().unwrap_or_default() },
                Message::Refreshed,
            ),
            Message::Refreshed(ports) => {
                self.log
                    .push(format!("Scanned {} active ports", ports.len()));
                let _ = self.tray_updates.send(tray::TrayUpdate {
                    ports: ports
                        .iter()
                        .take(12)
                        .map(|port| (port.port, port.pid, port.process_name.clone()))
                        .collect(),
                });
                self.ports = ports;
                iced::Task::none()
            }
            Message::SearchChanged(search) => {
                self.search = search;
                iced::Task::none()
            }
            Message::Select(pid) => {
                self.selected_pid = Some(pid);
                iced::Task::none()
            }
            Message::ShowDashboard => {
                self.show_log = false;
                self.show_watched = false;
                self.show_settings = false;
                iced::Task::none()
            }
            Message::ShowLog => {
                self.show_log = true;
                self.show_watched = false;
                self.show_settings = false;
                iced::Task::none()
            }
            Message::ShowWatched => {
                self.show_watched = true;
                self.show_log = false;
                self.show_settings = false;
                iced::Task::none()
            }
            Message::ShowSettings => {
                self.show_settings = true;
                self.show_log = false;
                self.show_watched = false;
                iced::Task::none()
            }
            Message::ToggleAutoRefresh(enabled) => {
                self.auto_refresh = enabled;
                iced::Task::none()
            }
            Message::ToggleLaunchAtLogin(enabled) => {
                match login_item::set_enabled(enabled) {
                    Ok(()) => self.launch_at_login = enabled,
                    Err(error) => self.status = format!("Could not update autostart: {error}"),
                }
                iced::Task::none()
            }
            Message::SetAppearance(preference) => {
                self.appearance = preference;
                let _ = settings::save(&settings::Settings {
                    appearance: preference,
                });
                iced::Task::none()
            }
            Message::CopyToClipboard(value) => iced::clipboard::write(value),
            Message::OpenInBrowser(url) => iced::Task::perform(
                async move { quick_actions::open_in_browser(&url) },
                |opened| {
                    Message::ActionCompleted(if opened {
                        "Opened in browser".to_owned()
                    } else {
                        "Could not find a browser (xdg-open missing)".to_owned()
                    })
                },
            ),
            Message::ToggleWatched(port) => {
                if let Some(index) = self
                    .watched_ports
                    .iter()
                    .position(|watched| watched.port == port)
                {
                    self.watched_ports.remove(index);
                } else {
                    self.watched_ports.push(watched_ports::WatchedPort { port });
                    self.watched_ports.sort_by_key(|watched| watched.port);
                }
                let _ = watched_ports::save(&self.watched_ports);
                iced::Task::none()
            }
            Message::Terminate(pid) => iced::Task::perform(
                async move {
                    process_control::terminate(pid)
                        .map(|_| format!("Sent SIGTERM to process {pid}"))
                        .unwrap_or_else(|error| error.to_string())
                },
                Message::ActionCompleted,
            ),
            Message::RequestForceKill(pid) => {
                self.force_kill_pid = Some(pid);
                iced::Task::none()
            }
            Message::CancelForceKill => {
                self.force_kill_pid = None;
                iced::Task::none()
            }
            Message::ForceKill(pid) => {
                self.force_kill_pid = None;
                iced::Task::perform(
                    async move {
                        process_control::force_terminate(pid)
                            .map(|_| format!("Sent SIGKILL to process {pid}"))
                            .unwrap_or_else(|error| error.to_string())
                    },
                    Message::ActionCompleted,
                )
            }
            Message::ActionCompleted(status) => {
                self.log.push(status.clone());
                self.status = status;
                iced::Task::done(Message::Refresh)
            }
            Message::TrayPolled => {
                let command = self
                    .tray_receiver
                    .lock()
                    .ok()
                    .and_then(|receiver| receiver.try_recv().ok());
                let next = match command {
                    Some(tray::TrayCommand::ShowDashboard) => Message::ShowDashboard,
                    Some(tray::TrayCommand::Refresh) => Message::Refresh,
                    Some(tray::TrayCommand::ShowLog) => Message::ShowLog,
                    Some(tray::TrayCommand::Terminate(pid)) => Message::Terminate(pid),
                    Some(tray::TrayCommand::ForceTerminate(pid)) => Message::ForceKill(pid),
                    Some(tray::TrayCommand::Quit) => {
                        std::process::exit(0);
                    }
                    None => Message::TrayPolled,
                };
                iced::Task::batch([iced::Task::done(next), Self::poll_tray()])
            }
        }
    }

    fn theme(&self) -> iced::Theme {
        self.appearance.theme()
    }

    fn view(&self) -> iced::Element<'_, Message> {
        use iced::widget::{
            button, column, container, mouse_area, row, scrollable, text, text_input,
        };
        use iced::{Alignment, Length};

        let query = self.search.trim().to_lowercase();
        let visible_ports = self.ports.iter().filter(|port| {
            query.is_empty()
                || port.port.to_string().contains(&query)
                || port.pid.to_string().contains(&query)
                || port.user.contains(&query)
                || port.process_name.to_lowercase().contains(&query)
                || format!("{:?}", port.protocol)
                    .to_lowercase()
                    .contains(&query)
        });
        let visible_count = visible_ports.clone().count();

        let rows = visible_ports
            .map(|port| {
                let protocol = format!("{:?}", port.protocol).to_uppercase();
                let framework = framework_detection::detect(port)
                    .map(|label| format!(" · {label}"))
                    .unwrap_or_default();
                let identity = column![
                    text(format!("{}{}", port.process_name, framework)).size(17),
                    text(format!("PID {}  ·  UID {}", port.pid, port.user)).size(13)
                ]
                .spacing(4)
                .width(Length::Fill);

                let actions = row![
                    button(
                        if self
                            .watched_ports
                            .iter()
                            .any(|watched| watched.port == port.port)
                        {
                            "★"
                        } else {
                            "☆"
                        }
                    )
                    .on_press(Message::ToggleWatched(port.port))
                    .style(iced::widget::button::text)
                    .padding([6, 9]),
                    button("Stop")
                        .on_press(Message::Terminate(port.pid))
                        .style(iced::widget::button::secondary)
                        .padding([6, 12]),
                    button("Kill")
                        .on_press(Message::RequestForceKill(port.pid))
                        .style(iced::widget::button::danger)
                        .padding([6, 12])
                ]
                .spacing(8);

                let port_label = column![text(port.port).size(20), text(protocol).size(11)]
                    .spacing(2)
                    .align_x(Alignment::Start)
                    .width(Length::Fixed(72.0));

                let row_content = container(
                    row![port_label, identity, actions]
                        .align_y(Alignment::Center)
                        .spacing(16)
                        .width(Length::Fill),
                )
                .padding([14, 12])
                .width(Length::Fill)
                .height(Length::Fixed(68.0));

                mouse_area(row_content).on_press(Message::Select(port.pid))
            })
            .fold(column![], |rows, row| rows.push(row));

        let confirmation = self.force_kill_pid.map(|pid| {
            row![
                text(format!("Force kill PID {pid}? This cannot be undone.")),
                button("Cancel")
                    .on_press(Message::CancelForceKill)
                    .style(iced::widget::button::secondary),
                button("Confirm Force Kill")
                    .on_press(Message::ForceKill(pid))
                    .style(iced::widget::button::danger)
            ]
            .spacing(12)
        });

        let header = container(
            row![
                text("PORT").size(12),
                text("PROCESS").size(12),
                text("ACTIONS").size(12)
            ]
            .spacing(16)
            .width(Length::Fill),
        )
        .padding([8, 12])
        .width(Length::Fill);

        let detail = self.selected_pid.and_then(|pid| {
            self.ports.iter().find(|port| port.pid == pid).map(|port| {
                let mut details = column![
                    text("PROCESS DETAILS").size(11),
                    text(&port.process_name).size(22),
                    text(format!("PID {}", port.pid)).size(14),
                    text(format!("Port {}  ·  {:?}", port.port, port.protocol)).size(14),
                    text(format!("User ID {}", port.user)).size(14),
                ]
                .spacing(10);
                if let Some(exe_path) = &port.exe_path {
                    details = details.push(text(format!("Executable: {exe_path}")).size(12));
                }
                if let Some(working_dir) = &port.working_dir {
                    details = details.push(text(format!("Working dir: {working_dir}")).size(12));
                }
                details = details.push(
                    row![
                        button("Copy PID")
                            .on_press(Message::CopyToClipboard(port.pid.to_string()))
                            .style(iced::widget::button::text)
                            .padding([7, 12]),
                        button("Open in browser")
                            .on_press(Message::OpenInBrowser(format!(
                                "http://localhost:{}",
                                port.port
                            )))
                            .style(iced::widget::button::text)
                            .padding([7, 12])
                    ]
                    .spacing(6),
                );
                details = details.push(
                    button("Stop process")
                        .on_press(Message::Terminate(port.pid))
                        .style(iced::widget::button::secondary)
                        .padding([7, 12]),
                );
                container(details).padding(18).width(Length::Fixed(230.0))
            })
        });

        let list = if visible_count == 0 {
            container(
                column![
                    text(if self.ports.is_empty() {
                        "No listening ports found"
                    } else {
                        "No ports match your search"
                    })
                    .size(18),
                    text(if self.ports.is_empty() {
                        "Refresh to scan the local machine again."
                    } else {
                        "Try a different port, process, PID, or protocol."
                    })
                    .size(14)
                ]
                .align_x(Alignment::Center)
                .spacing(8),
            )
            .width(Length::Fill)
            .center_x(Length::Fill)
            .padding(48)
        } else {
            container(column![header, scrollable(rows).height(Length::Fill)])
                .width(Length::Fill)
                .height(Length::Fill)
        };

        let search_field = text_input("Search ports, PID...", &self.search)
            .on_input(Message::SearchChanged)
            .padding([9, 12])
            .width(Length::Fixed(280.0));

        let mut dashboard = column![
            row![
                column![
                    text("Active Ports").size(28),
                    text("Find and free local development ports").size(13)
                ]
                .spacing(3)
                .width(Length::Fill),
                search_field,
                button("Refresh")
                    .on_press(Message::Refresh)
                    .padding([8, 16])
            ]
            .align_y(Alignment::Center)
            .spacing(20),
            text(format!("{} active ports", self.ports.len())).size(14),
        ];
        dashboard = dashboard.spacing(12).padding([22, 28]);
        if !query.is_empty() {
            dashboard =
                dashboard.push(text(format!("Showing {visible_count} matching sockets")).size(13));
        }
        if !self.status.is_empty() {
            dashboard = dashboard.push(
                container(text(&self.status).size(13))
                    .padding([8, 12])
                    .width(Length::Fill),
            );
        }
        if let Some(confirmation) = confirmation {
            dashboard = dashboard.push(container(confirmation).padding(12).width(Length::Fill));
        }
        let workspace = if let Some(detail) = detail {
            row![list, detail].spacing(1).height(Length::Fill)
        } else {
            row![list].height(Length::Fill)
        };
        dashboard = dashboard.push(workspace);

        let log_panel = column![
            text("Activity Log").size(28),
            text("Recent scans and process actions").size(13),
            scrollable(self.log.iter().rev().fold(column![], |items, entry| {
                items.push(container(text(entry)).padding([12, 14]).width(Length::Fill))
            }))
            .height(Length::Fill)
        ]
        .spacing(16)
        .padding([22, 28])
        .height(Length::Fill);

        let watched_panel = column![
            text("Watched Ports").size(28),
            text("Keep an eye on the ports you use most").size(13),
            scrollable(self.watched_ports.iter().fold(column![], |items, watched| {
                let active = self.ports.iter().find(|port| port.port == watched.port);
                let status = active
                    .map(|port| format!("Active · {} (PID {})", port.process_name, port.pid))
                    .unwrap_or_else(|| "Not active".to_owned());
                items.push(
                    container(
                        row![
                            column![text(watched.port).size(20), text(status).size(13)]
                                .spacing(3)
                                .width(Length::Fill),
                            button("Remove")
                                .on_press(Message::ToggleWatched(watched.port))
                                .style(iced::widget::button::secondary)
                                .padding([6, 10])
                        ]
                        .align_y(Alignment::Center)
                        .spacing(12),
                    )
                    .padding([10, 12])
                    .width(Length::Fill),
                )
            }))
            .height(Length::Fill)
        ]
        .spacing(16)
        .padding([22, 28])
        .height(Length::Fill);

        let settings_panel = column![
            text("Settings").size(28),
            text("Configure how PortMedic behaves on Linux").size(13),
            container(
                column![
                    text("General").size(18),
                    iced::widget::checkbox("Auto-refresh ports", self.auto_refresh)
                        .on_toggle(Message::ToggleAutoRefresh),
                    text("Keep the active port list updated while PortMedic is open.")
                        .size(13),
                    iced::widget::checkbox("Launch at login", self.launch_at_login)
                        .on_toggle(Message::ToggleLaunchAtLogin),
                    text("Adds or removes an XDG autostart entry for your desktop session.")
                        .size(13)
                ]
                .spacing(10),
            )
            .padding(18)
            .width(Length::Fill),
            container(
                column![
                    text("Appearance").size(18),
                    row(settings::AppearancePreference::ALL.iter().map(|preference| {
                        iced::widget::radio(
                            preference.label(),
                            *preference,
                            Some(self.appearance),
                            Message::SetAppearance,
                        )
                        .into()
                    }))
                    .spacing(16)
                ]
                .spacing(10),
            )
            .padding(18)
            .width(Length::Fill),
            container(
                column![
                    text("Desktop integration").size(18),
                    text("System tray is active. Press Ctrl+Shift+P from anywhere to jump to the dashboard.")
                        .size(13)
                ]
                .spacing(8),
            )
            .padding(18)
            .width(Length::Fill)
        ]
        .spacing(16)
        .padding([22, 28])
        .height(Length::Fill);

        let content = if self.show_log {
            log_panel
        } else if self.show_watched {
            watched_panel
        } else if self.show_settings {
            settings_panel
        } else {
            dashboard
        };

        let navigation = column![
            button("▦   Dashboard")
                .on_press(Message::ShowDashboard)
                .style(iced::widget::button::text)
                .padding([10, 12])
                .width(Length::Fill),
            button("☆   Watched Ports")
                .on_press(Message::ShowWatched)
                .style(iced::widget::button::text)
                .padding([10, 12])
                .width(Length::Fill),
            button("◷   Activity Log")
                .on_press(Message::ShowLog)
                .style(iced::widget::button::text)
                .padding([10, 12])
                .width(Length::Fill),
            button("⚙   Settings")
                .on_press(Message::ShowSettings)
                .style(iced::widget::button::text)
                .padding([10, 12])
                .width(Length::Fill)
        ]
        .spacing(4);

        let sidebar = container(
            column![
                text("PortMedic").size(22),
                text("v1.0.0").size(12),
                navigation,
                iced::widget::Space::with_height(Length::Fill),
                column![text("Help").size(13), text("Feedback").size(13)].spacing(10)
            ]
            .spacing(8)
            .padding(18)
            .height(Length::Fill),
        )
        .width(Length::Fixed(210.0))
        .height(Length::Fill);

        container(row![sidebar, content])
            .width(Length::Fill)
            .height(Length::Fill)
            .into()
    }
}
