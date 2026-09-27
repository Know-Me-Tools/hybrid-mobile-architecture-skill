// TJ-ARCH-MOB-001 compliant
import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);

// src/native-helpers/verify-flutter-ios-restart.mts
import { existsSync, readFileSync, rmSync } from "node:fs";
import { join, resolve } from "node:path";
import { randomUUID } from "node:crypto";

// src/native-helpers/common.mts
import { spawnSync } from "node:child_process";
var ToolError = class extends Error {
  constructor(message, code = 1) {
    super(message);
    this.code = code;
  }
  code;
};
function run(command, args, options = {}) {
  const result = spawnSync(command, args, { cwd: options.cwd, env: options.env ?? process.env, encoding: "utf8", stdio: options.capture ? ["ignore", "pipe", "pipe"] : "inherit", shell: false, maxBuffer: 64 * 1024 * 1024 });
  if (result.error) throw new ToolError(`required tool failed: ${command}: ${result.error.message}`, 127);
  if (result.status !== 0 && !options.allowFailure) throw new ToolError(`${command} failed (${result.status ?? result.signal})${result.stderr ? `: ${result.stderr.trim()}` : ""}`, result.status ?? 1);
  return result.status === 0 ? result.stdout ?? "" : "";
}
function assert(condition, message, code = 1) {
  if (!condition) throw new ToolError(message, code);
}
async function main(fn) {
  try {
    await fn();
  } catch (error) {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = error instanceof ToolError ? error.code : 1;
  }
}

