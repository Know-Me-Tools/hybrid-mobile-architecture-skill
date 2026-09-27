import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyPathExact } from './support.mjs';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const invoke = (script, args, options = {}) => spawnSync(process.execPath, [script, ...args], { encoding: 'utf8', ...options });

test('standalone progress payload records mirrored wiki and valid events with private-root override', () => {
  const root = mkdtempSync(join(tmpdir(), 'helper ü space-'));
  try {
    const app = join(root, 'Existing App'); mkdirSync(app);
    assert.equal(spawnSync('git', ['init', app]).status, 0);
    const script = join(root, 'record-progress.mjs');
    copyPathExact(join(repo, 'skills/karpathy-progress-memory/scripts/record-progress.mjs'), script);
    const result = invoke(script, ['--phase', 'native', '--title', 'Portable "helpers"', '--summary', `Updated ${app}`, '--evidence', 'Built and exercised', '--next', 'Windows runner'], { cwd: app, env: { ...process.env, PROMETHEUS_PRIVATE_ROOT: join(root, 'private') } });
    assert.equal(result.status, 0, result.stderr);
    const [local, privateCopy] = result.stdout.trim().split(/\r?\n/);
    assert.equal(readFileSync(local, 'utf8'), readFileSync(privateCopy, 'utf8'));
    const progress = readFileSync(local, 'utf8');
    assert.ok(progress.includes('Updated $REPO_ROOT'), `progress entry retained an absolute repository alias:\n${progress}`);
    const event = JSON.parse(readFileSync(join(app, '.prometheus/events.jsonl'), 'utf8'));
    assert.equal(event.project_root, '$REPO_ROOT');
    assert.equal(event.payload.title, 'Portable "helpers"');
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('progress validation fails before creating directories for secrets or invalid phase', () => {
  const root = mkdtempSync(join(tmpdir(), 'helper rejected-'));
  try {
    const script = join(repo, 'skills/karpathy-progress-memory/scripts/record-progress.mjs');
    const args = ['--phase', 'valid', '--title', 'Change', '--summary', 'api_key=do-not-store', '--evidence', 'evidence', '--next', 'next'];
    const secret = invoke(script, args, { cwd: root });
    assert.equal(secret.status, 3, secret.stderr);
    args[1] = '../escape'; args[5] = 'safe';
    assert.equal(invoke(script, args, { cwd: root }).status, 2);
    args[1] = 'valid'; args.push('--status', '../escape');
    assert.equal(invoke(script, args, { cwd: root }).status, 2);
    assert.ok(!existsSync(join(root, '.prometheus')));
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('Docusaurus refuses an existing destination and platform helpers reject malformed invocations', () => {
  const root = mkdtempSync(join(tmpdir(), 'existing site ü-'));
  try {
    const result = invoke(join(repo, 'skills/build-branded-docusaurus/scripts/scaffold.mjs'), [root, 'Site', 'https://example.com', '/']);
    assert.equal(result.status, 1); assert.match(result.stderr, /refusing to overwrite/);
    assert.equal(invoke(join(repo, 'assets/templates/scripts/android/build.mjs'), ['production']).status, 64);
    assert.equal(invoke(join(repo, 'assets/templates/scripts/android/verify-device-runtime-gates.mjs'), []).status, 64);
    assert.equal(invoke(join(repo, 'assets/templates/scripts/android/verify-native-inference-gates.mjs'), ['missing.apk'], { env: { ...process.env, KNOWME_PLATFORM_NATIVE: join(root, 'absent-native-binary') } }).status, 127);
    assert.equal(invoke(join(repo, 'scripts/verify-tauri-ui-restart.mjs'), []).status, 2);
    assert.equal(invoke(join(repo, 'scripts/verify-flutter-ios-restart.mjs'), [root, 'emulator-5554']).status, 2);
    assert.equal(invoke(join(repo, 'scripts/install-tauri-webdriver.mjs'), ['--check']).status, 0);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('generated Flutter and Rust bridge sources receive deterministic architecture markers', () => {
  const root = mkdtempSync(join(tmpdir(), 'generated markers-'));
  try {
    const dart = join(root, 'mobile/lib/bridge/generated/api/notes.dart');
    const riverpod = join(root, 'mobile/lib/features/notes/providers/notes.g.dart');
    const rust = join(root, 'rust/gen_ui_ffi/src/frb_generated.rs');
    for (const path of [dart, riverpod, rust]) { mkdirSync(dirname(path), { recursive: true }); writeFileSync(path, '// generated\n'); }
    const script = join(repo, 'scripts/mark-generated-sources.mjs');
    assert.equal(invoke(script, [root]).status, 0);
    assert.equal(invoke(script, [root, '--check']).status, 0);
    for (const path of [dart, riverpod, rust]) assert.match(readFileSync(path, 'utf8'), /^\/\/ TJ-ARCH-MOB-001 compliant\n\/\/ generated\n$/);
    assert.equal(invoke(script, [root]).status, 0);
    for (const path of [dart, riverpod, rust]) assert.equal(readFileSync(path, 'utf8').match(/TJ-ARCH-MOB-001/g)?.length, 1);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('native mobile workflow prebuilds the integration test entrypoint used by exact binaries', () => {
  const workflow = readFileSync(join(repo, '.github/workflows/scaffold-ci.yml'), 'utf8');
  assert.match(workflow, /flutter build ios --simulator --debug --no-codesign --target integration_test\/notes_test\.dart/);
  assert.match(workflow, /flutter build apk --debug --target-platform android-arm64 --target integration_test\/notes_test\.dart/);
  assert.match(workflow, /runs-on: macos-15\b/);
  assert.match(workflow, /targets: aarch64-apple-ios-sim,aarch64-linux-android/);
  assert.match(workflow, /api-level: 30[\s\S]*arch: arm64-v8a/);
  assert.doesNotMatch(workflow, /API 35 x86_64|arch: x86_64/);
  assert.match(workflow, /--ios-app .*Runner\.app/);
  assert.match(workflow, /emulator-5554 .*app-debug\.apk/);
});

test('iOS restart proof couples the rendered-state marker to the direct relaunch', () => {
  const helper = readFileSync(join(repo, 'runtime/src/native-helpers/verify-flutter-ios-restart.mts'), 'utf8');
  const integrationTest = readFileSync(join(repo, 'assets/templates/baselines/flutter/mobile/integration_test/notes_test.dart'), 'utf8');
  assert.match(helper, /simctl', 'install', id, applicationBinary!/);
  assert.match(helper, /simctl', 'get_app_container'/);
  assert.match(helper, /simctl', 'launch', id, bundleId\][\s\S]*waitForIosMarker\(firstMarker/);
  assert.match(helper, /simctl', 'launch'.*--route=\/verify-restart/);
  assert.match(helper, /first iOS application process did not publish its rendered-state marker within five minutes/);
  assert.match(helper, /restarted iOS application did not publish its rendered-state marker within five minutes/);
  assert.match(integrationTest, /expect\(find\.text\(title\), findsAtLeastNWidgets\(1\)\);[\s\S]*knowme-builder-restart-pass/);
  assert.match(integrationTest, /PASS: rendered persisted note after relaunch/);
});

test('Android restart proof couples the rendered-state marker to the direct relaunch', () => {
  const helper = readFileSync(join(repo, 'runtime/src/native-helpers/verify-flutter-ios-restart.mts'), 'utf8');
  const integrationTest = readFileSync(join(repo, 'assets/templates/baselines/flutter/mobile/integration_test/notes_test.dart'), 'utf8');
  assert.match(helper, /'install', '-r', applicationBinary!/);
  assert.match(helper, /shell', 'pm', 'clear', applicationId!/);
  assert.match(helper, /launch\(\);[\s\S]*waitForMarker\(firstMarker, 'PASS: rendered and persisted note after first launch/);
  assert.match(helper, /launch\('\/verify-restart'\);[\s\S]*waitForMarker\(androidMarker, 'PASS: rendered persisted note after relaunch/);
  assert.match(helper, /shell', 'run-as', applicationId!, 'cat', marker/);
  assert.match(helper, /first Android application process did not publish its rendered-state marker within five minutes/);
  assert.match(helper, /restarted Android application did not publish its rendered-state marker within five minutes/);
  assert.match(integrationTest, /knowme-builder-first-pass/);
  assert.match(integrationTest, /knowme-builder-restart-pass/);
});

test('standalone canonical and project-template skills have identical portable scripts', () => {
  for (const [skill, scripts] of [['build-branded-docusaurus', ['scaffold', 'verify', 'build-site']], ['karpathy-progress-memory', ['record-progress']]]) {
    for (const script of scripts) assert.deepEqual(readFileSync(join(repo, 'skills', skill, 'scripts', `${script}.mjs`)), readFileSync(join(repo, 'templates/project-skills', skill, 'scripts', `${script}.mjs`)));
  }
});
