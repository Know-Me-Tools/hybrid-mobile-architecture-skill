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

    builder()
        .args([
            "--json",
            "upgrade",
            destination.to_str().expect("utf8"),
            "--apply",
        ])
        .assert()
        .success()
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
}
