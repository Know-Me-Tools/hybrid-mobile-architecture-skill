import assert from "node:assert/strict";
import test from "node:test";
import { registerAgentRunTransport } from "../src/entity-transport.mjs";

test("uses the governed BFF instead of a raw UAR or MCP transport", async () => {
  const transport = registerAgentRunTransport({
    endpoint: "http://bff.invalid",
    fetchImpl: async (url) => ({ ok: true, json: async () => [{ url }] }),
  });
  const events = await transport.create({ message: "hello", idempotencyId: "c1" });
  assert.match(events[0].url, /\/api\/v1\/agent\/runs$/);
});
