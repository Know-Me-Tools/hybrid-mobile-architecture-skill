use std::{env, path::Path, process::Command};

use crate::model::CommandResult;

/// Inspect prerequisites without installing tools or claiming application certification.
pub(crate) fn inspect(root: &Path, targets: &[String], result: &mut CommandResult) {
    for (tool, args) in [("rustc", vec!["-vV"]), ("cargo", vec!["--version"])] {
        match Command::new(tool).args(args).current_dir(root).output() {
            Ok(output) if output.status.success() => result
                .actions
                .push(String::from_utf8_lossy(&output.stdout).trim().to_owned()),
            _ => {
                result.ok = false;
                result
                    .warnings
                    .push(format!("native tool unavailable: {tool}"));
            }
        }
    }
    if targets.is_empty() {
        result.warnings.push("no cross-target requested; native library and application build readiness are unverified".to_owned());
        return;
    }
    let installed = Command::new("rustup")
        .args(["target", "list", "--installed"])
        .current_dir(root)
        .output()
        .ok()
        .filter(|output| output.status.success())
        .map(|output| String::from_utf8_lossy(&output.stdout).into_owned())
        .unwrap_or_default();
    for target in targets {
        if installed.lines().any(|line| line.trim() == target) {
            result
                .actions
                .push(format!("Rust standard library installed: {target}"));
        } else {
            result.ok = false;
            result.warnings.push(format!(
                "missing Rust target {target}; install explicitly with rustup target add {target}"
            ));
        }
        if !cfg!(windows) {
            result.ok = false;
            result.warnings.push(format!("{target}: MSVC/Windows SDK and native execution require a Windows runner; target installation is insufficient"));
            continue;
        }
        let arch = if target.starts_with("aarch64") {
            "arm64"
        } else {
            "x64"
        };
        let vc_lib = env::var_os("VCToolsInstallDir").map(|directory| {
            Path::new(&directory)
                .join("lib")
                .join(arch)
                .join("libcmt.lib")
        });
        let sdk_lib = env::var_os("LIB").is_some_and(|paths| {
            env::split_paths(&paths).any(|path| {
                path.file_name()
                    .is_some_and(|name| name.to_string_lossy().eq_ignore_ascii_case(arch))
                    && path.join("kernel32.lib").is_file()
            })
        });
        let sdk_headers = env::var_os("INCLUDE").is_some_and(|paths| {
            env::split_paths(&paths).any(|path| path.join("Windows.h").is_file())
        });
        let linker = env::var_os("PATH").is_some_and(|paths| {
            env::split_paths(&paths).any(|path| path.join("link.exe").is_file())
        });
        if !vc_lib.is_some_and(|path| path.is_file()) || !sdk_lib || !sdk_headers || !linker {
            result.ok = false;
            result.warnings.push(format!("{target}: incomplete MSVC {arch} tools/Windows SDK environment; select the matching Visual Studio developer environment"));
        } else {
            result.actions.push(format!(
                "{target}: MSVC {arch} library, SDK headers/library and linker found"
            ));
        }
        result.warnings.push(format!("{target}: linking, native dependencies and launch remain unverified until the target application build/run succeeds"));
    }
}
