// TJ-ARCH-MOB-001 compliant
import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);

// src/native-helpers/verify-tauri-ui-restart.mts
import { spawn, spawnSync } from "node:child_process";
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, statSync } from "node:fs";
import { createServer } from "node:net";
import { join, resolve } from "node:path";
import { setTimeout as delay } from "node:timers/promises";

// src/native-helpers/common.mts
var ToolError = class extends Error {
  constructor(message, code = 1) {
    super(message);
    this.code = code;
  }
  code;
};
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

// src/native-helpers/verify-tauri-ui-restart.mts
async function stopTree(child) {
  if (!child.pid) return;
  if (process.platform === "win32") {
    spawnSync("taskkill.exe", ["/PID", String(child.pid), "/T", "/F"], {
      stdio: "ignore",
      shell: false
    });
    return;
  }
  try {
    process.kill(-child.pid, "SIGTERM");
  } catch {
    return;
  }
  for (let attempt = 0; attempt < 5; attempt++) {
    await delay(500);
    try {
      process.kill(-child.pid, 0);
    } catch {
      return;
    }
  }
  try {
    process.kill(-child.pid, "SIGKILL");
  } catch {
  }
}
async function waitFor(description, deadline, operation) {
  let last;
  while (Date.now() < deadline) {
    try {
      return await operation();
    } catch (error) {
      last = error;
    }
    await delay(250);
  }
  throw new Error(`${description} did not become ready: ${last instanceof Error ? last.message : String(last)}`);
}
async function reservePort() {
  const server = createServer();
  await new Promise((resolveListen, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolveListen);
  });
  const address = server.address();
  assert(address !== null && typeof address === "object", "Unable to reserve a WebView2 debug port");
  await new Promise((resolveClose, reject) => server.close((error) => error ? reject(error) : resolveClose()));
  return address.port;
}
async function findTarget(port, deadline, app, startupError) {
  return waitFor("WebView2 DevTools target", deadline, async () => {
    assert(!startupError(), `Tauri application failed to launch: ${startupError()?.message}`);
    assert(
      app.exitCode === null && app.signalCode === null,
      "Tauri application exited before exposing its UI"
    );
    const response = await fetch(`http://127.0.0.1:${port}/json/list`, {
      signal: AbortSignal.timeout(1e3)
    });
    assert(response.ok, `DevTools target discovery failed (${response.status})`);
    const targets = await response.json();
    const target = targets.find((candidate) => candidate.type === "page" && candidate.webSocketDebuggerUrl);
    assert(Boolean(target?.webSocketDebuggerUrl), "WebView2 has no page target yet");
    return target.webSocketDebuggerUrl;
  });
}
var CdpSession = class _CdpSession {
  #socket;
  #pending = /* @__PURE__ */ new Map();
  #nextId = 1;
  constructor(socket) {
    this.#socket = socket;
    socket.addEventListener("message", (event) => {
      if (typeof event.data !== "string") return;
      const reply = JSON.parse(event.data);
      if (typeof reply.id !== "number") return;
      const pending = this.#pending.get(reply.id);
      if (!pending) return;
      this.#pending.delete(reply.id);
      globalThis.clearTimeout(pending.timer);
      if (reply.error) {
        pending.reject(new Error(`CDP request failed: ${reply.error.message ?? "unknown error"}`));
      } else {
        pending.resolve(reply.result);
      }
    });
    socket.addEventListener("close", () => {
      for (const pending of this.#pending.values()) {
        globalThis.clearTimeout(pending.timer);
        pending.reject(new Error("WebView2 DevTools connection closed"));
      }
      this.#pending.clear();
    });
  }
  static async connect(url, deadline) {
    const socket = new WebSocket(url);
    await new Promise((resolveOpen, reject) => {
      const timer = globalThis.setTimeout(
        () => reject(new Error("WebView2 DevTools connection timed out")),
        Math.max(1, deadline - Date.now())
      );
      socket.addEventListener("open", () => {
        globalThis.clearTimeout(timer);
        resolveOpen();
      }, { once: true });
      socket.addEventListener("error", () => {
        globalThis.clearTimeout(timer);
        reject(new Error("WebView2 DevTools connection failed"));
      }, { once: true });
    });
    const session = new _CdpSession(socket);
    await session.call("Runtime.enable", {}, deadline);
    return session;
  }
  call(method, params, deadline) {
    const id = this.#nextId++;
    return new Promise((resolveCall, reject) => {
      const timer = globalThis.setTimeout(() => {
        this.#pending.delete(id);
        reject(new Error(`CDP ${method} timed out`));
      }, Math.max(1, deadline - Date.now()));
      this.#pending.set(id, { resolve: resolveCall, reject, timer });
      this.#socket.send(JSON.stringify({ id, method, params }));
    });
  }
  async evaluate(expression, deadline) {
    const response = await this.call("Runtime.evaluate", {
      expression,
      awaitPromise: true,
      returnByValue: true
    }, deadline);
    if (response.exceptionDetails) {
      throw new Error(response.exceptionDetails.exception?.description ?? response.exceptionDetails.text ?? "WebView2 evaluation failed");
    }
    return response.result?.value;
  }
  close() {
    this.#socket.close();
  }
};
async function waitForUi(session, deadline) {
  await waitFor("rendered notes UI", deadline, async () => {
    const ready = await session.evaluate(
      `Boolean(document.querySelector('[data-testid="note-input"]') && document.querySelector('[data-testid="saved-notes"]'))`,
      deadline
    );
    assert(ready, "notes UI is not rendered");
  });
}
async function createNote(session, title, deadline) {
  const encoded = JSON.stringify(title);
  const updated = await session.evaluate(`(() => {
    const input = document.querySelector('[data-testid="note-input"]');
    if (!(input instanceof HTMLInputElement)) return false;
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
    if (!setter) return false;
    setter.call(input, ${encoded});
    input.dispatchEvent(new Event('input', { bubbles: true, composed: true }));
    return true;
  })()`, deadline);
  assert(updated, "Unable to enter a note through the rendered UI");
  await waitFor("React note state", deadline, async () => {
    const value = await session.evaluate(
      `document.querySelector('[data-testid="note-input"]')?.value ?? null`,
      deadline
    );
    assert(value === title, `note input contains ${JSON.stringify(value)}`);
  });
  const clicked = await session.evaluate(`(() => {
    const button = document.querySelector('[data-testid="save-note"]');
    if (!(button instanceof HTMLButtonElement) || button.disabled) return false;
    button.click();
    return true;
  })()`, deadline);
  assert(clicked, "Unable to invoke note creation through the rendered UI");
}
async function waitForNote(session, title, deadline) {
  await waitFor(`persisted note ${title}`, deadline, async () => {
    const values = await session.evaluate(
      `[...document.querySelectorAll('[data-testid="saved-notes"] li')].map(node => node.textContent ?? '')`,
      deadline
    );
    assert(values.includes(title), `note not visible; found ${JSON.stringify(values)}`);
  });
}
async function launchAndInspect(binary, data, profile, log, deadline, inspect) {
  mkdirSync(profile, { recursive: true });
  const port = await reservePort();
  const handle = openSync(log, "w");
  const app = spawn(binary, [], {
    env: {
      ...process.env,
      APP_DATA_DIR: data,
      GEN_UI_APP_DATA_DIR: data,
      TAURI_WEBVIEW_AUTOMATION: "true",
      WEBVIEW2_USER_DATA_FOLDER: profile,
      WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS: [
        process.env.WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS,
        `--remote-debugging-port=${port}`,
        "--remote-allow-origins=*"
      ].filter(Boolean).join(" ")
    },
    stdio: ["ignore", handle, handle],
    detached: process.platform !== "win32",
    shell: false
  });
  closeSync(handle);
  let startupError;
  app.on("error", (error) => {
    startupError = error;
  });
  let session;
  try {
    const target = await findTarget(port, deadline, app, () => startupError);
    session = await CdpSession.connect(target, deadline);
    await waitForUi(session, deadline);
    await inspect(session);
  } catch (error) {
    if (existsSync(log)) {
      console.error(readFileSync(log, "utf8").split(/\r?\n/).slice(-200).join("\n"));
    }
    throw error;
  } finally {
    session?.close();
    await stopTree(app);
  }
}
await main(async () => {
  assert(
    process.argv.length >= 4 && process.argv.length <= 5,
    "node scripts/verify-tauri-ui-restart.mjs <binary> <empty-app-data-dir> [timeout-seconds]",
    2
  );
  const binary = resolve(process.argv[2]);
  const data = resolve(process.argv[3]);
  const seconds = Number(process.argv[4] ?? 240);
  assert(process.platform === "win32", "Packaged Tauri UI relaunch proof requires native Windows", 2);
  assert(existsSync(binary) && statSync(binary).isFile(), `Tauri binary is not a file: ${binary}`, 2);
  assert(!existsSync(data), `App-data proof directory must not already exist: ${data}`, 2);
  assert(Number.isFinite(seconds) && seconds > 0, "timeout must be positive", 2);
  mkdirSync(data, { recursive: true });
  const deadline = Date.now() + seconds * 1e3;
  const title = `WebView2 persistence ${Date.now()}`;
  await launchAndInspect(
    binary,
    data,
    join(data, "webview-first"),
    join(data, "tauri-first.log"),
    deadline,
    async (session) => {
      await createNote(session, title, deadline);
      await waitForNote(session, title, deadline);
    }
  );
  await delay(750);
  await launchAndInspect(
    binary,
    data,
    join(data, "webview-second"),
    join(data, "tauri-second.log"),
    deadline,
    (session) => waitForNote(session, title, deadline)
  );
  assert(
    existsSync(join(data, "notes.sqlite3")),
    "UI workflow did not create the persisted SQLite database"
  );
  process.stdout.write(
    `PASS: packaged Tauri UI -> invoke -> Rust -> SQLite survived application relaunch
app_data=${data}
`
  );
});
