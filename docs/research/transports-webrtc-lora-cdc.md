# Research Brief: CRDT Sync over Edge Transports + Postgres CDC Fan-out

**Slug:** `transports-webrtc-lora-cdc`
**Researcher:** KNOWME_RESEARCHER (web-research track)
**Date:** 2026-07-18 (all URLs accessed on this date unless noted)
**Master-goal lens:** pglite (web) + pglite-oxide (Tauri) clients syncing through `flint-realtime-fabric` to central Postgres (`flint-forge`); CRDT sync over WebRTC and potentially LoRa; Rust-first everywhere.

---

## 0. Verdict summary

| Transport / mechanism | Practicality verdict | Role in the master architecture |
|---|---|---|
| WebRTC DataChannel (browser/native P2P) | **High** for small-group P2P sessions & LAN; **Medium** as a server↔client channel | Edge CRDT sync between nearby devices and small collaboration rooms; not the backbone |
| Rust WebRTC (`webrtc-rs/rtc`, `str0m`) | **Medium-High**, both pre-1.0 | Lets the Rust fabric terminate DataChannels natively and speak to browsers/`flutter_webrtc` without a JS shim |
| `flutter_webrtc` | **High** (mature, all-platform DataChannel) | The Flutter-side WebRTC endpoint |
| iroh (+ iroh-docs / iroh-blobs / iroh-gossip) | **High** — best Rust fit | Candidate primary P2P/edge substrate of `flint-realtime-fabric`; blobs double as decentralized component distribution |
| rust-libp2p (gossipsub, kad, QUIC) | **Medium-High** but heavier | Alternative p2p substrate; choose iroh unless libp2p ecosystem interop is required |
| LoRa mesh (lora-rs, Meshtastic, MeshCore) | **Low** for general sync; **OK** for opportunistic control-plane | Niche: tiny CRDT op beacons, presence, checkpoint hashes. Never bulk sync |
| BLE (BitChat-style, platform P2P APIs) | **Medium-High** for phone-adjacent sync | Practical last-10-meters transport; better than LoRa for consumer devices |
| Postgres logical replication (`pgoutput` + custom Rust fan-out) | **High** — the proven backbone pattern | The server-side sync spine: one replication slot → Rust shape/bucket matcher → fabric fan-out to pglite clients |
| Electric (Postgres Sync) | **High** as reference architecture | Read-path shape sync + Shape Log + CDN fan-out; model to re-implement in Rust inside the fabric |
| PowerSync | **High** as reference architecture | Bucket/checkpoint model + client upload queue; the bidirectional complement to Electric |
| Debezium | **Low for this use case** | JVM + Kafka-centric pipeline tool; wrong granularity for per-user embedded fan-out |

---

## A. WebRTC DataChannel sync

### What exists (facts)

**JS CRDT-over-DataChannel libraries**

- **y-webrtc** (`npm i y-webrtc`, repo `github.com/yjs/y-webrtc`, MIT) — official Yjs WebRTC provider. `new WebrtcProvider(roomName, ydoc, { signaling: [...], password, maxConns })`. Propagates Yjs doc updates P2P; encrypts signaling-server traffic with an optional room password so untrusted signaling servers are usable. Ships a tiny signaling server at `./bin/server.js`. Default public signaling endpoints: `wss://signaling.yjs.dev` etc. **Hard scaling caveat from the README and from Kevin Jahns:** default mesh is `maxConns = 20 + floor(rand*15)`; past ~30 clients the provider intentionally builds a *partially* connected mesh with no sync guarantees — "I highly recommend other communication protocols when a large number of clients is expected" (ProseMirror forum post, 2020-01-27; still the design in 2026).
- **automerge-repo network adapters** (`@automerge/automerge-repo`, announcement blog `automerge.org/blog/automerge-repo/`). Network is pluggable: `@automerge/automerge-repo-network-websocket` (client+server, wire protocol documented on npm, protocol version "1" join/peer handshake, page updated 2026-03-31), `@automerge/automerge-repo-network-broadcastchannel`, and community WebRTC adapters — notably `automerge-repo-network-peerjs` (`github.com/automerge/automerge-repo-network-peerjs`, wraps a PeerJS `DataConnection` in a `PeerjsNetworkAdapter`). Automerge 3 (autumn 2025) brought column-oriented storage (~10x smaller docs, 50–70% less memory), making DataChannel sync payloads cheaper.
- **Trystero** (`github.com/dmotz/trystero`, site trystero.dev) — "serverless WebRTC matchmaking". Peers discover each other over existing pub/sub media instead of a bespoke signaling server: strategies = Nostr (default), MQTT, BitTorrent trackers, Supabase Realtime, Firebase RTDB, IPFS, or a self-hosted WS relay (`@trystero-p2p/ws-relay`). Current release line 0.23.x (2026-03): split into scoped packages `@trystero-p2p/{nostr,mqtt,torrent,supabase,firebase,ipfs,core}`; added `onPeerHandshake(peerId, send, receive, isInitiator)` admission-handshake hook (app-level identity/auth before peers become visible); trickle ICE public option; **shared underlying `RTCPeerConnection` reuse across rooms**; automatic chunking/throttling of large payloads, progress events, session encryption (AES-GCM over SDP; WebRTC itself is DTLS-encrypted regardless). Runs server-side on Node/Bun via `rtcPolyfill` (recommended polyfill: `werift`). Community bridge `y-webrtc-trystero` (`github.com/WinstonFassett/y-webrtc-trystero`) adapts Trystero rooms as a Yjs provider.

