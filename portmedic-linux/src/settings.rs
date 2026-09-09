//! Persisted user preferences. Mirrors `AppearancePreference.swift` plus the
//! settings-storage half of `WatchedPortStoring` (same JSON-file approach).
use std::fs;
use std::io;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum AppearancePreference {
    Light,
    Dark,
    #[default]
    System,
}

impl AppearancePreference {
    pub const ALL: [AppearancePreference; 3] = [Self::Light, Self::Dark, Self::System];

    pub fn label(self) -> &'static str {
        match self {
            Self::Light => "Light",
            Self::Dark => "Dark",
            Self::System => "System",
        }
    }

    /// `System` follows the desktop environment's light/dark setting, falling
    /// back to dark when it can't be detected (e.g. no supported portal running).
    pub fn theme(self) -> iced::Theme {
        match self {
            Self::Light => iced::Theme::Light,
            Self::Dark => iced::Theme::Dark,
            Self::System => match dark_light::detect() {
                dark_light::Mode::Light => iced::Theme::Light,
                dark_light::Mode::Dark | dark_light::Mode::Default => iced::Theme::Dark,
            },
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, Default)]
pub struct Settings {
    #[serde(default)]
    pub appearance: AppearancePreference,
}

fn storage_path() -> PathBuf {
    std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            std::env::var_os("HOME")
                .map(|home| PathBuf::from(home).join(".config"))
                .unwrap_or_else(|| PathBuf::from("."))
        })
        .join("portmedic")
        .join("settings.json")
}

pub fn load() -> Settings {
    fs::read(storage_path())
        .ok()
        .and_then(|data| serde_json::from_slice(&data).ok())
        .unwrap_or_default()
}

pub fn save(settings: &Settings) -> io::Result<()> {
    let path = storage_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let data = serde_json::to_vec_pretty(settings).map_err(io::Error::other)?;
    fs::write(path, data)
}
