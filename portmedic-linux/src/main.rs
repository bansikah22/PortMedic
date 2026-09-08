//! PortMedic for Linux — entry point.
//!
//! This is a structural skeleton only. Real `/proc` scanning, process
//! termination, and iced UI wiring are implemented in a follow-up change
//! once this scaffold is validated on Linux CI.

// Scaffold stage: modules aren't wired together yet, so unused items are expected; remove once real usage lands.
#![allow(dead_code)]

mod model;
mod proc_scanner;
mod process_control;

fn main() -> iced::Result {
    iced::application("PortMedic", PortMedic::update, PortMedic::view).run_with(PortMedic::new)
}

#[derive(Default)]
struct PortMedic {
    ports: Vec<model::PortProcessInfo>,
}

#[derive(Debug, Clone)]
enum Message {
    Refresh,
    Refreshed(Vec<model::PortProcessInfo>),
}

impl PortMedic {
    fn new() -> (Self, iced::Task<Message>) {
        (Self::default(), iced::Task::none())
    }

    fn update(&mut self, message: Message) -> iced::Task<Message> {
        match message {
            Message::Refresh => iced::Task::none(),
            Message::Refreshed(ports) => {
                self.ports = ports;
                iced::Task::none()
            }
        }
    }

    fn view(&self) -> iced::Element<'_, Message> {
        // Placeholder: table/sidebar layout to be implemented next,
        // matching the macOS dashboard's information architecture.
        iced::widget::text("PortMedic (Linux) — work in progress").into()
    }
}