**Signaling / NAT-traversal requirements**

- WebRTC peer establishment always needs an out-of-band signaling channel to exchange SDP offers/answers + ICE candidates; the sync data itself then flows P2P over SCTP/DTLS DataChannels. Signaling is deliberately unspecified by the standard — any pub/sub works (y-webrtc's `server.js`, Trystero's strategies, or a channel inside flint-realtime-fabric).
- STUN discovers reflexive addresses; TURN (RFC 5766, e.g. `coturn`) relays when direct paths fail (symmetric NAT, some enterprise/cellular networks). TURN is a real operational cost center — every relayed byte consumes server bandwidth (VideoSDK TURN guide, 2025-07-10). Any production design must budget for TURN or accept a fraction of peers falling back to a relayed/WebSocket path.
- Firefox's 2025 WebRTC work (Mozilla blog, 2026-01-13) migrated DataChannels to a new `dcsctp` implementation that can run on workers — relevant because DataChannel reliability/perf historically varied by browser.

**Rust-side WebRTC**

- **`webrtc-rs/rtc`** (`github.com/webrtc-rs/rtc`, webrtc.rs) — pure-Rust sans-IO WebRTC stack. Composable crates (ICE, DTLS, SCTP, SDP, RTP/RTCP, DataChannel, mDNS, STUN, TURN). Drives via `poll_write`/`poll_event`/`poll_read`/`poll_timeout` + `handle_*` inputs; runtime-agnostic (tokio example in README). Full DataChannel support (`RTCDataChannelInit { ordered, max_retransmits, .. }`). Semver caution: 0.x with alpha/beta/rc pre-release stages; minor bumps may break (README section "Semantic Versioning", page updated 2026-02-08).
- **`str0m`** (`github.com/algesten/str0m`, docs.rs/str0m, MIT, page 2026-07-01) — the other sans-IO Rust WebRTC. Explicit feature-gap table vs libWebRTC: has SDP/ICE/**Data Channels**/TWCC/simulcast; **lacks TURN, mDNS, network-interface enumeration, A/V capture/encode/decode, adaptive jitter buffer**. "Also works for peer-2-peer, though that aspect has received less testing" (LinuxLinks, 2025-05-02). No internal threads — a single `Rtc` state machine, which composes cleanly with a fabric event loop.
- **Flutter side:** `flutter_webrtc` (pub.dev, latest 1.4.1, Mar 2026; ~150k downloads/30 days) — based on GoogleWebRTC; **Data Channel supported on Android, iOS, Web, macOS, Windows, Linux, Embedded**. GetStream maintains a synced fork (`GetStream/webrtc-flutter`) with its own native WebRTC builds (v125.6422.065).

**Rust CRDT over the channel**

- **`yrs`** (docs.rs/yrs, page 2026-07-01) — Rust port of Yjs, binary/protocol compatible; includes `sync::Awareness` and the y-sync protocol state machine with `sync::DefaultProtocol` and an extensible `Protocol` trait (`Message::Custom(tag, data)`). The old standalone `y-crdt/y-sync` repo was archived 2024-12-20 (functionality lives in `yrs::sync`). Wire framing: `0x00` SyncStep1, `0x01` SyncStep2, `0x02` Update, `0x03` Awareness.
- **Caution:** Loro (Rust-native CRDT, 1.0 GA Feb 2026) does **not** implement the Yjs wire protocol — a Loro↔Yjs interop layer would have to be written. One migration spec recommends deliberately shifting message-type byte values to reject cross-protocol confusion (`kryptobasedev/llmtxt` P1 spec, validated 2026-04-17).

### How it works

