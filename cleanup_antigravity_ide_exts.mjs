// TJ-ARCH-MOB-001 compliant
import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);

// src/native-helpers/cleanup-antigravity-ide-exts.mts
import { existsSync as existsSync2, lstatSync, readdirSync as readdirSync2, rmSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

// src/native-helpers/common.mts
import { existsSync, readdirSync, readFileSync, realpathSync, statSync } from "node:fs";
var ToolError = class extends Error {
  constructor(message, code = 1) {
    super(message);
    this.code = code;
  }
  code;
};
function text(path) {
  return readFileSync(path, "utf8");
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

// src/native-helpers/cleanup-antigravity-ide-exts.mts
await main(() => {
  const args = process.argv.slice(2);
  let root = join(homedir(), ".antigravity-ide/extensions"), apply = false;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--apply") apply = true;
    else if (args[i] === "--dry-run") apply = false;
    else if (args[i] === "--root") {
      assert(args[i + 1], "--root requires a path");
      root = resolve(args[++i]);
    } else {
      assert(args[i] === "--help", `unknown option ${args[i]}`);
      console.log("node cleanup_antigravity_ide_exts.mjs [--root DIR] [--dry-run|--apply]\nDefault: preview only. --apply removes older duplicate extension versions.");
      return;
    }
  }
  assert(existsSync2(root) && lstatSync(root).isDirectory(), `extension root missing or symlink: ${root}`);
  const groups = /* @__PURE__ */ new Map(), skipped = [];
  for (const dir of readdirSync2(root, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (!dir.isDirectory()) continue;
    const path = join(root, dir.name);
    let id, version;
    try {
      const pkg = JSON.parse(text(join(path, "package.json")));
      if (typeof pkg.publisher === "string" && typeof pkg.name === "string") id = `${pkg.publisher}.${pkg.name}`;
      if (typeof pkg.version === "string") version = pkg.version;
    } catch {
    }
    const fallback = /^(.*)-(\d[^/]*)$/.exec(dir.name);
    if (fallback) {
      id ??= fallback[1];
      version ??= fallback[2];
    }
    if (!id || !version) {
      skipped.push(dir.name);
      continue;
    }
    const list = groups.get(id) ?? [];
    list.push({ path, directory: dir.name, version, obsolete: existsSync2(join(path, ".obsolete")) });
    groups.set(id, list);
  }
  const key = (version) => version.trim().replace(/^[vV]+/, "").split(".").map((part) => Number(/^\d+/.exec(part)?.[0] ?? 0));
  const size = (dir) => readdirSync2(dir, { withFileTypes: true }).reduce((sum, entry) => {
    const path = join(dir, entry.name);
    return sum + (entry.isDirectory() ? size(path) : lstatSync(path).size);
  }, 0);
  let freed = 0;
  for (const [id, group] of [...groups].sort(([a], [b]) => a.localeCompare(b))) {
    if (group.length < 2) continue;
    group.sort((a, b) => {
      const x = key(a.version), y = key(b.version);
      for (let i = 0; i < Math.max(x.length, y.length, 3); i++) if ((x[i] ?? 0) !== (y[i] ?? 0)) return (x[i] ?? 0) - (y[i] ?? 0);
      return 0;
    });
    for (const entry of group.slice(0, -1)) {
      const bytes = size(entry.path);
      let status = "WOULD DELETE";
      if (apply) try {
        rmSync(entry.path, { recursive: true });
        status = "deleted";
        freed += bytes;
      } catch (error) {
        status = `FAILED: ${error}`;
        process.exitCode = 1;
      }
      console.log(`${id} v${entry.version} | ${entry.directory} | ${(bytes / 1024 ** 2).toFixed(1)} MB | ${status}${entry.obsolete ? " [had .obsolete]" : ""}`);
    }
    const newest = group.at(-1);
    console.log(`${id} v${newest.version} | ${newest.directory} | KEPT (newest)`);
  }
  if (skipped.length) console.log(`Dirs skipped (no parsable id/version):
${skipped.join("\n")}`);
  console.log(`TOTAL FREED: ${(freed / 1024 ** 2).toFixed(1)} MB (${(freed / 1024 ** 3).toFixed(2)} GB)${apply ? "" : " \u2014 dry run; no files removed"}`);
});
