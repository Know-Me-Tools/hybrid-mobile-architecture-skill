use std::{
    fs,
    io::Write,
    path::{Path, PathBuf},
    time::{SystemTime, UNIX_EPOCH},
};

use anyhow::{Context, Result, bail};
use clap::CommandFactory;
use clap_complete::{Shell, generate};
use include_dir::{Dir, DirEntry};
use sha2::{Digest, Sha256};
use tempfile::Builder as TempBuilder;

use crate::{
    bundle::{self, SKILLS, TEMPLATES},
    cli::{
        AddArgs, AdoptArgs, Cli, Command, CompletionShell, CompletionsArgs, DoctorArgs,
        ManifestArgs, ManifestCommand, NewArgs, SkillsArgs, SkillsCommand, UpgradeArgs,
    },
    model::{
        BUILDER_VERSION, CommandResult, GeneratedFile, GeneratedLock, Ownership,
        PROMETHEUS_CONTRACT, ProjectManifest,
    },
};

pub fn execute(cli: Cli) -> Result<()> {
    let json = cli.json;
    let result = match cli.command {
        Command::New(args) => create_project(args),
        Command::Adopt(args) => adopt_project(args),
        Command::Upgrade(args) => upgrade_project(args),
        Command::Add(args) => add_capability(args),
        Command::Skills(args) => manage_skills(args),
        Command::Audit(args) => audit_project(args.path, args.profile),
        Command::Doctor(args) => doctor(args),
        Command::Manifest(args) => manage_manifest(args),
        Command::Completions(args) => return completions(args),
    }?;
    print_result(&result, json)
}

fn add_capability(args: AddArgs) -> Result<CommandResult> {
    let destination = absolute_path(&args.path)?;
    let project: ProjectManifest = toml::from_str(
        &fs::read_to_string(destination.join(".knowme-builder/project.toml"))
            .context("project is not adopted; run `knowme-builder adopt --check` first")?,
    )?;
    let kind = args.kind.as_str();
    let name = args.name.unwrap_or_else(|| kind.to_owned());
    let safe_name = slug(&name);
    if safe_name.is_empty() {
        bail!("capability name must contain an alphanumeric character");
    }
    let template_path = format!("add/{kind}");
    let template = TEMPLATES
        .get_dir(&template_path)
        .with_context(|| format!("capability template is not packaged: {template_path}"))?;
    let mut result = CommandResult::new(format!("add-{kind}"));
    result.path = Some(destination.display().to_string());
    result.profile = Some(project.profile.as_str().to_owned());
    let context = RenderContext {
        app_name: &safe_name,
        profile: project.profile.as_str(),
        mode: project.generation_mode.as_str(),
    };
    let additions_root = destination.join(".knowme-builder/additions").join(kind);
    let mut proposed_lock = GeneratedLock {
        schema_version: 1,
        builder_version: BUILDER_VERSION.to_owned(),
        files: Vec::new(),
    };
    if args.check {
        result.actions.extend(
            collect_template_paths(template)?
                .iter()
                .map(|path| format!("add {kind}/{}", path.display())),
        );
        return Ok(result);
    }
    if additions_root.join(&safe_name).exists() {
        bail!("capability already exists: {kind}/{safe_name}");
    }
    let staging = TempBuilder::new()
        .prefix(".addition-")
        .tempdir_in(destination.join(".knowme-builder"))?;
    render_dir(
        template,
        template,
        staging.path(),
        &context,
        &mut proposed_lock,
    )?;
    let target = additions_root.join(&safe_name);
    fs::create_dir_all(&additions_root)?;
    fs::rename(staging.keep(), &target)?;
    result.changed = true;
    result.actions.push(format!("created {}", target.display()));
    Ok(result)
}

