use std::path::{Component, Path};

use anyhow::{Context, Result, bail};
use include_dir::{Dir, include_dir};

use crate::{
    cli::Profile,
    model::{BUILDER_VERSION, BuilderManifest, ProfileManifest},
};

pub static TEMPLATES: Dir<'_> = include_dir!("$CARGO_MANIFEST_DIR/../../assets/templates");
pub static SKILLS: Dir<'_> = include_dir!("$CARGO_MANIFEST_DIR/../../skills");
const MANIFEST_JSON: &str = include_str!("../../../builder.manifest.json");
const PROMETHEUS_CONTRACT_JSON: &str =
    include_str!("../../../compatibility/prometheus-control-plane.json");
const UAR_CONTRACT_JSON: &str = include_str!("../../../compatibility/uar-runtime.json");
const ACTIVATION_MANIFEST_JSON: &str = include_str!("../../../templates/activation-manifest.json");

pub fn manifest() -> Result<BuilderManifest> {
    let manifest: BuilderManifest =
        serde_json::from_str(MANIFEST_JSON).context("embedded Builder manifest is invalid")?;
    if manifest.schema_version != 1 {
        bail!(
            "unsupported embedded Builder manifest schema {}",
            manifest.schema_version
        );
    }
    if manifest.package.version != BUILDER_VERSION {
        bail!(
            "crate version {} differs from manifest version {}",
            BUILDER_VERSION,
            manifest.package.version
        );
    }
    Ok(manifest)
}

pub fn profile(manifest: &BuilderManifest, profile: Profile) -> Result<&ProfileManifest> {
    manifest
        .profiles
        .get(profile.as_str())
        .with_context(|| format!("profile {} is not packaged", profile.as_str()))
}

pub fn prometheus_contract() -> Result<serde_json::Value> {
    serde_json::from_str(PROMETHEUS_CONTRACT_JSON)
        .context("embedded Prometheus compatibility contract is invalid")
}

pub fn uar_contract() -> Result<serde_json::Value> {
    serde_json::from_str(UAR_CONTRACT_JSON)
        .context("embedded UAR compatibility contract is invalid")
}

pub fn activation_manifest() -> &'static [u8] {
    ACTIVATION_MANIFEST_JSON.as_bytes()
}

pub fn validate_relative_path(path: &Path) -> Result<()> {
    if path.as_os_str().is_empty() || path.is_absolute() {
        bail!(
            "generated path must be non-empty and relative: {}",
            path.display()
        );
    }
    for component in path.components() {
        if matches!(
            component,
            Component::ParentDir | Component::RootDir | Component::Prefix(_)
        ) {
            bail!("generated path escapes the destination: {}", path.display());
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use super::{manifest, validate_relative_path};

    #[test]
    fn embedded_manifest_matches_crate_version() {
        let manifest = manifest().expect("manifest");
        assert_eq!(manifest.skills.len(), 29);
        assert_eq!(manifest.supported_harnesses.len(), 4);
    }

    #[test]
    fn rejects_escaping_paths() {
        assert!(validate_relative_path(Path::new("../secret")).is_err());
        assert!(validate_relative_path(Path::new("/tmp/file")).is_err());
        assert!(validate_relative_path(Path::new("src/main.rs")).is_ok());
    }
}
