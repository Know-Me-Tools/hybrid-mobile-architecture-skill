// TJ-ARCH-MOB-001 compliant
// Guest bindings for tauri-plugin-gen-ui. Typed wrappers over the plugin's
// commands + typed listeners for its event channels.
//
// LAYER CONTRACT (TJ-ARCH-MOB-001): call these ONLY from Zustand stores — never
// from a React component or hook. Components import hooks; hooks compose stores;
// stores own invoke()/listen().
import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";

// Command names are prefixed by the plugin ("gen-ui") — Tauri maps them to
// "plugin:gen-ui|<command>".
const cmd = (name: string) => `plugin:gen-ui|${name}`;

// --- Mirrored gen_ui_types shapes (kept in lockstep with the Rust seams) -----
export interface EntityRecord {
  id: string;
  entityType: string;
  dataJson: string;
}
export interface ListResult {
  items: EntityRecord[];
  nextCursor: string | null;
}
export type FilterOp = "eq" | "ne" | "lt" | "lte" | "gt" | "gte" | "in" | "like";
export interface FilterSpec {
  field: string;
  op: FilterOp;
  valueJson: string;
}
export interface SortSpec {
  field: string;
  descending: boolean;
}
export interface ViewDescriptor {
  entityType: string;
  filters: FilterSpec[];
  sorts: SortSpec[];
  limit: number | null;
  cursor: string | null;
}

// --- Command wrappers --------------------------------------------------------
export function chatSend(threadId: string, message: string): Promise<string> {
  return invoke<string>(cmd("chat_send"), { threadId, message });
}
// Attaches the forwarder that emits CHAT_EVENT for this run_id. Call this
// (and start listening on onChatEvent) as soon as possible after chatSend
// resolves — chat_send's producer task can finish and deregister before this
// attaches for very fast responses/errors (see chatStore.ts sendMessage for
// how the residual race window is minimised on the caller side).
export function chatSubscribe(runId: string): Promise<void> {
  return invoke<void>(cmd("chat_subscribe"), { runId });
}
export function entityList(view: ViewDescriptor): Promise<ListResult> {
  return invoke<ListResult>(cmd("entity_list"), { view });
}
export function entityGet(entityType: string, id: string): Promise<EntityRecord | null> {
  return invoke<EntityRecord | null>(cmd("entity_get"), { entityType, id });
}
export function entityCreate(record: EntityRecord): Promise<EntityRecord> {
  return invoke<EntityRecord>(cmd("entity_create"), { record });
}
export function entityUpdate(record: EntityRecord): Promise<EntityRecord> {
  return invoke<EntityRecord>(cmd("entity_update"), { record });
}
export function entityDelete(entityType: string, id: string): Promise<void> {
  return invoke<void>(cmd("entity_delete"), { entityType, id });
}
export function memorySearch(query: string, k: number): Promise<string[]> {
  return invoke<string[]>(cmd("memory_search"), { query, k });
}
export function graphExpand(entityId: string, depth: number): Promise<string[]> {
  return invoke<string[]>(cmd("graph_expand"), { entityId, depth });
}

// --- Event channels (mirror gen_ui_ffi StreamSink feeds) ---------------------
export const CHAT_EVENT = "gen-ui://chat-event";
export const ENTITY_CHANGE = "gen-ui://entity-change";
export const SYNC_STATUS = "gen-ui://sync-status";

export function onChatEvent<T>(handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(CHAT_EVENT, (e) => handler(e.payload));
}
export function onEntityChange<T>(handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(ENTITY_CHANGE, (e) => handler(e.payload));
}
export function onSyncStatus<T>(handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(SYNC_STATUS, (e) => handler(e.payload));
}