fn manage_skills(args: SkillsArgs) -> Result<CommandResult> {
    let (path, check, force) = match args.command {
        SkillsCommand::Install { path, check, force } => (path, check, force),
        SkillsCommand::Check { path } => (path, true, false),
    };
    let destination = absolute_path(&path)?;
    let manifest = bundle::manifest()?;
    let harness_roots = [
        ".claude/skills",
        ".codex/skills",
        ".opencode/skills",
        ".kimi-code/skills",
        ".kimi/skills",
        ".agents/skills",
    ];
    let mut result = CommandResult::new(if check {
        "skills-check"
    } else {
        "skills-install"
    });
    result.path = Some(destination.display().to_string());
    for harness in harness_roots {
        for skill in &manifest.skills {
            let source = SKILLS
                .get_dir(skill)
                .with_context(|| format!("packaged skill is missing: {skill}"))?;
            let target = destination.join(harness).join(skill);
            let drift = dir_differs(source, source, &target)?;
            if !drift {
                continue;
            }
            result.actions.push(format!("sync {harness}/{skill}"));
            if target.exists() {
                if force && !check {
                    let backup = destination
                        .join(".knowme-builder/backups/skills")
                        .join(harness)
                        .join(skill);
                    if !backup.exists() {
                        if let Some(parent) = backup.parent() {
                            fs::create_dir_all(parent)?;
                        }
                        fs::rename(&target, &backup)?;
                        result.warnings.push(format!(
                            "previous payload preserved at {}",
                            backup.display()
                        ));
                    } else {
                        fs::remove_dir_all(&target)?;
                        result.warnings.push(format!(
                            "initial pre-Builder payload remains preserved at {}",
                            backup.display()
                        ));
                    }
                    write_embedded_dir(source, source, &target)?;
                    result.changed = true;
                } else {
                    result.conflicts.push(format!("{harness}/{skill}"));
                }
                if !check && !force {
                    let proposed = destination
                        .join(".knowme-builder/conflicts/skills")
                        .join(harness)
                        .join(skill);
                    write_embedded_dir(source, source, &proposed)?;
                    result.changed = true;
                }
            } else if !check {
                write_embedded_dir(source, source, &target)?;
                result.changed = true;
            }
        }
    }
    if !check {
        let lock_path = destination.join("skills-lock.json");
        let lock = skills_lock_bytes_preserving_third_party(&manifest.skills, &lock_path)?;
        if !lock_path.is_file() || fs::read(&lock_path)? != lock {
            atomic_write(&lock_path, &lock)?;
            result.actions.push("refresh skills-lock.json".to_owned());
            result.changed = true;
        }
    }
    result.ok = result.conflicts.is_empty();
    Ok(result)
}

fn audit_project(
    path: PathBuf,
    requested_profile: Option<crate::cli::Profile>,
) -> Result<CommandResult> {
    let destination = absolute_path(&path)?;
    let mut result = CommandResult::new("audit");
    result.path = Some(destination.display().to_string());
    let project_path = destination.join(".knowme-builder/project.toml");
    let project: Option<ProjectManifest> = if project_path.exists() {
        Some(toml::from_str(&fs::read_to_string(&project_path)?)?)
    } else {
        None
    };
    let profile = requested_profile
        .or_else(|| project.as_ref().map(|value| value.profile))
        .context("audit requires --profile or adopted project state")?;
    result.profile = Some(profile.as_str().to_owned());
    let required = match profile {
        crate::cli::Profile::SovereignHybrid => {
            vec!["rust", "desktop", "mobile", ".knowme-builder/project.toml"]
        }
        crate::cli::Profile::GovernedWebShell => {
            vec!["server", "web", ".knowme-builder/project.toml"]
        }
        crate::cli::Profile::FlutterMobile => {
            vec!["mobile", "rust", ".knowme-builder/project.toml"]
        }
        crate::cli::Profile::TauriDesktop => {
            vec!["desktop", "rust", ".knowme-builder/project.toml"]
        }
        crate::cli::Profile::AxumWeb => {
            vec!["server", "web", ".knowme-builder/project.toml"]
        }
    };
    for required_path in required {
        if !destination.join(required_path).exists() {
            result.ok = false;
            result
                .warnings
                .push(format!("missing profile surface: {required_path}"));
        }
    }
    for prohibited in [
        ".kbd-orchestrator/current-waypoint.json",
        ".kbd-orchestrator/progress.json",
        ".kbd-orchestrator/position.json",
    ] {
        if destination.join(prohibited).is_file() {
            result.warnings.push(format!(
                "compatibility projection must remain read-only: {prohibited}"
            ));
        }
    }
    Ok(result)
}