// src/native-helpers/verify-flutter-ios-restart.mts
await main(async () => {
  assert(process.argv.length >= 3 && process.argv.length <= 6, "node scripts/verify-flutter-ios-restart.mjs <flutter-project> [--ios-app <application-binary> | <android-device-id> <application-apk> <test-apk>]", 2);
  const project = resolve(process.argv[2]);
  const requestedMode = process.argv[3];
  const applicationBinary = process.argv[4] ? resolve(process.argv[4]) : void 0;
  if (requestedMode && requestedMode !== "--ios-app") {
    const existingDevice = requestedMode;
    const testBinary = process.argv[5] ? resolve(process.argv[5]) : void 0;
    assert(Boolean(applicationBinary) && Boolean(testBinary), "existing-device verification requires prebuilt application and instrumentation APKs", 2);
    const buildConfig = readFileSync(resolve(project, "android/app/build.gradle.kts"), "utf8");
    const applicationId = /applicationId\s*=\s*"([^"]+)"/.exec(buildConfig)?.[1];
    assert(Boolean(applicationId), "Android build configuration omitted applicationId");
    run("adb", ["-s", existingDevice, "install", "-r", applicationBinary]);
    run("adb", ["-s", existingDevice, "install", "-r", testBinary]);
    run("adb", ["-s", existingDevice, "shell", "pm", "clear", applicationId]);
    const instrumentationInventory = run("adb", ["-s", existingDevice, "shell", "pm", "list", "instrumentation"], { capture: true });
    const instrumentation = instrumentationInventory.split(/\r?\n/).map((line) => /^instrumentation:([^\s]+)\s+\(target=([^\)]+)\)$/.exec(line.trim())).find((match) => match?.[2] === applicationId)?.[1];
    assert(Boolean(instrumentation), `No installed Android instrumentation targets ${applicationId}`);
    const executeInstrumentation = (verifyRestart = false) => {
      const restartArguments = verifyRestart ? ["-e", "verifyRestart", "true"] : [];
      const output = run("adb", ["-s", existingDevice, "shell", "am", "instrument", "-w", "-r", ...restartArguments, instrumentation], { capture: true });
      process.stdout.write(output);
      assert(!/(?:FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed)/.test(output), "Android instrumentation reported a test failure");
      assert(/^\s*OK \(\d+ tests?\)\s*$/m.test(output), "Android instrumentation did not report a passing test suite");
    };
    executeInstrumentation(false);
    run("adb", ["-s", existingDevice, "shell", "am", "force-stop", applicationId]);
    executeInstrumentation(true);
    process.stdout.write(`PASS: Flutter UI -> Rust FFI -> SQLite -> application relaunch recovery on device ${existingDevice}
`);
    return;
  }
  assert(process.platform === "darwin", "managed iOS simulator verification requires macOS", 2);
  assert(requestedMode === "--ios-app" && Boolean(applicationBinary), "managed iOS verification requires --ios-app <application-binary>", 2);
  assert(applicationBinary.endsWith(".app"), "managed iOS application binary must be an .app bundle", 2);
  const bundleId = run("plutil", ["-extract", "CFBundleIdentifier", "raw", "-o", "-", resolve(applicationBinary, "Info.plist")], { capture: true }).trim();
  assert(Boolean(bundleId), "iOS application bundle omitted CFBundleIdentifier");
  const inventory = JSON.parse(run("xcrun", ["simctl", "list", "--json"], { capture: true }));
  const compatible = inventory.runtimes?.filter((item) => item.identifier && item.isAvailable !== false && /^iOS /.test(item.name ?? "")).flatMap((runtime) => (inventory.devices?.[runtime.identifier] ?? []).filter((device) => device.isAvailable !== false && device.deviceTypeIdentifier && /^iPhone /.test(device.name ?? "")).map((device) => ({ runtime, device }))).at(-1);
  assert(Boolean(compatible?.runtime.identifier), "No available iOS simulator runtime with a compatible iPhone device");
  assert(Boolean(compatible?.device.deviceTypeIdentifier), "Compatible iPhone simulator omitted its device type identifier");
  const name = `knowme-builder-cert-${randomUUID()}`;
  const id = run("xcrun", ["simctl", "create", name, compatible.device.deviceTypeIdentifier, compatible.runtime.identifier], { capture: true }).trim();
  assert(Boolean(id), "simctl did not return a device identifier");
  try {
    run("xcrun", ["simctl", "boot", id]);
    run("xcrun", ["simctl", "bootstatus", id, "-b"]);
    run("xcrun", ["simctl", "install", id, applicationBinary]);
    const dataContainer = run("xcrun", ["simctl", "get_app_container", id, bundleId, "data"], { capture: true }).trim();
    assert(Boolean(dataContainer), "simctl did not return the installed application data container");
    const firstMarker = join(dataContainer, "tmp", "knowme-builder-first-pass");
    const marker = join(dataContainer, "tmp", "knowme-builder-restart-pass");
    const waitForIosMarker = async (path, expected, failure) => {
      const deadline = Date.now() + 5 * 60 * 1e3;
      while (!existsSync(path) && Date.now() < deadline) {
        await new Promise((resolveDelay) => setTimeout(resolveDelay, 1e3));
      }
      assert(existsSync(path), failure);
      assert(readFileSync(path, "utf8") === expected, `invalid rendered-state marker: ${path}`);
    };
    rmSync(firstMarker, { force: true });
    rmSync(marker, { force: true });
    run("xcrun", ["simctl", "launch", id, bundleId]);
    await waitForIosMarker(firstMarker, "PASS: rendered and persisted note after first launch\n", "first iOS application process did not publish its rendered-state marker within five minutes");
    run("xcrun", ["simctl", "terminate", id, bundleId]);
    run("xcrun", ["simctl", "launch", id, bundleId, "--route=/verify-restart"]);
    await waitForIosMarker(marker, "PASS: rendered persisted note after relaunch\n", "restarted iOS application did not publish its rendered-state marker within five minutes");
    process.stdout.write(`PASS: Flutter UI -> Rust FFI -> SQLite -> application relaunch recovery on simulator ${id}
`);
  } finally {
    run("xcrun", ["simctl", "shutdown", id], { allowFailure: true });
    run("xcrun", ["simctl", "delete", id], { allowFailure: true });
  }
});