1. Peers join a room via any signaling medium; SDP/ICE exchanged; a full or partial DataChannel mesh forms.
2. CRDT updates (Yjs `Update` messages, Automerge sync-protocol messages, Loro export blobs) are binary frames on ordered/reliable SCTP channels; awareness/presence rides a separate message type.
3. Server participation requires a native WebRTC endpoint: browser/`flutter_webrtc` ↔ Rust (`rtc` or `str0m`) is symmetric — the Rust side acts as just another peer, so `flint-realtime-fabric` can terminate edge DataChannels and bridge them into its server-side sync spine.

### Implications for the master goal

- WebRTC is the right **edge** transport: phone↔phone, phone↔desktop, browser↔desktop on LAN or direct WAN paths, small collaboration rooms, agent-to-agent side channels. It is **not** the fan-out backbone to thousands of pglite clients (mesh limits + per-peer connection cost + TURN exposure).
- The fabric should offer: (a) a signaling/announcement channel inside its existing gateway; (b) a Rust DataChannel terminator (`rtc` preferred — it includes TURN/mDNS pieces str0m lacks; str0m if a simpler single-state-machine embed is wanted); (c) yrs (or Loro) as the Rust CRDT so Dart/TS clients and Rust agents speak one wire protocol.
- Trystero's 0.23 admission-handshake + connection-reuse design is the reference for how to bolt authn/authz onto P2P rooms.

### Gaps / risks

- Mesh fan-out degrades past ~20–30 peers/room (y-webrtc) — need partial-mesh + relay peer design for anything bigger.
- TURN infrastructure must be operated or bought; fraction of real-world peers always needs it.
- Both Rust stacks are pre-1.0; browser↔native DataChannel interop (SCTP) needs dedicated conformance testing.
- DataChannel message size is practically capped (~16–256 KiB depending on stack) — large CRDT state transfers need chunking (Trystero automates this; `rtc`/`str0m` leave it to you).

---

## B. libp2p and iroh for P2P sync in Rust

### What exists (facts)

**rust-libp2p**

- `libp2p-gossipsub` on crates.io (page updated 2026-03-26); rust-libp2p provides transports (TCP+Noise+Yamux, QUIC, WebTransport), discovery (mDNS, Kademlia DHT, rendezvous), NAT traversal (AutoNAT v2, DCUtR hole punching, Circuit Relay v2), and pub/sub (GossipSub 1.4 with IDONTWANT; Vac/IFT ran 2025 perf programs on staggered sending and large-message fragmentation — `roadmap.vac.dev/p2p/ift/2025q1-gossipsub-perf-improvements`).
- Production usage in 2025–2026: Circle's Malachite consensus engine validated "libp2p + GossipSub as default p2p option" after worldwide adversarial testing (github.com/circlefin/malachite discussion #1119, 2025-07-04); `agntcy/dir` v0.4.0 (2025-10-15) added GossipSub label announcements and authenticated PeerID for an agent-directory network.

**iroh (n0-computer)**

- Core: `iroh` — direct peer connections over **QUIC, hole-punched when possible**, with relay fallback and node discovery (DNS + pkarr; `iroh-pkarr-node-discovery` on lib.rs). Protocols mount on one `Endpoint` via `Router` + ALPN. WASM/browser support demonstrated (`iroh-examples`: browser-echo, browser-chat, browser-blobs).
- **`iroh-blobs`** — content-addressed blob transfer; BLAKE3 Merkle-tree *verified streaming*; resumable transfers (Distribits 2025 talk "Iroh p2p QUIC transport and resumable verified transfers", 2025-10-24).
- **`iroh-docs`** (docs.rs, v0.95.0, 2026-01-03) — "Multi-dimensional key-value documents with an efficient synchronization protocol." Model: a `Replica` holds `Entry`s keyed by (key, author, namespace); entry value = 32-byte BLAKE3 content hash + size + timestamp (content itself flows via iroh-blobs). Two keypairs: `NamespaceSecret` (write capability; pubkey = `NamespaceId`) and `Author` (authorship; `AuthorId`). Sync = **range-based set reconciliation** (Aljoscha Meyer, arXiv:2212.13567) — recursively partition sets, compare fingerprints, transfer only differing ranges; plus live sync over **iroh-gossip**. Storage: `store::fs::Store` over `redb`, single file. Sharing via `DocTicket`. Meta-protocol stack: `Docs` depends on `Blobs` + `Gossip` (setup example in README: `Router::builder(endpoint).accept(BLOBS_ALPN, …).accept(GOSSIP_ALPN, …).accept(DOCS_ALPN, …)`).
- CRDT bridges in `iroh-examples`: `iroh-automerge`, `iroh-automerge-repo` ("Iroh integration with automerge using **samod**" — samod is the Rust re-implementation of automerge-repo), `tauri-todos` (iroh documents + Tauri), and a community `iroh-loro` PR (#132, 2025-09-05) implementing `IrohLoroProtocol` with incremental sync + presence.
- Willow protocol (`willowprotocol.org`) is the conceptual sibling — iroh-docs' set reconciliation derives from the same research line (Meyer is a Willow author).

### How it works

- libp2p: build a `Swarm` with transport + behaviour (gossipsub/kad/mdns); CRDT ops ride gossip topics or request-response streams; you own anti-entropy on top.
- iroh: one endpoint; docs sync themselves (namespace-scoped, per-author latest-wins with timestamps — effectively a CRDT map); blobs fetched on demand by hash; gossip gives live propagation; discovery via pkarr/DNS means no self-hosted DHT is required for small deployments.

### Implications for the master goal

- **iroh is the strongest single candidate for the fabric's P2P/edge layer**: pure Rust, QUIC-native, WASM-compilable for the web surface, Tauri-proven (`tauri-todos`), and its blobs answer the *decentralized component/skill distribution* requirement in the same stack (content-addressed, verified, resumable — complementary to flint-forge's IPFS/OCI/S3 registry stores).
- iroh-docs maps directly onto "settings schemas with synced client/server storage" (namespace per app/user scope; author keys = device identity).
- libp2p is the fallback if interop with the wider libp2p world (IPFS, Waku, Ethereum infra) is a requirement; it is heavier and its NAT story needs more assembly than iroh's.
- Either way: CRDT payload (yrs/Loro/Automerge-via-samod) stays transport-independent — the fabric should define one sync-protocol abstraction with adapters for WebRTC-DataChannel, iroh, and WebSocket.