fn doctor(args: DoctorArgs) -> Result<CommandResult> {
    let destination = absolute_path(&args.path)?;
    let mut result = CommandResult::new("doctor");
    result.path = Some(destination.display().to_string());
    let manifest = bundle::manifest()?;
    let _prometheus = bundle::prometheus_contract()?;
    let _uar = bundle::uar_contract()?;
    result.actions.push(format!(
        "Builder {} manifest {} is internally consistent across {} harnesses",
        manifest.package.id,
        manifest.package.version,
        manifest.supported_harnesses.len()
    ));

    let prometheus = std::process::Command::new("prometheus")
        .args(["doctor", "--json"])
        .current_dir(&destination)
        .output();
    match prometheus {
        Ok(output) => {
            let parsed: serde_json::Value = serde_json::from_slice(&output.stdout)
                .context("prometheus doctor returned invalid JSON")?;
            let contract = parsed
                .get("contractVersion")
                .or_else(|| parsed.pointer("/controlPlane/contractVersion"))
                .and_then(serde_json::Value::as_str);
            if contract.is_none() {
                result.ok = false;
                result
                    .warnings
                    .push("Prometheus doctor lacks a machine-readable contractVersion".to_owned());
            } else if !version_at_least(contract.unwrap_or_default(), PROMETHEUS_CONTRACT) {
                result.ok = false;
                result.warnings.push(format!(
                    "Prometheus contract {} is older than required {}",
                    contract.unwrap_or_default(),
                    PROMETHEUS_CONTRACT
                ));
            } else {
                result.actions.push(format!(
                    "Prometheus control-plane contract {} is compatible",
                    contract.unwrap_or_default()
                ));
            }
            if output.status.success() {
                result.actions.push("Prometheus doctor passed".to_owned());
            } else {
                result.ok = false;
                let failed = parsed
                    .pointer("/summary/failed")
                    .and_then(serde_json::Value::as_u64)
                    .unwrap_or_default();
                result.warnings.push(format!(
                    "Prometheus doctor reported {failed} failing health check(s)"
                ));
            }
        }
        Err(error) => {
            result.ok = false;
            result
                .warnings
                .push(format!("Prometheus CLI is unavailable: {error}"));
        }
    }
    Ok(result)
}

fn version_at_least(actual: &str, required: &str) -> bool {
    fn parts(value: &str) -> Option<(u64, u64, u64)> {
        let stable = value.split_once('-').map_or(value, |(prefix, _)| prefix);
        let mut values = stable.split('.').map(str::parse::<u64>);
        Some((
            values.next()?.ok()?,
            values.next()?.ok()?,
            values.next()?.ok()?,
        ))
    }
    matches!((parts(actual), parts(required)), (Some(actual), Some(required)) if actual >= required)
}

fn manage_manifest(args: ManifestArgs) -> Result<CommandResult> {
    let mut result = CommandResult::new("manifest");
    let manifest = bundle::manifest()?;
    let _prometheus = bundle::prometheus_contract()?;
    let _uar = bundle::uar_contract()?;
    result.actions.push(format!(
        "validated embedded manifest {} {}",
        manifest.package.id, manifest.package.version
    ));
    let root = std::env::current_dir()?;
    let script = root.join("scripts/generate-builder-manifests.mjs");
    match args.command {
        ManifestCommand::Check if script.is_file() => {
            let status = std::process::Command::new("node")
                .arg(&script)
                .arg("--check")
                .current_dir(&root)
                .status()?;
            if !status.success() {
                result.ok = false;
                result
                    .warnings
                    .push("generated manifests drifted".to_owned());
            }
        }
        ManifestCommand::Generate if script.is_file() => {
            let status = std::process::Command::new("node")
                .arg(&script)
                .current_dir(&root)
                .status()?;
            if !status.success() {
                bail!("manifest generator failed");
            }
            result.changed = true;
        }
        ManifestCommand::Generate => {
            bail!("manifest generation requires the Builder source checkout");
        }
        ManifestCommand::Check => {}
    }
    Ok(result)
}

fn completions(args: CompletionsArgs) -> Result<()> {
    let shell = match args.shell {
        CompletionShell::Bash => Shell::Bash,
        CompletionShell::Elvish => Shell::Elvish,
        CompletionShell::Fish => Shell::Fish,
        CompletionShell::PowerShell => Shell::PowerShell,
        CompletionShell::Zsh => Shell::Zsh,
    };
    let mut command = crate::cli::Cli::command();
    generate(
        shell,
        &mut command,
        "knowme-builder",
        &mut std::io::stdout(),
    );
    Ok(())
}

fn dir_differs(root: &Dir<'_>, dir: &Dir<'_>, target: &Path) -> Result<bool> {
    for entry in dir.entries() {
        match entry {
            DirEntry::Dir(child) => {
                if dir_differs(root, child, target)? {
                    return Ok(true);
                }
            }
            DirEntry::File(file) => {
                let relative = file.path().strip_prefix(root.path())?;
                let installed = target.join(relative);
                if !installed.is_file() || fs::read(&installed)? != file.contents() {
                    return Ok(true);
                }
            }
        }
    }
    Ok(false)
}

