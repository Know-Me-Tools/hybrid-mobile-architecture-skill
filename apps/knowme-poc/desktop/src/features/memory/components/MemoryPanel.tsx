// TJ-ARCH-MOB-001 compliant — component imports the hook only (no store, no invoke).
import { useState } from 'react'
import { useMemory } from '../hooks/useMemory'

const FIELD =
  'w-full rounded-md border border-[color:var(--color-border)] bg-[color:var(--color-bg)] px-3 py-2 text-sm text-[color:var(--color-fg)] focus-visible:outline-2 focus-visible:outline-[color:var(--color-ember)]'
const ACTION =
  'shrink-0 rounded-md bg-[color:var(--color-ember)] px-4 py-2 text-sm font-medium text-white disabled:opacity-50'

export function MemoryPanel() {
  const { hits, query, isIngesting, isSearching, error, mode, ingest, search, setMode } = useMemory()
  const [ingestText, setIngestText] = useState('')
  const [searchText, setSearchText] = useState('')

  return (
    <section aria-label="Memory graph-RAG panel" className="mx-auto flex w-full max-w-2xl flex-col gap-6">
      <form
        className="flex flex-col gap-2"
        onSubmit={(e) => {
          e.preventDefault()
          if (ingestText.trim()) {
            void ingest(ingestText.trim())
            setIngestText('')
          }
        }}
      >
        <label htmlFor="mem-ingest" className="text-xs font-medium uppercase tracking-wide text-[color:var(--color-fg-sub)]">
          Ingest
        </label>
        <div className="flex gap-2">
          <input
            id="mem-ingest"
            value={ingestText}
            onChange={(e) => setIngestText(e.target.value)}
            placeholder="Add a memory…"
            className={FIELD}
          />
          <button type="submit" disabled={isIngesting || !ingestText.trim()} className={ACTION}>
            {isIngesting ? 'Ingesting…' : 'Ingest'}
          </button>
        </div>
      </form>

      <form
        className="flex flex-col gap-2"
        onSubmit={(e) => {
          e.preventDefault()
          if (searchText.trim()) void search(searchText.trim())
        }}
      >
        <div className="flex items-center justify-between gap-2">
          <label htmlFor="mem-search" className="text-xs font-medium uppercase tracking-wide text-[color:var(--color-fg-sub)]">
            Search
          </label>
          {/* Dev toggle: proves what RRF fusion buys instead of asserting it. Run the
              same query both ways — a rare exact term that vector recall smooths away
              comes back ranked first under hybrid. */}
          <div role="radiogroup" aria-label="Retrieval mode" className="flex gap-1">
            {(['hybrid', 'vector'] as const).map((m) => (
              <button
                key={m}
                type="button"
                role="radio"
                aria-checked={mode === m}
                disabled={isSearching}
                onClick={() => void setMode(m)}
                title={
                  m === 'hybrid'
                    ? 'Vector + BM25, RRF-fused — the real retrieval path'
                    : 'Vector recall only, no lexical lane — diagnostic'
                }
                className={
                  mode === m
                    ? 'rounded-md bg-[color:var(--color-ember)] px-2 py-1 text-xs font-medium text-white disabled:opacity-50'
                    : 'rounded-md border border-[color:var(--color-border)] px-2 py-1 text-xs text-[color:var(--color-fg)] disabled:opacity-50'
                }
              >
                {m === 'hybrid' ? 'Hybrid' : 'Vector only'}
              </button>
            ))}
          </div>
        </div>
        <div className="flex gap-2">
          <input
            id="mem-search"
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            placeholder="Hybrid graph-RAG search…"
            className={FIELD}
          />
          <button type="submit" disabled={isSearching || !searchText.trim()} className={ACTION}>
            {isSearching ? 'Searching…' : 'Search'}
          </button>
        </div>
      </form>

      {error ? (
        <p role="alert" className="rounded-md border border-[color:var(--color-ember)] px-3 py-2 text-sm text-[color:var(--color-ember)]">
          {error}
        </p>
      ) : null}

      {/* Only labelled once a search has run — "Results for ''" is noise to a
          screen reader before then. */}
      <ol aria-label={query ? `Results for ${query}` : 'Results'} className="flex flex-col gap-2">
        {hits.map((hit) => (
          <li
            key={hit.id}
            className="rounded-md border border-[color:var(--color-border)] bg-[color:var(--color-card)] p-3"
          >
            <div className="flex items-baseline justify-between gap-2">
              {/* `kind` is the hit's category (note/entity/…); `text` is the body.
                  These are the real MemoryHit fields — the panel previously read
                  `name`/`snippet`, which no longer exist. */}
              <span className="text-xs uppercase tracking-wide text-[color:var(--color-fg-faint)]">{hit.kind}</span>
              {/* The score's SCALE depends on the mode — an RRF score and a vector
                  similarity are not the same units. Label it, so nobody compares a
                  number across modes and concludes something false. */}
              <span
                className="font-mono text-xs text-[color:var(--color-fg-sub)]"
                title={mode === 'hybrid' ? 'Fused RRF score' : 'Vector similarity, 1/(1+distance)'}
              >
                {mode === 'hybrid' ? 'rrf' : 'sim'} {hit.score.toFixed(3)}
              </span>
            </div>
            <p className="mt-1 text-sm text-[color:var(--color-fg)]">{hit.text}</p>
          </li>
        ))}
      </ol>

      {query && hits.length === 0 && !isSearching ? (
        <p className="text-sm text-[color:var(--color-fg-sub)]">No memories matched “{query}”.</p>
      ) : null}
    </section>
  )
}
