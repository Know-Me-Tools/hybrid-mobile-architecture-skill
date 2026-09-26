// TJ-ARCH-MOB-001 compliant
import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);

// src/native-helpers/install-flutter.mts
import { existsSync as existsSync2, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { delimiter as delimiter2, dirname as dirname2, join as join2 } from "node:path";
import { spawnSync as spawnSync2 } from "node:child_process";

// src/native-helpers/common.mts
import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, realpathSync, statSync } from "node:fs";
import { delimiter, dirname, join, resolve } from "node:path";
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
function executable(name) {
  for (const dir of (process.env.PATH ?? "").split(delimiter)) {
    for (const suffix of process.platform === "win32" ? [".exe", ""] : [""]) {
      const candidate = join(dir, name + suffix);
      if (existsSync(candidate) && statSync(candidate).isFile()) return candidate;
    }
  }
  return void 0;
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

// src/native-helpers/install-flutter.mts
function vendor(file, args, cwd) {
  if (!file.endsWith(".bat")) {
    run(file, args, { cwd });
    return;
  }
  for (const token of [file, ...args]) assert(!/[&|<>^%!"\r\n\0]/.test(token), "vendor batch adapter refuses command expansion characters in SDK path or arguments");
  assert(["flutter.bat", "dart.bat"].some((name) => file.endsWith(name)), "unsupported vendor batch entrypoint");
  const result = spawnSync2(process.env.ComSpec ?? "cmd.exe", ["/d", "/v:off", "/s", "/c", `"${[file, ...args].map((token) => `"${token}"`).join(" ")}"`], { cwd, stdio: "inherit", shell: false, windowsVerbatimArguments: true });
  if (result.error || result.status !== 0) throw new ToolError(`Flutter vendor bootstrap failed: ${result.error?.message ?? result.status}`, result.status ?? 1);
}
await main(() => {
  assert(process.argv.length <= 3 && (!process.argv[2] || ["--fvm", "--help"].includes(process.argv[2])), "usage: node scripts/install-flutter.mjs [--fvm]");
  if (process.argv[2] === "--help") {
    console.log("node scripts/install-flutter.mjs [--fvm]\nInstalls/upgrades Flutter beta. Windows bootstrap uses the vendor flutter.bat with a restricted adapter.");
    return;
  }
  if (process.argv[2] === "--fvm") {
    const dart = executable("dart") ?? (process.env.PATH ?? "").split(delimiter2).map((dir) => join2(dir, "dart.bat")).find(existsSync2);
    assert(dart, "Dart is required to install FVM");
    vendor(dart, ["pub", "global", "activate", "fvm"]);
    for (const args of [["install", "beta"], ["global", "beta"], ["flutter", "--version"]]) vendor(dart, ["pub", "global", "run", "fvm:fvm", ...args]);
    console.log(`Add ${join2(homedir(), ".pub-cache/bin")} to PATH. Use fvm flutter <command>.`);
    return;
  }
  const sdk = join2(homedir(), "development/flutter"), flutter = join2(sdk, "bin", process.platform === "win32" ? "flutter.bat" : "flutter");
  if (existsSync2(sdk)) {
    assert(existsSync2(join2(sdk, ".git")), `existing Flutter directory is not a Git checkout: ${sdk}`);
    if (existsSync2(join2(sdk, ".git/shallow"))) run("git", ["fetch", "--unshallow", "origin"], { cwd: sdk });
    run("git", ["fetch", "origin"], { cwd: sdk });
    vendor(flutter, ["channel", "beta"], sdk);
    vendor(flutter, ["upgrade"], sdk);
  } else {
    mkdirSync(dirname2(sdk), { recursive: true });
    run("git", ["clone", "https://github.com/flutter/flutter.git", "-b", "beta", sdk]);
  }
  process.env.PATH = `${join2(sdk, "bin")}${delimiter2}${process.env.PATH ?? ""}`;
  vendor(flutter, ["doctor", "--no-color"], sdk);
  vendor(flutter, ["--version"], sdk);
  console.log(`Permanently add ${join2(sdk, "bin")} to PATH. Then run flutter doctor --android-licenses.`);
});