fn write_embedded_dir(root: &Dir<'_>, dir: &Dir<'_>, destination: &Path) -> Result<()> {
    for entry in dir.entries() {
        match entry {
            DirEntry::Dir(child) => write_embedded_dir(root, child, destination)?,
            DirEntry::File(file) => {
                let relative = file.path().strip_prefix(root.path())?;
                bundle::validate_relative_path(relative)?;
                atomic_write(&destination.join(relative), file.contents())?;
            }
        }
    }
    Ok(())
}

fn adopt_project(args: AdoptArgs) -> Result<CommandResult> {
    let destination = absolute_path(&args.path)?;
    if !destination.is_dir() {
        bail!(
            "adoption target must be an existing directory: {}",
            destination.display()
        );
    }
    let manifest = bundle::manifest()?;
    let profile = bundle::profile(&manifest, args.profile)?;
    let mut result = CommandResult::new("adopt");
    result.path = Some(destination.display().to_string());
    result.profile = Some(args.profile.as_str().to_owned());

    let project = ProjectManifest {
        schema_version: 1,
        profile: args.profile,
        builder_version: BUILDER_VERSION.to_owned(),
        required_prometheus_contract: PROMETHEUS_CONTRACT.to_owned(),
        uar_mode: profile.uar_mode.clone(),
        enabled_surfaces: profile.surfaces.clone(),
        generation_mode: crate::cli::GenerationMode::Runnable,
        policy_overlay_path: ".knowme-builder/policy-overlay.toml".to_owned(),
        unsupported_surfaces: Vec::new(),
    };
    let state_dir = destination.join(".knowme-builder");
    let project_bytes = toml::to_string_pretty(&project)?;
    plan_control_file(
        &state_dir.join("project.toml"),
        project_bytes.as_bytes(),
        args.apply,
        &mut result,
    )?;
    let lock = GeneratedLock {
        schema_version: 1,
        builder_version: BUILDER_VERSION.to_owned(),
        files: Vec::new(),
    };
    let lock_bytes = format!("{}\n", serde_json::to_string_pretty(&lock)?);
    plan_control_file(
        &state_dir.join("generated.lock.json"),
        lock_bytes.as_bytes(),
        args.apply,
        &mut result,
    )?;
    let policy = b"# Project-local policy overlay.\n# Consumer-specific roles, tenants, and release gates belong here.\n";
    plan_control_file(
        &state_dir.join("policy-overlay.toml"),
        policy,
        args.apply,
        &mut result,
    )?;
    plan_control_file(
        &state_dir.join("activation-manifest.json"),
        bundle::activation_manifest(),
        args.apply,
        &mut result,
    )?;

    let proposed_skills = skills_lock_bytes(&manifest.skills)?;
    let skills_lock_path = destination.join("skills-lock.json");
    if skills_lock_path.exists() {
        if fs::read(&skills_lock_path)? != proposed_skills {
            result
                .warnings
                .push("existing skills-lock.json is user-owned and was not overwritten".to_owned());
            result.conflicts.push("skills-lock.json".to_owned());
            if args.apply {
                let proposed = state_dir.join("conflicts/skills-lock.json.proposed");
                atomic_write(&proposed, &proposed_skills)?;
                result.changed = true;
            }
        }
    } else {
        result.actions.push("create skills-lock.json".to_owned());
        if args.apply {
            atomic_write(&skills_lock_path, &proposed_skills)?;
            result.changed = true;
        }
    }
    result.ok = result.conflicts.is_empty();
    Ok(result)
}

