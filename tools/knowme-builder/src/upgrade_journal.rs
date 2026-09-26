//! Recovery for one managed-file upgrade. Semantic version migrations remain
//! explicit engine policy; a journal does not make an unsupported version valid.
use crate::{
    engine::{atomic_write, ensure_no_symlinks},
    model::{BUILDER_VERSION, CommandResult},
};
use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::{
    collections::BTreeSet,
    fs::{self, File, OpenOptions},
    path::{Path, PathBuf},
};

const JOURNAL: &str = ".knowme-builder/upgrade-journal.json";
#[derive(Deserialize, Serialize, PartialEq)]
#[serde(rename_all = "kebab-case")]
enum Status {
    Prepared,
    Committed,
    RollingBack,
    RolledBack,
}
#[derive(Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct Entry {
    path: String,
    before: Option<Vec<u8>>,
    after_digest: String,
}
#[derive(Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct Journal {
    schema_version: u32,
    builder_version: String,
    migration_id: String,
    status: Status,
    entries: Vec<Entry>,
}
fn hash(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}
fn current(path: &Path) -> Result<Option<Vec<u8>>> {
    match fs::read(path) {
        Ok(bytes) => Ok(Some(bytes)),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(e) => Err(e.into()),
    }
}
fn validate_path(root: &Path, path: &str, paths: &mut BTreeSet<String>) -> Result<()> {
    ensure_no_symlinks(root, Path::new(path))?;
    if path.contains(['\\', ':'])
        || path
            .split('/')
            .any(|part| part.is_empty() || part == "." || part == "..")
    {
        bail!("non-canonical upgrade journal path");
    }
    let key = path.to_lowercase();
    if !paths.insert(key.clone()) || key == JOURNAL || key == ".knowme-builder/upgrade.lock" {
        bail!("invalid duplicate or reserved journal path");
    }
    Ok(())
}
fn load(root: &Path) -> Result<Option<Journal>> {
    ensure_no_symlinks(root, Path::new(JOURNAL))?;
    let Some(bytes) = current(&root.join(JOURNAL))? else {
        return Ok(None);
    };
    let journal: Journal =
        serde_json::from_slice(&bytes).context("invalid upgrade recovery journal")?;
    if journal.schema_version != 1 {
        bail!("unsupported upgrade journal schema");
    }
    let mut paths = BTreeSet::new();
    for entry in &journal.entries {
        validate_path(root, &entry.path, &mut paths)?;
    }
    Ok(Some(journal))
}
fn save(root: &Path, journal: &Journal) -> Result<()> {
    atomic_write(
        &root.join(JOURNAL),
        format!("{}\n", serde_json::to_string_pretty(journal)?).as_bytes(),
    )
}
pub(crate) fn lock(root: &Path) -> Result<File> {
    let relative = Path::new(".knowme-builder/upgrade.lock");
    ensure_no_symlinks(root, relative)?;
    // Do not create adoption state for an unrecognized application.
    if !root.join(".knowme-builder/project.toml").is_file() {
        bail!("missing adoption state");
    }
    let lock = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(root.join(relative))?;
    lock.try_lock()
        .context("another upgrade or rollback is running")?;
    Ok(lock)
}
pub(crate) fn ensure_ready(root: &Path) -> Result<()> {
    if let Some(journal) = load(root)?
        && matches!(journal.status, Status::Prepared | Status::RollingBack)
    {
        bail!("interrupted managed-file upgrade; run upgrade --rollback before retrying");
    }
    Ok(())
}
pub(crate) type PlannedWrite = (PathBuf, Option<Vec<u8>>, Vec<u8>);
pub(crate) fn apply(
    root: &Path,
    writes: Vec<PlannedWrite>,
    guards: &[(&Path, &[u8])],
) -> Result<bool> {
    if writes.is_empty() {
        return Ok(false);
    }
    let _guard = lock(root)?;
    ensure_ready(root)?;
    for (path, expected) in guards {
        ensure_no_symlinks(root, path.strip_prefix(root)?)?;
        if fs::read(path)? != *expected {
            bail!(
                "control state changed after upgrade preflight: {}",
                path.display()
            );
        }
    }
    let mut entries = Vec::new();
    let mut paths = BTreeSet::new();
    for (path, before, bytes) in &writes {
        let relative = path
            .strip_prefix(root)?
            .to_str()
            .context("non-UTF8 upgrade path")?
            .replace('\\', "/");
        validate_path(root, &relative, &mut paths)?;
        if current(path)? != *before {
            bail!("file changed after upgrade preflight: {}", path.display());
        }
        entries.push(Entry {
            path: relative,
            before: before.clone(),
            after_digest: hash(bytes),
        });
    }
    let identity = hash(&serde_json::to_vec(&entries)?);
    let mut journal = Journal {
        schema_version: 1,
        builder_version: BUILDER_VERSION.to_owned(),
        migration_id: format!("managed-files-{BUILDER_VERSION}-{}", &identity[..16]),
        status: Status::Prepared,
        entries,
    };
    // Record original bytes and expected output before touching any owned file.
    save(root, &journal)?;
    for (path, _, bytes) in writes {
        atomic_write(&path, &bytes)?;
    }
    journal.status = Status::Committed;
    save(root, &journal)?;
    Ok(true)
}
pub(crate) fn rollback(root: &Path) -> Result<CommandResult> {
    // Check journal presence before creating the coordination lock file.
    load(root)?.context("no managed-file upgrade journal to roll back")?;
    let _guard = lock(root)?;
    let mut journal = load(root)?.context("no managed-file upgrade journal to roll back")?;
    let mut result = CommandResult::new("upgrade-rollback");
    result.path = Some(root.display().to_string());
    if journal.status == Status::RolledBack {
        return Ok(result);
    }
    // Preflight the entire recovery before restoring even the first file.
    for entry in &journal.entries {
        let bytes = current(&root.join(&entry.path))?;
        if bytes != entry.before
            && !bytes
                .as_ref()
                .is_some_and(|value| hash(value) == entry.after_digest)
        {
            result.conflicts.push(entry.path.clone());
        }
    }
    if !result.conflicts.is_empty() {
        result.ok = false;
        result
            .warnings
            .push("rollback preserved later user edits; no files were restored".to_owned());
        return Ok(result);
    }
    journal.status = Status::RollingBack;
    save(root, &journal)?;
    for entry in journal.entries.iter().rev() {
        let path = root.join(&entry.path);
        if current(&path)? == entry.before {
            continue;
        }
        match &entry.before {
            Some(bytes) => atomic_write(&path, bytes)?,
            None => fs::remove_file(&path)?,
        }
        result.actions.push(format!("restore {}", entry.path));
        result.changed = true;
    }
    journal.status = Status::RolledBack;
    save(root, &journal)?;
    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn later_control_edit_blocks_all_planned_application_writes() {
        let temp = tempfile::tempdir().expect("temporary project");
        let root = temp.path();
        fs::create_dir(root.join(".knowme-builder")).expect("state");
        let state = root.join(".knowme-builder/project.toml");
        fs::write(&state, b"later user edit").expect("edited state");
        let app = root.join("application.txt");
        fs::write(&app, b"original application").expect("application");
        let result = apply(
            root,
            vec![(
                app.clone(),
                Some(b"original application".to_vec()),
                b"new application".to_vec(),
            )],
            &[(state.as_path(), b"old parsed state")],
        );
        assert!(result.is_err());
        assert_eq!(
            fs::read(&app).expect("application"),
            b"original application"
        );
        assert_eq!(fs::read(&state).expect("state"), b"later user edit");
        assert!(!root.join(JOURNAL).exists());
    }
}
