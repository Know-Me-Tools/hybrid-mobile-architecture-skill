// TJ-ARCH-MOB-001 compliant
// Wire type + fold logic for gen_ui_types::events::A2uiEvent, emitted by
// tauri-plugin-gen-ui's chat_subscribe forwarder on the GEN_UI_CHAT_EVENT
// channel (see onChatEvent in the plugin's guest-js). Tauri serializes the
// Rust enum via serde as-is — `#[serde(tag = "type", rename_all =
// "snake_case")]` — so this type (and the fold below) must stay in lockstep
// with gen_ui_types::events::A2uiEvent's shape, not a speculative one.
import type { ContentBlock, MessageUsage } from './types'

export type A2uiEvent =
  | { type: 'run_started'; run_id: string }
  | { type: 'block'; block: ContentBlock }
  | { type: 'run_finished'; run_id: string }
  | { type: 'run_error'; message: string }

/** Fold one run's A2uiEvent onto its Message. `messageId` is the caller's
 * mapping from `run_id` to the assistant Message being streamed into (the
 * wire event itself carries no message id — only `run_id`, per the Rust
 * shape) — see chatStore.ts's sendMessage for the run_id -> messageId
 * association. */
export function applyA2uiEvent(
  event: A2uiEvent,
  messageId: string,
  streamBlock: (value: { messageId: string; block: ContentBlock }) => void,
  finalize: (messageId: string, usage?: MessageUsage) => void,
  onError?: (messageId: string, message: string) => void,
): void {
  switch (event.type) {
    case 'run_started':
      break
    case 'block':
      streamBlock({ messageId, block: event.block })
      break
    case 'run_finished':
      finalize(messageId)
      break
    case 'run_error':
      onError?.(messageId, event.message)
      finalize(messageId)
      break
  }
}