fn upgrade_project(args: UpgradeArgs) -> Result<CommandResult> {
    let destination = absolute_path(&args.path)?;
    let state_dir = destination.join(".knowme-builder");
    let project_path = state_dir.join("project.toml");
    let lock_path = state_dir.join("generated.lock.json");
    let project: ProjectManifest = toml::from_str(
        &fs::read_to_string(&project_path)
            .with_context(|| format!("missing adoption state {}", project_path.display()))?,
    )
    .context("invalid .knowme-builder/project.toml")?;
    let mut lock: GeneratedLock = serde_json::from_str(
        &fs::read_to_string(&lock_path)
            .with_context(|| format!("missing generated lock {}", lock_path.display()))?,
    )
    .context("invalid .knowme-builder/generated.lock.json")?;

    let mut result = CommandResult::new("upgrade");
    result.path = Some(destination.display().to_string());
    result.profile = Some(project.profile.as_str().to_owned());
    let app_name = destination
        .file_name()
        .and_then(|name| name.to_str())
        .context("project path must have a UTF-8 name")?;
    let render_context = RenderContext {
        app_name,
        profile: project.profile.as_str(),
        mode: project.generation_mode.as_str(),
    };

    for file in &mut lock.files {
        if !matches!(file.ownership, Ownership::Builder) {
            continue;
        }
        let relative = Path::new(&file.path);
        bundle::validate_relative_path(relative)?;
        let target = destination.join(relative);
        let current = if target.exists() {
            Some(fs::read(&target)?)
        } else {
            None
        };
        let unmodified = current
            .as_ref()
            .is_none_or(|bytes| digest(bytes) == file.last_installed_digest);
        let template = TEMPLATES
            .get_file(&file.template_id)
            .with_context(|| format!("missing template {}", file.template_id))?;
        let source = template.contents();
        let proposed = match std::str::from_utf8(source) {
            Ok(text) => render_text(text, &render_context).into_bytes(),
            Err(_) => source.to_vec(),
        };
        let proposed_digest = digest(&proposed);
        if current
            .as_ref()
            .is_some_and(|bytes| digest(bytes) == proposed_digest)
        {
            file.source_digest = digest(source);
            file.last_installed_digest = proposed_digest;
            file.version = BUILDER_VERSION.to_owned();
            continue;
        }

        if unmodified {
            result.actions.push(format!("upgrade {}", file.path));
            if args.apply {
                atomic_write(&target, &proposed)?;
                file.source_digest = digest(source);
                file.last_installed_digest = proposed_digest;
                file.version = BUILDER_VERSION.to_owned();
                result.changed = true;
            }
        } else {
            result.conflicts.push(file.path.clone());
            if args.apply {
                let sidecar = state_dir
                    .join("conflicts")
                    .join(relative)
                    .with_extension(format!(
                        "{}proposed",
                        relative
                            .extension()
                            .map(|value| format!("{}.", value.to_string_lossy()))
                            .unwrap_or_default()
                    ));
                atomic_write(&sidecar, &proposed)?;
                result.changed = true;
            }
        }
    }

    if args.apply {
        lock.builder_version = BUILDER_VERSION.to_owned();
        atomic_write(
            &lock_path,
            format!("{}\n", serde_json::to_string_pretty(&lock)?).as_bytes(),
        )?;
    }
    result.ok = result.conflicts.is_empty();
    Ok(result)
}

fn plan_control_file(
    path: &Path,
    expected: &[u8],
    apply: bool,
    result: &mut CommandResult,
) -> Result<()> {
    if path.exists() {
        if fs::read(path)? != expected {
            result.conflicts.push(
                path.file_name()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .into_owned(),
            );
        }
        return Ok(());
    }
    result.actions.push(format!("create {}", path.display()));
    if apply {
        atomic_write(path, expected)?;
        result.changed = true;
    }
    Ok(())
}