### Gaps / risks

- iroh is 0.x and churns (the iroh-loro PR needed fixes "for iroh v0.91 compatibility"; examples lag releases). Pin versions; wrap behind an internal trait.
- iroh's public relays/discovery are n0-operated conveniences — sovereign deployment means running own relay + discovery (both supported but operationally yours).
- iOS background networking limits P2P liveness on mobile regardless of library; plan for store-and-forward via the server spine.
- Gossip-style eventual delivery ≠ server-authoritative ordering; keep Postgres CDC as the consistency backbone and treat p2p as latency optimization + offline edge.

---

## C. LoRa mesh for opportunistic sync (and BLE alternatives)

### What exists (facts)

**Rust crates**

- `lora-rs/lora-rs` org (`github.com/lora-rs/lora-rs`, last repo update 2025-11-27): `lora-phy` (SX126x/SX127x radio drivers, PHY layer), `lorawan-device` (LoRaWAN MAC device stack, non-blocking + async/Embassy), `lorawan-encoding` (packet codec), `lora-modulation` (time-on-air calculator). All `no_std`, embedded-first. This is **end-device** tooling — there is no mature Rust LoRaWAN gateway/network-server mesh stack.
- `tago-io/lora-packet-rs` (2026-05-21) — LoRaWAN 1.0/1.1 frame codec with strong key newtypes, constant-time MIC check, `no_std+alloc`, `#![deny(unsafe_code)]`.

**Meshtastic**

