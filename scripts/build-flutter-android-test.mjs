// TJ-ARCH-MOB-001 compliant
import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);

// src/native-helpers/build-flutter-android-test.mts
import { existsSync } from "node:fs";
import { resolve } from "node:path";

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

// src/native-helpers/build-flutter-android-test.mts
await main(() => {
  assert(process.argv.length === 3, "node scripts/build-flutter-android-test.mjs <flutter-project>", 2);
  const project = resolve(process.argv[2]);
  const android = resolve(project, "android");
  const wrapper = resolve(android, "gradle/wrapper/gradle-wrapper.jar");
  assert(existsSync(wrapper), `Gradle wrapper JAR is missing: ${wrapper}`);
  run("java", [
    "-classpath",
    wrapper,
    "org.gradle.wrapper.GradleWrapperMain",
    "app:assembleAndroidTest"
  ], { cwd: android });
});