fn create_project(args: NewArgs) -> Result<CommandResult> {
    let destination = absolute_path(&args.path)?;
    let manifest = bundle::manifest()?;
    let profile = bundle::profile(&manifest, args.profile)?;
    let mut result = CommandResult::new("new");
    result.path = Some(destination.display().to_string());
    result.profile = Some(args.profile.as_str().to_owned());

    if args.adopt {
        bail!("use `knowme-builder adopt` for non-destructive adoption");
    }

    let destination_state = destination_state(&destination)?;
    if destination_state == DestinationState::NonEmpty && !args.force {
        bail!(
            "destination is not empty; use `adopt` for an evolved application or explicit `--force`: {}",
            destination.display()
        );
    }

    let template_path = format!("profiles/{}/{}", args.profile.as_str(), args.mode.as_str());
    let template = TEMPLATES
        .get_dir(&template_path)
        .with_context(|| format!("profile template is not packaged: {template_path}"))?;

    let planned_paths = collect_template_paths(template)?;
    result.actions.extend(
        planned_paths
            .iter()
            .map(|path| format!("generate {}", path.display())),
    );
    result
        .actions
        .push("write .knowme-builder/project.toml".to_owned());
    result
        .actions
        .push("write .knowme-builder/generated.lock.json".to_owned());
    result.actions.push("write skills-lock.json".to_owned());

    if args.check {
        return Ok(result);
    }

    let parent = destination
        .parent()
        .context("destination must have a parent directory")?;
    fs::create_dir_all(parent)
        .with_context(|| format!("failed to create destination parent {}", parent.display()))?;
    let staging = TempBuilder::new()
        .prefix(".knowme-builder-stage-")
        .tempdir_in(parent)
        .context("failed to create staging directory")?;
    let staging_path = staging.path().to_path_buf();
    let app_name = destination
        .file_name()
        .and_then(|name| name.to_str())
        .context("destination must have a UTF-8 file name")?;

    let mut lock = GeneratedLock {
        schema_version: 1,
        builder_version: BUILDER_VERSION.to_owned(),
        files: Vec::new(),
    };
    render_dir(
        template,
        template,
        &staging_path,
        &RenderContext {
            app_name,
            profile: args.profile.as_str(),
            mode: args.mode.as_str(),
        },
        &mut lock,
    )?;
    if profile
        .surfaces
        .iter()
        .any(|surface| surface == "tauri-desktop")
    {
        install_command_manifest(&staging_path, &mut lock)?;
    }

    let project = ProjectManifest {
        schema_version: 1,
        profile: args.profile,
        builder_version: BUILDER_VERSION.to_owned(),
        required_prometheus_contract: PROMETHEUS_CONTRACT.to_owned(),
        uar_mode: profile.uar_mode.clone(),
        enabled_surfaces: profile.surfaces.clone(),
        generation_mode: args.mode,
        policy_overlay_path: ".knowme-builder/policy-overlay.toml".to_owned(),
        unsupported_surfaces: if matches!(args.mode, crate::cli::GenerationMode::Skeleton)
            || !profile.runnable_vertical_slice
        {
            profile.surfaces.clone()
        } else {
            Vec::new()
        },
    };
    write_project_state(&staging_path, &project, &lock, &manifest.skills)?;
    validate_generated_project(&staging_path)?;

    let retained_stage = staging.keep();
    if destination_state == DestinationState::Empty {
        fs::remove_dir(&destination).with_context(|| {
            format!(
                "failed to remove empty destination {}",
                destination.display()
            )
        })?;
    } else if destination_state == DestinationState::NonEmpty {
        let backup = backup_path(&destination)?;
        fs::rename(&destination, &backup).with_context(|| {
            format!(
                "failed to preserve existing destination as {}",
                backup.display()
            )
        })?;
        result.warnings.push(format!(
            "existing destination preserved at {}",
            backup.display()
        ));
    }
    fs::rename(&retained_stage, &destination)
        .with_context(|| format!("failed to atomically install {}", destination.display()))?;
    result.changed = true;
    Ok(result)
}

fn install_command_manifest(root: &Path, lock: &mut GeneratedLock) -> Result<()> {
    let source = TEMPLATES
        .get_file("command-contract/commands.json")
        .context("command contract is not packaged")?
        .contents();
    let relative = Path::new("desktop/src-tauri/command-manifest.json");
    atomic_write(&root.join(relative), source)?;
    lock.files.push(GeneratedFile {
        path: relative.to_string_lossy().into_owned(),
        template_id: "command-contract/commands.json".to_owned(),
        source_digest: digest(source),
        last_installed_digest: digest(source),
        ownership: Ownership::Builder,
        version: BUILDER_VERSION.to_owned(),
    });
    Ok(())
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum DestinationState {
    Missing,
    Empty,
    NonEmpty,
}

fn destination_state(path: &Path) -> Result<DestinationState> {
    if !path.exists() {
        return Ok(DestinationState::Missing);
    }
    if !path.is_dir() {
        return Ok(DestinationState::NonEmpty);
    }
    let mut entries =
        fs::read_dir(path).with_context(|| format!("failed to inspect {}", path.display()))?;
    Ok(if entries.next().is_none() {
        DestinationState::Empty
    } else {
        DestinationState::NonEmpty
    })
}

struct RenderContext<'a> {
    app_name: &'a str,
    profile: &'a str,
    mode: &'a str,
}

