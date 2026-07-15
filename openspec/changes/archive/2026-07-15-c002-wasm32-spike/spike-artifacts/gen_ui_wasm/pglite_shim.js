// TJ-ARCH-MOB-001 compliant
// c002 spike placeholder shim. C-007 ships the real one, importing PGlite:
//   import { PGlite } from '@electric-sql/pglite'
// Kept dependency-free here so `cargo check` (which does not run the JS bundler)
// has a resolvable module path. wasm-bindgen only reads this at the CLI stage.
export async function createPglite(dataDir) {
  // real impl: return new PGlite(`idb://${dataDir}`)
  throw new Error("pglite_shim: spike placeholder — wired by C-007");
}
export async function pgliteQuery(db, sql) {
  // real impl: return (await db.query(sql)).rows
  throw new Error("pglite_shim: spike placeholder — wired by C-007");
}