- Flood-based mesh over LoRa on ESP32+SX1262-class hardware (managed flood routing; default hop limit 3, max 7; v2.6 adds next-hop routing for direct messages).
- **Hard payload cap: 233 bytes** per `Data.payload` (things-nyc/lwom README, 2025-12-19, citing Meshtastic mesh.options).
- **Data rates are brutally low** (Meshtastic blog "Why your mesh should switch from LongFast", 2025-04-22): LongFast (SF11/250kHz) ≈ **1.07 kbps**, MediumFast 3.52 kbps, ShortFast 10.94 kbps, ShortTurbo 21.88 kbps; VeryLongSlow ≈ 0.09 kbps (Meshtasticator docs). These are PHY rates *before* mesh overhead, hop retransmission, duty-cycle limits (EU868 1%), and collision loss — effective app throughput in a busy mesh is a few hundred bytes/minute.
- Real-world hybrid: BitChat-over-LoRa whitepaper (`permissionlesstech/bitchat` issue #180, 2025-07-11): phone ↔ ESP32 via BLE, ESP32 bridges into LoRa mesh; states LoRa ~300 bps–2.4 kbps effective, seconds-to-minutes latency, 1–3 km urban / up to 10 km rural links.
- MeshCore alternative: compile-time radio profiles (default SF7/62.5kHz ≈ 11 kbps, 2–5 km urban), flood-then-direct routing, internal 64-hop path support, repeater-role separation (austinmesh.org and ryanmalloy.com protocol writeups, 2026-02).

**BLE alternatives**

- BLE 5 gives ~1–2 Mbps PHY (practical app throughput hundreds of kbps), plus Coded PHY long-range mode; store-and-forward messengers (BitChat) prove phone-native P2P sync without internet.
- Platform-local P2P: Apple MultipeerConnectivity, Android Nearby Connections, Wi-Fi Direct — all vastly more bandwidth than LoRa, no extra hardware, already permission-modelled by the OS.

### How it works / what fits over LoRa

At ~1 kbps with 233-byte frames and multi-second airtime per packet, LoRa can carry: CRDT *op beacons* (a Yjs single-keystroke update is tens of bytes), state-vector digests/checkpoint hashes ("my doc is at VV {…}", merkle root), presence/telemetry, and tiny urgent ops. It cannot carry: initial sync, blob transfer, doc snapshots, or chatty anti-entropy. A viable design is a *dormant opportunistic channel*: exchange version vectors over LoRa; if peers diverge, schedule real sync over BLE/Wi-Fi/internet when available; LoRa itself carries only hashes + tiny high-priority deltas. Duty-cycle regulations and shared-channel airtime make even this a "few messages per node per minute" budget.

### Implications for the master goal

- Treat `lora-rs` as a specialized edge adapter in the fabric's transport registry (behind the same sync-protocol trait), targeting field/off-grid scenarios — not a general client transport.
- BLE is the realistic short-range radio for consumer KnowMe clients; LoRa only enters via companion LoRa hardware (ESP32 bridge), which the BitChat architecture validates.
- MeshCore's flood-then-direct and Meshtastic's managed-flood trade-offs are useful prior art if the fabric ever needs multi-hop store-and-forward semantics over constrained links.

### Gaps / risks

- No Rust mesh protocol stack (Meshtastic/MeshCore are C++/PlatformIO firmware) — a Rust LoRa mesh would be greenfield on `lora-phy`.
- Regulatory duty-cycle + crowded LongFast default channels; dense meshes collapse (Meshtastic's own blog recommends faster presets as meshes grow).
- 233-byte frames force an application-layer fragmentation/reassembly + FEC design for anything beyond single ops.

---

## D. Postgres logical replication / CDC fan-out to embedded replicas

### What exists (facts)

**Logical decoding primitives**

- `wal_level = logical` adds row-level info to WAL (~10–15% volume overhead vs `replica`). An **output plugin** inside the walsender decodes WAL → change stream. The three that matter: **`pgoutput`** (in-tree binary; the `CREATE SUBSCRIPTION` protocol; Debezium 2.x default; only choice on managed PGs like RDS/Supabase that disallow out-of-tree plugins), **`wal2json`** (JSON per change; ~1.5–2x wire size; friendlier for hand-rolled consumers), `decoderbufs` (Protobuf; Debezium 1.x legacy). (`pipecode.ai` CDC guide, 2026-06-30; `stacksync.com` plugin guide, 2025-09-06; `queryplane.com` logical-replication-in-practice, 2026-05-05.)
- **Replication slots** are persistent server-side WAL cursors (`restart_lsn`, `confirmed_flush_lsn`); they guarantee crash-safe resume but retain WAL forever if a consumer dies (phantom slot → disk-full outage; `max_slot_wal_keep_size` exists to bound this, at the cost of invalidating the slot). Default `max_replication_slots = 10` — you cannot give each end client a slot; **one slot + a fan-out service is the only viable topology at thousands of clients**.
- Publications define what's streamed; **PG15 added row filters (`FOR TABLE … WHERE (…)`) and column lists**; PG16 added parallel apply + logical decoding from standbys + bidirectional support; PG17 added `pg_createsubscriber` and failover slots.
- `REPLICA IDENTITY` governs UPDATE/DELETE row identification (PK default; `USING INDEX`; `FULL` at ~2x WAL cost). DDL is **not** replicated — schema evolution must be handled by the consumer.
- **Rust consumption:** `pg_walstream` (docs.rs, page 2026-07-01) — platform-agnostic logical-replication library: `LogicalReplicationStream`/`EventStream`, a byte-faithful `pgoutput` parser **and** encoder, `WalRouter` (typed per-table routing), retry with exponential backoff, LSN tracking for feedback. This is the crate to build the fabric's CDC ingest on.

**Electric (ElectricSQL → "Postgres Sync" / "the agent platform built on sync")**

- Architecture (`electric-sql.com/primitives/postgres-sync`, 2025-08-13; `github.com/electric-sql/electric`): an **Elixir** sync service (`packages/sync-service`) connects via `DATABASE_URL`, consumes the logical replication stream, and **fans out into Shapes** — declarative partial-replication queries (`table` + `where` + `columns`). Clients consume a low-level **HTTP API**: initial `GET /v1/shape?table=foo&offset=-1`, then `live=true` long-polling; responses are **Shape Log** entries with client-tracked offsets/handles. Because it's plain HTTP with deterministic logs, **CDNs cache shape responses** and the same log is served to every subscriber — the stated design goal is "millions of concurrent users with minimal additional load on your database."
- **Read-path only**: writes go through your existing API/backend to Postgres; Electric propagates the committed result. This is the same server-authoritative stance PowerSync takes.
- **Authz:** Electric itself does no auth; the documented production pattern is an **Authorization Proxy/gatekeeper** in front (validates JWT, rewrites/approves shape definitions), optionally plus a caching proxy (Neon guide `neon.com/guides/electric-sql`). Shape params allow per-user filtering, but enforcement is the proxy's job.
- **PGlite integration:** `@electric-sql/pglite-sync` (`pglite.dev/docs/sync`, alpha) — `pg.electric.syncShapeToTable({ shape, table, primaryKey, shapeKey })` and `syncShapesToTables` (multi-table, transactionally consistent across tables — single Postgres transaction → single PGlite transaction). This is exactly the pglite-web half of the master goal, already working.
- History note: Electric *pivoted* in late 2024 from a CRDT/direct-write model to this server-authoritative shape model; the legacy CRDT Electric is dead. PowerSync's comparison (2024, updated 2026-03-10) documents the legacy model's fatal flaw: per-client in-memory row graphs → server memory ∝ clients × rows.

**PowerSync**

- v1.0 announcement (`powersync.com/blog/introducing-powersync-v1-0-postgres-sqlite-sync-layer`, 2023-11-29) + architecture deep-dives: connects to standard Postgres **read-only via logical replication**; **Sync Rules** (SQL with dynamic per-client parameters from JWT claims) partition data into **buckets** shared across users where possible; the service snapshots, then incrementally maintains an **operation history indexed by `op_id`** in its own storage (Postgres stays clean), with compaction.
- **Consistency:** causal+ via **checkpoints** — a checkpoint is a committed-LSN-consistent point; clients advance to a checkpoint only when they hold all its data, and do not advance while local writes sit unacknowledged in the **upload queue** → no client-side conflict resolution ever; server is authoritative ("No CRDTs needed" — PostgresConf 2024 talk PDF `postgresconf.org/.../2024-04_Local-first_apps_using_logical_replication.pdf`).
- **Schemaless replication:** rows ship as JSON; client schema is **SQLite views** over schemaless data → no client migrations; sync-rules changes apply atomically client-side.
- Client SDKs: Flutter, React Native, web (WASM SQLite + OPFS), Kotlin, Swift; since June 2025 sync state/processing moved into a **Rust SQLite extension, `powersync-sqlite-core`** (`powersync.com/blog/powersync-update-june-2025`). Newer **Sync Streams** support INNER JOINs (post Oct 2025). Backends: Postgres (mature), MongoDB (GA 2025-03), MySQL (beta), SQL Server (alpha). Operational lessons published: resumable initial replication, replication-lag metrics, **RLS pitfall** (custom replication roles + RLS silently return empty results unless superuser/`BYPASSRLS`).
- Trade-offs (QueryPlane review, 2026-02-07): best for per-user datasets of thousands–tens of thousands of rows, not millions; write path requires implementing `uploadData()` + server-side conflict policy.

**Debezium**

- JVM/Kafka CDC framework; uses `pgoutput` by default since 2.x, snapshot-then-stream, heartbeats, signal tables. Right tool for warehouse/event pipelines; **wrong tool** for per-user embedded fan-out (Kafka infrastructure per deployment, no notion of client shapes/authz). Even streaming frameworks are filing issues to escape the Debezium+Kafka requirement in favor of direct slot consumption (`pathwaycom/pathway` issue #186, 2026-02-06).

### How a Rust service should do this (synthesis)

1. **Ingest:** one logical replication slot, `pgoutput`, consumed in Rust with `pg_walstream` (or `rtc`-style sans-IO parser embedded) inside `flint-forge`/`flint-realtime-fabric`. Track LSNs; send standby status updates; monitor slot lag.
2. **Match:** evaluate committed transactions against registered **Shapes** (Electric-style `table+where+columns` with server-bound parameters) — the matcher is the hard IP: incremental evaluation of which shape-logs each row touches, with move-in/move-out detection when updates change shape membership.
3. **Stage:** append to per-shape durable logs (the Electric insight: one shared log per shape → N subscribers, CDN/cache-friendly; NOT per-client state). Checkpoint markers give PowerSync-style causal consistency.
4. **Deliver:** fabric channels (WebSocket/QUIC/HTTP long-poll) stream log slices by client offset; pglite (web, via pglite-sync-style apply) and pglite-oxide (Tauri, typed Rust commands) apply transactionally, multi-table atomic.
5. **Authz:** gatekeeper evaluates JWT claims at shape *registration* and stamps allowed parameter sets; the matcher only ever materializes authorized shapes. PG15 publication row-filters can add a static defense-in-depth layer for tenant isolation.
6. **Write path:** clients write locally → upload queue → fabric ingest → API/business logic → Postgres commit → change flows back through step 1 and lands in the client's checkpoint. Server-authoritative, no client conflict resolution.
7. **Schema evolution:** DDL isn't in the stream — follow PowerSync: ship schemaless JSON, apply client-side views, version shape definitions.

### Implications for the master goal

- This spine (CDC → shape matcher → durable shape logs → fabric fan-out) is the **central nervous system** of the whole design; WebRTC/iroh/LoRa are edge optimizations around it.
- Electric's HTTP Shape Log proves the fan-out scales; PowerSync proves the bidirectional checkpoint model and ships a Rust core already (`powersync-sqlite-core`) — precedent for putting the client sync engine in Rust inside `gen_ui_core`.
- Because pglite-oxide keeps a real Postgres on the client, shape application can use actual SQL semantics (not SQLite-view emulation) — a differentiator over both Electric (SQLite views) and PowerSync (schemaless JSON).

### Gaps / risks

- Building the incremental shape matcher is the real R&D; both Electric (Elixir) and PowerSync (closed-service/open-edition split) are only partially reusable as code — budget for a Rust implementation.
- Replication-slot hygiene (lag alerts, `max_slot_wal_keep_size` policy, failover slots on PG17) is a standing operational duty.
- `REPLICA IDENTITY FULL` on legacy tables inflates WAL; TOASTed values arrive unchanged-referenced; DDL drift between server and shape definitions needs detection.
- Supabase/managed-PG constraints: only `pgoutput`, custom-role+RLS silent-empty-results trap (PowerSync's June 2025 warning), provider-specific enablement steps.
- Electric's per-shape where-clause expressiveness is limited (no arbitrary joins; PowerSync needed `pg_ivm`/Sync Streams for joins) — expect the same fight in a Rust matcher.

---

## E. Cross-cutting notes for the fabric design

- **One sync-protocol abstraction, many transports.** yrs/y-sync framing (or Loro's export modes, or Automerge's sync protocol) should ride interchangeably over: WebSocket (baseline), iroh streams/gossip (Rust edge), WebRTC DataChannel (browser/Flutter edge), BLE bridge (phone-adjacent), LoRa beacon (off-grid, hashes+tiny ops only).
- **Server-authoritative + CRDT hybrid is the industry-validated split**: Postgres CDC spine for entities/settings (Electric/PowerSync model); true CRDT only where multi-writer offline collaboration is intrinsic (docs, canvas, agent scratchpads) — and there, yrs gives Rust/JS/Dart(WASM) one wire protocol.
- **Component distribution:** iroh-blobs (BLAKE3 verified, resumable) is a credible in-fabric alternative/complement to IPFS for WASM component + skill packages; flint-forge's existing OCI/IPFS/S3 registry can index hashes either system serves.
- **Mobile reality:** iOS kills background sockets; the CDC spine + push-notification wake + foreground iroh/WebRTC is the pragmatic pattern.

## Key sources (all accessed 2026-07-18)

- y-webrtc README — https://github.com/yjs/y-webrtc
- Yjs ProseMirror P2P demo + mesh-scaling caveat — https://discuss.prosemirror.net/t/offline-peer-to-peer-collaborative-editing-using-yjs/2488 (2020-01-27)
- Tag1 "Signaling servers and y-webrtc" — https://www.tag1.com/blog/signal-y-webrtc-part2/ (2020-03-17)
- automerge-repo announcement — https://automerge.org/blog/automerge-repo/
- automerge-repo-network-websocket wire protocol — https://www.npmjs.com/package/@automerge/automerge-repo-network-websocket (2026-03-31)
- automerge-repo-network-peerjs — https://github.com/automerge/automerge-repo-network-peerjs
- Trystero repo + 0.23.0 release notes — https://github.com/dmotz/trystero , https://github.com/dmotz/trystero/releases (2026-03-23); site https://trystero.dev/ (2026-05-04)
- y-webrtc-trystero — https://github.com/WinstonFassett/y-webrtc-trystero
- TURN/STUN guide — http://videosdk.live/developer-hub/stun-turn-server/what-is-turn-server (2025-07-10)
- Firefox WebRTC 2025 (dcsctp DataChannel rework) — https://blog.mozilla.org/webrtc/firefox-webrtc-2025/ (2026-01-13)
- webrtc-rs/rtc — https://github.com/webrtc-rs/rtc (2026-02-08); https://webrtc.rs/
- str0m — https://docs.rs/str0m (2026-07-01); https://www.linuxlinks.com/str0m-sans-io-webrtc-implementation/ (2025-05-02)
- flutter_webrtc — https://pub.dev/packages/flutter_webrtc (1.4.1, 2026-03); https://fluttergems.dev/packages/flutter_webrtc/ (2026-05-18); https://github.com/GetStream/webrtc-flutter/blob/main/CHANGELOG.md
- yrs — https://docs.rs/yrs (2026-07-01); y-crdt/y-sync archived — https://github.com/y-crdt/y-sync; y-crdt/y-crdt parity table — https://github.com/y-crdt/y-crdt
- Loro migration spec (wire-protocol incompatibility) — https://github.com/kryptobaseddev/llmtxt/blob/main/docs/specs/P1-loro-migration.md (2026-03-09)
- libp2p-gossipsub — https://crates.io/crates/libp2p-gossipsub (2026-03-26); Malachite libp2p validation — https://github.com/circlefin/malachite/discussions/1119 (2025-07-04); agntcy/dir v0.4.0 — https://github.com/agntcy/dir/blob/main/CHANGELOG.md (2025-10-15); Vac gossipsub perf — https://roadmap.vac.dev/p2p/ift/2025q1-gossipsub-perf-improvements
- iroh-docs — https://docs.rs/iroh-docs/latest/iroh_docs/ (0.95.0, 2026-01-03); https://github.com/n0-computer/iroh-docs; https://www.iroh.computer/proto/iroh-docs; set-reconciliation paper arXiv:2212.13567
- iroh examples (browser WASM, tauri-todos, iroh-automerge/samod) — https://lib.rs/crates/iroh-pkarr-node-discovery; iroh-loro PR — https://github.com/n0-computer/iroh-examples/pull/132 (2025-09-05)
- Distribits iroh talk — https://www.distribits.live/talks/2025/bruynooghe-iroh-p2p-quic-transport-and/ (2025-10-24)
- lora-rs — https://github.com/lora-rs/lora-rs (updated 2025-11-27); lora-packet-rs — https://github.com/tago-io/lora-packet-rs (2026-05-21)
- Meshtastic presets/data rates — https://meshtastic.org/blog/why-your-mesh-should-switch-from-longfast/ (2025-04-22); Meshtasticator modem table — https://meshtastic.org/docs/software/meshtasticator/discrete-event-sim/
- Meshtastic 233-byte payload — https://github.com/things-nyc/lwom (2025-12-19)
- BitChat-over-LoRa whitepaper — https://github.com/permissionlesstech/bitchat/issues/180 (2025-07-11)
- MeshCore vs Meshtastic — https://www.austinmesh.org/learn/meshcore-vs-meshtastic/ ; https://ryanmalloy.com/protocols/meshcore (2026-02-01)
- Postgres CDC slots/plugins deep-dive — https://pipecode.ai/blogs/postgresql-logical-replication-cdc-slots-publications (2026-06-30); plugin comparison — https://www.stacksync.com/blog/postgresql-logical-decoding-plugins-developers-guide (2025-09-06); practice guide — https://queryplane.com/blog/postgres-logical-replication-in-practice/ (2026-05-05)
- pg_walstream — https://docs.rs/pg_walstream (2026-07-01)
- Electric — https://github.com/electric-sql/electric ; https://electric-sql.com/primitives/postgres-sync (2025-08-13); https://electric-sql.com/docs/guides/shapes ; authz proxy pattern — https://neon.com/guides/electric-sql ; PGlite sync — https://pglite.dev/docs/sync
- PowerSync — https://powersync.com/blog/introducing-powersync-v1-0-postgres-sqlite-sync-layer (2023-11-29); https://powersync.com/blog/powersync-update-june-2025 (2025-07-07); https://powersync.com/blog/postgres-logical-replication-challenges-solutions (2024-05-08); local-first logical replication talk — https://postgresconf.org/system/events/document/000/002/237/2024-04_Local-first_apps_using_logical_replication.pdf (2024-04); review — https://queryplane.com/blog/powersync-offline-first-sync/ (2026-02-07); Electric comparison — https://powersync.com/blog/electricsql-vs-powersync
- Debezium/pgoutput context — https://github.com/pathwaycom/pathway/issues/186 (2026-02-06)