fn render_dir(
    root: &Dir<'_>,
    dir: &Dir<'_>,
    destination: &Path,
    context: &RenderContext<'_>,
    lock: &mut GeneratedLock,
) -> Result<()> {
    for entry in dir.entries() {
        match entry {
            DirEntry::Dir(child) => render_dir(root, child, destination, context, lock)?,
            DirEntry::File(file) => {
                let relative = file
                    .path()
                    .strip_prefix(root.path())
                    .context("template path escaped profile root")?;
                bundle::validate_relative_path(relative)?;
                let output_relative =
                    PathBuf::from(render_text(&relative.to_string_lossy(), context));
                bundle::validate_relative_path(&output_relative)?;
                let output = destination.join(&output_relative);
                if let Some(parent) = output.parent() {
                    fs::create_dir_all(parent)?;
                }
                let source = file.contents();
                let rendered = match std::str::from_utf8(source) {
                    Ok(text) => render_text(text, context).into_bytes(),
                    Err(_) => source.to_vec(),
                };
                let mut output_file = fs::File::create(&output)?;
                output_file.write_all(&rendered)?;
                output_file.sync_all()?;
                lock.files.push(GeneratedFile {
                    path: output_relative.to_string_lossy().into_owned(),
                    template_id: format!(
                        "profiles/{}/{}/{}",
                        context.profile,
                        context.mode,
                        relative.display()
                    ),
                    source_digest: digest(source),
                    last_installed_digest: digest(&rendered),
                    ownership: Ownership::Builder,
                    version: BUILDER_VERSION.to_owned(),
                });
            }
        }
    }
    Ok(())
}

fn render_text(input: &str, context: &RenderContext<'_>) -> String {
    let slug = slug(context.app_name);
    let crate_name = slug.replace('-', "_");
    input
        .replace("__APP_NAME__", context.app_name)
        .replace("__APP_SLUG__", &slug)
        .replace("__APP_CRATE__", &crate_name)
        .replace("__PROFILE__", context.profile)
        .replace("__MODE__", context.mode)
        .replace("__BUILDER_VERSION__", BUILDER_VERSION)
}

fn collect_template_paths(root: &Dir<'_>) -> Result<Vec<PathBuf>> {
    let mut paths = Vec::new();
    fn collect(root: &Dir<'_>, dir: &Dir<'_>, paths: &mut Vec<PathBuf>) -> Result<()> {
        for entry in dir.entries() {
            match entry {
                DirEntry::Dir(child) => collect(root, child, paths)?,
                DirEntry::File(file) => {
                    paths.push(file.path().strip_prefix(root.path())?.to_path_buf());
                }
            }
        }
        Ok(())
    }
    collect(root, root, &mut paths)?;
    paths.sort();
    Ok(paths)
}

fn write_project_state(
    root: &Path,
    project: &ProjectManifest,
    lock: &GeneratedLock,
    skills: &[String],
) -> Result<()> {
    let state_dir = root.join(".knowme-builder");
    fs::create_dir_all(&state_dir)?;
    atomic_write(
        &state_dir.join("project.toml"),
        toml::to_string_pretty(project)?.as_bytes(),
    )?;
    atomic_write(
        &state_dir.join("generated.lock.json"),
        format!("{}\n", serde_json::to_string_pretty(lock)?).as_bytes(),
    )?;
    atomic_write(
        &state_dir.join("activation-manifest.json"),
        bundle::activation_manifest(),
    )?;
    atomic_write(&root.join("skills-lock.json"), &skills_lock_bytes(skills)?)
}

fn skills_lock_bytes(skills: &[String]) -> Result<Vec<u8>> {
    let pinned_skills = skills
        .iter()
        .map(|skill| {
            let source = SKILLS
                .get_dir(skill)
                .with_context(|| format!("packaged skill is missing: {skill}"))?;
            Ok(serde_json::json!({
                "id": skill,
                "source": format!("builder:templates/project-skills/{skill}"),
                "version": BUILDER_VERSION,
                "digest": digest_embedded_dir(source)?
            }))
        })
        .collect::<Result<Vec<_>>>()?;
    let skills_lock = serde_json::json!({
        "schemaVersion": 1,
        "builder": {
            "id": "hybrid-mobile-architecture",
            "version": BUILDER_VERSION,
            "digest": digest(include_bytes!("../../../builder.manifest.json"))
        },
        "prometheus": {
            "contractVersion": PROMETHEUS_CONTRACT,
            "source": "external:prometheus-skill-pack",
            "contractDigest": digest(include_bytes!("../../../compatibility/prometheus-control-plane.json"))
        },
        "openSpec": {
            "source": "external",
            "version": "1.6.0"
        },
        "skills": pinned_skills
    });
    Ok(format!("{}\n", serde_json::to_string_pretty(&skills_lock)?).into_bytes())
}

