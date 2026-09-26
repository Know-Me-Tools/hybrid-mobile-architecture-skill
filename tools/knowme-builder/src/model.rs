use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use crate::cli::{GenerationMode, Profile};

pub const BUILDER_VERSION: &str = env!("CARGO_PKG_VERSION");
pub const PROMETHEUS_PACKAGE_VERSION: &str = "1.7.0";
pub const PROMETHEUS_CONTRACT: &str = "2.0.0";

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BuilderManifest {
    pub schema_version: u32,
    pub package: PackageManifest,
    pub profiles: BTreeMap<String, ProfileManifest>,
    pub skills: Vec<String>,
    pub supported_harnesses: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct PackageManifest {
    pub id: String,
    pub version: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProfileManifest {
    pub surfaces: Vec<String>,
    pub uar_mode: String,
    pub runnable_vertical_slice: bool,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProjectManifest {
    pub schema_version: u32,
    pub profile: Profile,
    pub builder_version: String,
    pub required_prometheus_contract: String,
    pub uar_mode: String,
    pub enabled_surfaces: Vec<String>,
    pub generation_mode: GenerationMode,
    pub policy_overlay_path: String,
    pub unsupported_surfaces: Vec<String>,
    /// Stable rendering identity, independent of the destination directory.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub app_name: Option<String>,
}

#[derive(Debug, Default, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GeneratedLock {
    pub schema_version: u32,
    pub builder_version: String,
    pub files: Vec<GeneratedFile>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GeneratedFile {
    pub path: String,
    pub template_id: String,
    pub source_digest: String,
    pub last_installed_digest: String,
    pub ownership: Ownership,
    pub version: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
pub enum Ownership {
    Builder,
    User,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CommandResult {
    pub ok: bool,
    pub operation: String,
    pub changed: bool,
    pub path: Option<String>,
    pub profile: Option<String>,
    pub actions: Vec<String>,
    pub conflicts: Vec<String>,
    pub warnings: Vec<String>,
}

impl CommandResult {
    pub fn new(operation: impl Into<String>) -> Self {
        Self {
            ok: true,
            operation: operation.into(),
            changed: false,
            path: None,
            profile: None,
            actions: Vec::new(),
            conflicts: Vec::new(),
            warnings: Vec::new(),
        }
    }
}
