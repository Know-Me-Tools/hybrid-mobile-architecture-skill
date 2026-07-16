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

/** Boot-order invariant, step 1 of 3: open the config store + run migrations. */
export function runMigrations(): Promise<void> {
  return invoke<void>(cmd("run_migrations"));
}
/** Boot-order invariant, step 2 of 3. */
export function loadSeeds(): Promise<void> {
  return invoke<void>(cmd("load_seeds"));
}
/** Boot-order invariant, step 3 of 3. */
export function attachSyncShapes(): Promise<void> {
  return invoke<void>(cmd("attach_sync_shapes"));
}
export function entityRuntimeStart(tenantId: string): Promise<void> {
  return invoke<void>(cmd("entity_runtime_start"), { tenantId });
}
export function entityRuntimeStop(): Promise<void> {
  return invoke<void>(cmd("entity_runtime_stop"));
}
export function memoryIngest(text: string): Promise<string> {
  return invoke<string>(cmd("memory_ingest"), { text });
}
/**
 * Start a chat turn through the liter-llm gateway. Returns the run_id whose
 * ContentBlock events arrive on {@link onChatEvent}. `messages` is the prior
 * turn history flattened to alternating role/text pairs, oldest first.
 */
export function streamAgentA2ui(userMessage: string, messages: string[]): Promise<string> {
  return invoke<string>(cmd("stream_agent_a2ui"), { userMessage, messages });
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
/** Start a Scribe microphone recording. Errors if one is already in progress. */
export function scribeStart(): Promise<void> {
  return invoke<void>(cmd("scribe_start"));
}
/** Stop the in-flight Scribe recording and return its on-device transcript. */
export function scribeStop(): Promise<string> {
  return invoke<string>(cmd("scribe_stop"));
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
