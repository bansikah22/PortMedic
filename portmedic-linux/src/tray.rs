use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread;

use crate::branding;
use global_hotkey::hotkey::{Code, HotKey, Modifiers};
use global_hotkey::{GlobalHotKeyEvent, GlobalHotKeyManager, HotKeyState};
use tray_icon::menu::{Menu, MenuEvent, MenuItem, PredefinedMenuItem, Submenu};
use tray_icon::{Icon, TrayIconBuilder};

#[derive(Debug, Clone, Copy)]
pub enum TrayCommand {
    ShowDashboard,
    Refresh,
    ShowLog,
    Quit,
    Terminate(i32),
    ForceTerminate(i32),
}

pub struct TrayHandle {
    pub commands: Arc<Mutex<Receiver<TrayCommand>>>,
    pub updates: Sender<TrayUpdate>,
}

#[derive(Debug, Clone)]
pub struct TrayUpdate {
    pub ports: Vec<(u16, i32, String)>,
}

pub fn start() -> TrayHandle {
    let (command_sender, command_receiver) = mpsc::channel();
    let (update_sender, update_receiver) = mpsc::channel();
    thread::spawn(move || run(command_sender, update_receiver));
    TrayHandle {
        commands: Arc::new(Mutex::new(command_receiver)),
        updates: update_sender,
    }
}

fn run(sender: Sender<TrayCommand>, update_receiver: Receiver<TrayUpdate>) {
    if gtk::init().is_err() {
        return;
    }

    let show = MenuItem::new("Show PortMedic", true, None);
    let refresh = MenuItem::new("Refresh Ports", true, None);
    let log = MenuItem::new("Activity Log", true, None);
    let quit = MenuItem::new("Quit", true, None);
    let kill_items: Vec<MenuItem> = (0..12)
        .map(|_| MenuItem::new("No active port", false, None))
        .collect();
    let force_kill_items: Vec<MenuItem> = (0..12)
        .map(|_| MenuItem::new("No active port", false, None))
        .collect();
    let active_ports = Submenu::new("Active Ports", true);
    let kill_refs: Vec<&dyn tray_icon::menu::IsMenuItem> = kill_items
        .iter()
        .map(|item| item as &dyn tray_icon::menu::IsMenuItem)
        .collect();
    let _ = active_ports.append_items(&kill_refs);
    let force_kill_ports = Submenu::new("Force Kill Active Ports", true);
    let force_kill_refs: Vec<&dyn tray_icon::menu::IsMenuItem> = force_kill_items
        .iter()
        .map(|item| item as &dyn tray_icon::menu::IsMenuItem)
        .collect();
    let _ = force_kill_ports.append_items(&force_kill_refs);
    let menu = Menu::new();
    let _ = menu.append_items(&[
        &show,
        &refresh,
        &log,
        &active_ports,
        &force_kill_ports,
        &PredefinedMenuItem::separator(),
        &quit,
    ]);

    let icon = branding::rgba()
        .and_then(|(rgba, width, height)| Icon::from_rgba(rgba, width, height).ok());
    let _tray = TrayIconBuilder::new()
        .with_menu(Box::new(menu))
        .with_icon(icon.unwrap_or_else(|| Icon::from_rgba(vec![0; 4], 1, 1).unwrap()))
        .with_title("PortMedic")
        .build();

    // Ctrl+Shift+P shows the dashboard, mirroring the Carbon hotkey on macOS.
    // Kept alive for the loop's lifetime; dropping it would unregister the shortcut.
    let show_shortcut = HotKey::new(Some(Modifiers::CONTROL | Modifiers::SHIFT), Code::KeyP);
    let _hotkey_manager = GlobalHotKeyManager::new()
        .inspect(|manager| {
            let _ = manager.register(show_shortcut);
        })
        .ok();

    let ids = [
        (show.id(), TrayCommand::ShowDashboard),
        (refresh.id(), TrayCommand::Refresh),
        (log.id(), TrayCommand::ShowLog),
        (quit.id(), TrayCommand::Quit),
    ];
    let mut current_ports = Vec::new();
    loop {
        while let Ok(update) = update_receiver.try_recv() {
            current_ports = update.ports.clone();
            for (index, item) in kill_items.iter().enumerate() {
                if let Some((port, pid, name)) = update.ports.get(index) {
                    item.set_text(format!("Stop {port} · {name} (PID {pid})"));
                    item.set_enabled(true);
                    force_kill_items[index].set_text(format!("Kill {port} · {name} (PID {pid})"));
                    force_kill_items[index].set_enabled(true);
                } else {
                    item.set_text("No active port");
                    item.set_enabled(false);
                    force_kill_items[index].set_text("No active port");
                    force_kill_items[index].set_enabled(false);
                }
            }
        }
        while let Ok(event) = GlobalHotKeyEvent::receiver().try_recv() {
            if event.id == show_shortcut.id() && event.state == HotKeyState::Pressed {
                let _ = sender.send(TrayCommand::ShowDashboard);
            }
        }
        while let Ok(event) = MenuEvent::receiver().try_recv() {
            if let Some((_, command)) = ids.iter().find(|(id, _)| *id == event.id()) {
                if sender.send(*command).is_err() {
                    return;
                }
            } else if let Some(index) = kill_items.iter().position(|item| item.id() == event.id()) {
                if let Some((_, pid, _)) = current_ports.get(index) {
                    let _ = sender.send(TrayCommand::Terminate(*pid));
                }
            } else if let Some(index) = force_kill_items
                .iter()
                .position(|item| item.id() == event.id())
            {
                if let Some((_, pid, _)) = current_ports.get(index) {
                    let _ = sender.send(TrayCommand::ForceTerminate(*pid));
                }
            }
        }
        while gtk::events_pending() {
            gtk::main_iteration();
        }
        thread::sleep(std::time::Duration::from_millis(50));
    }
}
