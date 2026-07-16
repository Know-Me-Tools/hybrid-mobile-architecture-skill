// TJ-ARCH-MOB-001 compliant
import { beforeEach, describe, expect, it, vi } from 'vitest'

// Fake ONLY the Tauri IPC edge — a real IO boundary. The store logic is real.
const invoke = vi.fn()
vi.mock('@tauri-apps/api/core', () => ({
  invoke: (...args: unknown[]) => invoke(...args),
  isTauri: () => true,
}))

import { useMemoryStore, type MemoryHit } from '../stores/memoryStore'

const initial = useMemoryStore.getState()
beforeEach(() => {
  useMemoryStore.setState(initial, true)
  invoke.mockReset()
})

describe('memoryStore', () => {
  it('folds ranked hits from memory_search into state', async () => {
    const hits: MemoryHit[] = [
      { id: 'entity:1', name: 'Alpha', score: 0.91, snippet: 'first' },
      { id: 'entity:2', name: 'Beta', score: 0.42 },
    ]
    invoke.mockResolvedValueOnce(hits)

    await useMemoryStore.getState().search('alpha')

    const s = useMemoryStore.getState()
    expect(invoke).toHaveBeenCalledWith('memory_search', { query: 'alpha', k: 8 })
    expect(s.query).toBe('alpha')
    expect(s.hits).toHaveLength(2)
    expect(s.hits[0].score).toBeGreaterThan(s.hits[1].score)
    expect(s.isSearching).toBe(false)
  })

  it('surfaces a Rust domain error instead of throwing or retrying', async () => {
    invoke.mockRejectedValueOnce('surreal: index not ready')

    await useMemoryStore.getState().search('alpha')

    const s = useMemoryStore.getState()
    expect(s.error).toContain('index not ready')
    expect(s.hits).toEqual([])
    expect(s.isSearching).toBe(false)
    expect(invoke).toHaveBeenCalledTimes(1) // terminal — no silent retry
  })
})