fn skills_lock_bytes_preserving_third_party(skills: &[String], path: &Path) -> Result<Vec<u8>> {
    let mut generated: serde_json::Value = serde_json::from_slice(&skills_lock_bytes(skills)?)?;
    if path.is_file() {
        let existing: serde_json::Value = serde_json::from_slice(&fs::read(path)?)
            .with_context(|| format!("invalid existing skill lock {}", path.display()))?;
        let third_party = existing.get("thirdParty").cloned().or_else(|| {
            let version = existing.get("version")?.as_u64()?;
            let skills = existing.get("skills")?;
            skills.is_object().then(|| {
                serde_json::json!({
                    "schemaVersion": version,
                    "skills": skills
                })
            })
        });
        if let Some(third_party) = third_party {
            generated
                .as_object_mut()
                .expect("generated skill lock is an object")
                .insert("thirdParty".to_owned(), third_party);
        }
    }
    Ok(format!("{}\n", serde_json::to_string_pretty(&generated)?).into_bytes())
}

fn digest_embedded_dir(root: &Dir<'_>) -> Result<String> {
    let mut entries = Vec::new();
    fn collect(root: &Dir<'_>, dir: &Dir<'_>, entries: &mut Vec<(String, Vec<u8>)>) -> Result<()> {
        for entry in dir.entries() {
            match entry {
                DirEntry::Dir(child) => collect(root, child, entries)?,
                DirEntry::File(file) => entries.push((
                    file.path()
                        .strip_prefix(root.path())?
                        .to_string_lossy()
                        .into_owned(),
                    file.contents().to_vec(),
                )),
            }
        }
        Ok(())
    }
    collect(root, root, &mut entries)?;
    entries.sort_by(|left, right| left.0.cmp(&right.0));
    let mut hasher = Sha256::new();
    for (path, content) in entries {
        hasher.update(path.as_bytes());
        hasher.update([0]);
        hasher.update(content);
        hasher.update([0]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn validate_generated_project(root: &Path) -> Result<()> {
    for required in [
        ".knowme-builder/project.toml",
        ".knowme-builder/generated.lock.json",
        "skills-lock.json",
    ] {
        if !root.join(required).is_file() {
            bail!("staged project is missing required file {required}");
        }
    }
    Ok(())
}

fn atomic_write(path: &Path, content: &[u8]) -> Result<()> {
    let parent = path.parent().context("output path has no parent")?;
    fs::create_dir_all(parent)?;
    let mut temp = TempBuilder::new().prefix(".write-").tempfile_in(parent)?;
    temp.write_all(content)?;
    temp.as_file().sync_all()?;
    temp.persist(path)
        .map_err(|error| error.error)
        .with_context(|| format!("failed to atomically write {}", path.display()))?;
    Ok(())
}

fn digest(content: &[u8]) -> String {
    format!("{:x}", Sha256::digest(content))
}

fn slug(value: &str) -> String {
    value
        .chars()
        .map(|character| {
            if character.is_ascii_alphanumeric() {
                character.to_ascii_lowercase()
            } else {
                '-'
            }
        })
        .collect::<String>()
        .split('-')
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("-")
}

fn backup_path(destination: &Path) -> Result<PathBuf> {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .context("system clock is before Unix epoch")?
        .as_secs();
    let name = destination
        .file_name()
        .and_then(|value| value.to_str())
        .context("destination must have a UTF-8 file name")?;
    Ok(destination.with_file_name(format!("{name}.knowme-builder-backup-{seconds}")))
}

fn absolute_path(path: &Path) -> Result<PathBuf> {
    if path.is_absolute() {
        return Ok(path.to_path_buf());
    }
    Ok(std::env::current_dir()?.join(path))
}

fn print_result(result: &CommandResult, json: bool) -> Result<()> {
    if json {
        println!("{}", serde_json::to_string_pretty(result)?);
        return Ok(());
    }
    println!(
        "{}: {}",
        if result.changed { "changed" } else { "checked" },
        result.operation
    );
    if let Some(path) = &result.path {
        println!("path: {path}");
    }
    for action in &result.actions {
        println!("  {action}");
    }
    for warning in &result.warnings {
        eprintln!("warning: {warning}");
    }
    for conflict in &result.conflicts {
        eprintln!("conflict: {conflict}");
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::version_at_least;

    #[test]
    fn compares_control_plane_versions() {
        assert!(version_at_least("2.0.0", "2.0.0"));
        assert!(version_at_least("2.1.0", "2.0.0"));
        assert!(!version_at_least("1.99.0", "2.0.0"));
        assert!(!version_at_least("not-a-version", "2.0.0"));
    }
}
