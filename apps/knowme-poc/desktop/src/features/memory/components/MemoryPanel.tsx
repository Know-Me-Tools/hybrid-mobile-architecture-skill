// TJ-ARCH-MOB-001 compliant — component imports the hook only (no store, no invoke).
import { useState } from 'react'
import { useMemory } from '../hooks/useMemory'

export function MemoryPanel() {
  const { hits, query, isIngesting, isSearching, error, ingest, search } = useMemory()
  const [ingestText, setIngestText] = useState('')
  const [searchText, setSearchText] = useState('')

  return (
    <section aria-label="Memory graph-RAG panel">
      <form
        onSubmit={(e) => { e.preventDefault(); if (ingestText.trim()) { void ingest(ingestText.trim()); setIngestText('') } }}
      >
        <label htmlFor="mem-ingest">Ingest</label>
        <input id="mem-ingest" value={ingestText} onChange={(e) => setIngestText(e.target.value)} placeholder="Add a memory…" />
        <button type="submit" disabled={isIngesting}>{isIngesting ? 'Ingesting…' : 'Ingest'}</button>
      </form>

      <form
        onSubmit={(e) => { e.preventDefault(); if (searchText.trim()) void search(searchText.trim()) }}
      >
        <label htmlFor="mem-search">Search</label>
        <input id="mem-search" value={searchText} onChange={(e) => setSearchText(e.target.value)} placeholder="Hybrid graph-RAG search…" />
        <button type="submit" disabled={isSearching}>{isSearching ? 'Searching…' : 'Search'}</button>
      </form>

      {error ? <p role="alert">{error}</p> : null}

      <ol aria-label={`Results for ${query}`}>
        {hits.map((hit) => (
          <li key={hit.id}>
            <strong>{hit.name}</strong>
            <span> · {hit.score.toFixed(3)}</span>
            {hit.snippet ? <p>{hit.snippet}</p> : null}
          </li>
        ))}
      </ol>
    </section>
  )
}
