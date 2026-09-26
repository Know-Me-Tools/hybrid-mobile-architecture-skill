use std::fs;

use assert_cmd::Command;
use predicates::prelude::*;
use tempfile::tempdir;

fn builder() -> Command {
    assert_cmd::cargo::cargo_bin_cmd!("knowme-builder")
}

#[test]
fn explicit_profile_is_required() {
    builder()
        .args(["new", "example", "--mode", "skeleton", "--check"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--profile"));
}

#[test]
fn unknown_flags_are_rejected() {
    builder()
        .args([
            "new",
            "example",
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "skeleton",
            "--unknown",
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("unexpected argument"));
}

#[test]
fn non_empty_destination_requires_adopt_or_force() {
    let temp = tempdir().expect("tempdir");
    fs::write(temp.path().join("existing.txt"), "owned by user").expect("write fixture");
    builder()
        .args([
            "new",
            temp.path().to_str().expect("utf8"),
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "skeleton",
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("destination is not empty"));
}

#[test]
fn adoption_is_non_destructive_and_idempotent() {
    let temp = tempdir().expect("tempdir");
    let user_file = temp.path().join("application.txt");
    fs::write(&user_file, "keep me").expect("write fixture");

    builder()
        .args([
            "--json",
            "adopt",
            temp.path().to_str().expect("utf8"),
            "--profile",
            "governed-web-shell",
            "--check",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": false"));
    assert!(!temp.path().join(".knowme-builder").exists());

    builder()
        .args([
            "--json",
            "adopt",
            temp.path().to_str().expect("utf8"),
            "--profile",
            "governed-web-shell",
            "--apply",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": true"));

    assert_eq!(fs::read_to_string(user_file).expect("user file"), "keep me");
    assert!(temp.path().join(".knowme-builder/project.toml").is_file());
    assert!(
        temp.path()
            .join(".knowme-builder/generated.lock.json")
            .is_file()
    );
    assert!(temp.path().join("skills-lock.json").is_file());
    let state =
        fs::read_to_string(temp.path().join(".knowme-builder/project.toml")).expect("state");
    assert!(state.contains("generationMode = \"skeleton\""));
    assert!(state.contains("enabledSurfaces = []"));
    assert!(state.contains("\"react-web\""));

    builder()
        .args([
            "--json",
            "adopt",
            temp.path().to_str().expect("utf8"),
            "--profile",
            "governed-web-shell",
            "--apply",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": false"));
}

#[test]
fn interrupted_adoption_reports_and_repairs_missing_controls_preserving_user_content() {
    let temp = tempdir().expect("tempdir");
    let project = temp.path().to_str().expect("path");
    builder()
        .args(["adopt", project, "--profile", "axum-web", "--apply"])
        .assert()
        .success();
    let state_path = temp.path().join(".knowme-builder/project.toml");
    let lock_path = temp.path().join(".knowme-builder/generated.lock.json");
    let state = fs::read(&state_path).expect("state");
    let lock = fs::read(&lock_path).expect("lock");
    let policy = temp.path().join(".knowme-builder/policy-overlay.toml");
    let activation = temp.path().join(".knowme-builder/activation-manifest.json");
    let skills = temp.path().join("skills-lock.json");
    for path in [&policy, &activation, &skills] {
        fs::remove_file(path).expect("simulate interruption");
    }
    builder()
        .args([
            "--json",
            "adopt",
            project,
            "--profile",
            "axum-web",
            "--check",
        ])
        .assert()
        .failure()
        .stdout(predicate::str::contains("incomplete adoption state"))
        .stdout(predicate::str::contains("\"changed\": false"));
    for path in [&policy, &activation, &skills] {
        assert!(!path.exists(), "check must not restore files");
    }
    builder()
        .args([
            "--json",
            "adopt",
            project,
            "--profile",
            "axum-web",
            "--apply",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": true"));
    for path in [&policy, &activation, &skills] {
        assert!(path.is_file(), "apply must restore every missing control");
    }
    assert_eq!(fs::read(&state_path).expect("state"), state);
    assert_eq!(fs::read(&lock_path).expect("lock"), lock);
    builder()
        .args([
            "--json",
            "adopt",
            project,
            "--profile",
            "axum-web",
            "--apply",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": false"));

    fs::write(&policy, "[custom]\napproval = true\n").expect("custom policy");
    fs::write(&skills, "{\"third-party\":{\"version\":\"1.0.0\"}}\n").expect("third-party skills");
    let user_policy = fs::read(&policy).expect("policy");
    let user_skills = fs::read(&skills).expect("skills");
    fs::remove_file(&activation).expect("remove activation");
    builder()
        .args([
            "--json",
            "adopt",
            project,
            "--profile",
            "axum-web",
            "--check",
        ])
        .assert()
        .failure()
        .stdout(predicate::str::contains("activation-manifest.json"));
    builder()
        .args(["adopt", project, "--profile", "axum-web", "--apply"])
        .assert()
        .success();
    assert!(activation.is_file());
    assert_eq!(fs::read(policy).expect("policy"), user_policy);
    assert_eq!(fs::read(skills).expect("skills"), user_skills);
    builder()
        .args([
            "--json",
            "adopt",
            project,
            "--profile",
            "axum-web",
            "--check",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": false"));
}

#[test]
fn completions_are_available() {
    builder()
        .args(["completions", "bash"])
        .assert()
        .success()
        .stdout(predicate::str::contains("_knowme-builder"));
}

#[test]
fn runnable_sovereign_profile_generates_atomically() {
    let temp = tempdir().expect("tempdir");
    let destination = temp.path().join("my-agent-app");
    builder()
        .args([
            "--json",
            "new",
            destination.to_str().expect("utf8"),
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": true"));

    assert!(destination.join("rust/src/lib.rs").is_file());
    assert!(destination.join("rust/tests/vertical_slice.rs").is_file());
    assert!(destination.join("desktop/src/uar-facade.mjs").is_file());
    assert!(destination.join("mobile/lib/uar_facade.dart").is_file());
    let project = fs::read_to_string(destination.join(".knowme-builder/project.toml"))
        .expect("project manifest");
    assert!(project.contains("profile = \"sovereign-hybrid\""));
    assert!(project.contains("unsupportedSurfaces = []"));
}

#[test]
fn skeleton_records_unsupported_surfaces() {
    let temp = tempdir().expect("tempdir");
    let destination = temp.path().join("skeleton");
    builder()
        .args([
            "new",
            destination.to_str().expect("utf8"),
            "--profile",
            "governed-web-shell",
            "--mode",
            "skeleton",
        ])
        .assert()
        .success();
    let project = fs::read_to_string(destination.join(".knowme-builder/project.toml"))
        .expect("project manifest");
    assert!(project.contains("react-web"));
    assert!(project.contains("axum-bff"));
}

#[test]
fn upgrade_preserves_modified_managed_files_and_emits_proposal() {
    let temp = tempdir().expect("tempdir");
    let destination = temp.path().join("conflict-app");
    builder()
        .args([
            "new",
            destination.to_str().expect("utf8"),
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success();
    let readme = destination.join("README.md");
    fs::write(&readme, "consumer modification\n").expect("modify managed file");
    let lock_path = destination.join(".knowme-builder/generated.lock.json");
    let original_lock = fs::read(&lock_path).expect("lock");
    // Missing owned files would be restored by upgrade if the whole plan had no conflicts.
    let missing = destination.join("rust/src/lib.rs");
    fs::remove_file(&missing).expect("remove managed file");

    builder()
        .args([
            "--json",
            "upgrade",
            destination.to_str().expect("utf8"),
            "--apply",
        ])
        .assert()
        .failure()
        .stdout(predicate::str::contains("\"conflicts\": ["))
        .stdout(predicate::str::contains("README.md"));
    assert_eq!(
        fs::read_to_string(readme).expect("preserved readme"),
        "consumer modification\n"
    );
    assert!(
        destination
            .join(".knowme-builder/conflicts/README.md.proposed")
            .is_file()
    );
    assert!(
        !missing.exists(),
        "a conflicting upgrade must not partially restore files"
    );
    assert_eq!(fs::read(lock_path).expect("lock"), original_lock);
}

#[test]
fn adoption_conflict_does_not_partially_create_control_state() {
    let temp = tempdir().expect("tempdir");
    fs::write(temp.path().join("skills-lock.json"), "user-owned").expect("fixture");
    builder()
        .args([
            "--json",
            "adopt",
            temp.path().to_str().expect("path"),
            "--profile",
            "axum-web",
            "--apply",
        ])
        .assert()
        .failure()
        .stdout(predicate::str::contains("skills-lock.json"));
    assert!(!temp.path().join(".knowme-builder").exists());
    assert_eq!(
        fs::read_to_string(temp.path().join("skills-lock.json")).expect("lock"),
        "user-owned"
    );
}

#[test]
fn moved_project_upgrade_preserves_identity_and_is_idempotent() {
    let temp = tempdir().expect("tempdir");
    let original = temp.path().join("original-name");
    builder()
        .args([
            "new",
            original.to_str().expect("path"),
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success();
    let moved = temp.path().join("renamed folder");
    fs::rename(&original, &moved).expect("move project");
    let package = fs::read(moved.join("desktop/package.json")).expect("package");
    builder()
        .args([
            "--json",
            "upgrade",
            moved.to_str().expect("path"),
            "--apply",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": false"));
    assert_eq!(
        fs::read(moved.join("desktop/package.json")).expect("package"),
        package
    );
}

#[test]
fn legacy_identity_requires_explicit_original_name_and_unknown_schema_rejects_without_writes() {
    let temp = tempdir().expect("tempdir");
    let project = temp.path().join("legacy");
    builder()
        .args([
            "new",
            project.to_str().expect("path"),
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success();
    let path = project.join(".knowme-builder/project.toml");
    let saved = fs::read_to_string(&path).expect("state");
    let legacy = saved
        .lines()
        .filter(|line| !line.starts_with("appName ="))
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(&path, &legacy).expect("legacy state");
    builder()
        .args(["upgrade", project.to_str().expect("path"), "--apply"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--app-name"));
    assert_eq!(fs::read_to_string(&path).expect("state"), legacy);
    builder()
        .args([
            "upgrade",
            project.to_str().expect("path"),
            "--app-name",
            "legacy",
            "--apply",
        ])
        .assert()
        .success();
    let unsupported = fs::read_to_string(&path)
        .expect("state")
        .replace("schemaVersion = 1", "schemaVersion = 999");
    fs::write(&path, &unsupported).expect("unsupported schema");
    builder()
        .args(["upgrade", project.to_str().expect("path"), "--apply"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("unsupported project schema"));
    assert_eq!(fs::read_to_string(path).expect("state"), unsupported);
}

#[test]
fn native_doctor_rejects_unknown_target_before_probing() {
    builder()
        .args(["doctor", "--native-only", "--target", "imaginary-os"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("invalid value"));
}

#[test]
fn upgrade_journal_restores_missing_files_and_metadata_without_overwriting_later_edits() {
    let temp = tempdir().expect("tempdir");
    let project = temp.path().join("journal app");
    let path = project.to_str().expect("path");
    builder()
        .args([
            "new",
            path,
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success();
    let missing = project.join("rust/src/lib.rs");
    let expected = fs::read(&missing).expect("generated file");
    fs::remove_file(&missing).expect("simulate missing owned file");
    let metadata = project.join(".knowme-builder/project.toml");
    let original = fs::read_to_string(&metadata).expect("metadata");
    let legacy = original
        .lines()
        .filter(|line| !line.starts_with("appName ="))
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(&metadata, &legacy).expect("legacy rendering metadata");
    builder()
        .args(["upgrade", path, "--check", "--app-name", "journal app"])
        .assert()
        .success();
    assert!(
        !project
            .join(".knowme-builder/upgrade-journal.json")
            .exists()
    );
    builder()
        .args(["upgrade", path, "--apply", "--app-name", "journal app"])
        .assert()
        .success();
    assert_eq!(fs::read(&missing).expect("restored"), expected);
    let applied_metadata = fs::read(&metadata).expect("applied metadata");
    fs::write(&missing, "later user edit").expect("user edit");
    builder()
        .args(["--json", "upgrade", path, "--rollback"])
        .assert()
        .failure()
        .stdout(predicate::str::contains("rust/src/lib.rs"));
    assert_eq!(
        fs::read(&metadata).expect("preserved metadata"),
        applied_metadata
    );
    assert_eq!(
        fs::read_to_string(&missing).expect("preserved file"),
        "later user edit"
    );
    fs::write(&missing, &expected).expect("resolve edit");
    builder()
        .args(["upgrade", path, "--rollback"])
        .assert()
        .success();
    assert!(!missing.exists());
    assert_eq!(
        fs::read_to_string(&metadata).expect("original metadata"),
        legacy
    );
    builder()
        .args(["--json", "upgrade", path, "--rollback"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"changed\": false"));
}

#[test]
fn interrupted_upgrade_requires_recovery_and_restores_partial_application() {
    let temp = tempdir().expect("tempdir");
    let project = temp.path().join("interrupted");
    let path = project.to_str().expect("path");
    builder()
        .args([
            "new",
            path,
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success();
    let missing = project.join("rust/src/lib.rs");
    fs::remove_file(&missing).expect("missing");
    builder()
        .args(["upgrade", path, "--apply"])
        .assert()
        .success();
    let journal_path = project.join(".knowme-builder/upgrade-journal.json");
    let mut journal: serde_json::Value =
        serde_json::from_slice(&fs::read(&journal_path).expect("journal")).expect("parse");
    // A process killed after its first atomic application write leaves this
    // persisted protocol state; recovery must not depend on an in-memory flag.
    journal["status"] = "prepared".into();
    fs::write(
        &journal_path,
        serde_json::to_vec_pretty(&journal).expect("serialize"),
    )
    .expect("interruption fixture");
    builder()
        .args(["upgrade", path, "--check"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--rollback"));
    builder()
        .args(["upgrade", path, "--apply"])
        .assert()
        .failure();
    builder()
        .args(["upgrade", path, "--rollback"])
        .assert()
        .success();
    assert!(!missing.exists());
    builder()
        .args(["upgrade", path, "--apply"])
        .assert()
        .success();
    assert!(missing.exists());
}

#[test]
fn upgrade_rejects_duplicate_ownership_and_respects_native_process_lock() {
    let temp = tempdir().expect("tempdir");
    let project = temp.path().join("locked");
    let path = project.to_str().expect("path");
    builder()
        .args([
            "new",
            path,
            "--profile",
            "sovereign-hybrid",
            "--mode",
            "runnable",
        ])
        .assert()
        .success();
    let missing = project.join("rust/src/lib.rs");
    fs::remove_file(&missing).expect("missing");
    let lock_path = project.join(".knowme-builder/generated.lock.json");
    let original = fs::read(&lock_path).expect("ownership");
    let mut invalid: serde_json::Value = serde_json::from_slice(&original).expect("parse");
    let duplicate = invalid["files"][0].clone();
    invalid["files"]
        .as_array_mut()
        .expect("files")
        .push(duplicate);
    fs::write(&lock_path, serde_json::to_vec(&invalid).expect("json")).expect("duplicate lock");
    builder()
        .args(["upgrade", path, "--apply"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("duplicate or reserved"));
    assert!(!missing.exists());
    assert!(
        !project
            .join(".knowme-builder/upgrade-journal.json")
            .exists()
    );
    fs::write(&lock_path, &original).expect("restore ownership");
    let held =
        fs::File::create(project.join(".knowme-builder/upgrade.lock")).expect("coordination file");
    held.try_lock().expect("native exclusive lock");
    builder()
        .args(["upgrade", path, "--apply"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("another upgrade"));
    assert!(!missing.exists());
    drop(held);
    builder()
        .args(["upgrade", path, "--apply"])
        .assert()
        .success();
    assert!(missing.exists());
}

#[cfg(not(windows))]
#[test]
fn windows_targets_never_claim_native_readiness_on_other_hosts() {
    builder()
        .args([
            "--json",
            "doctor",
            "--native-only",
            "--target",
            "x86_64-pc-windows-msvc",
            "--target",
            "aarch64-pc-windows-msvc",
        ])
        .assert()
        .failure()
        .stdout(predicate::str::contains("Windows runner"))
        .stdout(predicate::str::contains("x86_64-pc-windows-msvc"))
        .stdout(predicate::str::contains("aarch64-pc-windows-msvc"));
}
