// TJ-ARCH-MOB-001 compliant — C-129 boundary test for the recall hook's
// contract: empty queries never invoke() (no wasted retrieval calls while
// the user is still typing/deleting), and a real query surfaces chunks.
import { describe, expect, test, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useRecall } from '../useRecall'
import { useChatStore } from '../../stores/chatStore'
import type { RagRetrieveResult } from '@prometheus-ags/tauri-plugin-gen-ui'

describe('useRecall', () => {
  test('does not call retrieveContext for an empty or whitespace query', async () => {
    const retrieveContext = vi.fn<() => Promise<RagRetrieveResult[]>>()
    useChatStore.setState({ retrieveContext })

    const { result } = renderHook(() => useRecall())
    await act(async () => {
      await result.current.recall('   ')
    })

    expect(retrieveContext).not.toHaveBeenCalled()
    expect(result.current.chunks).toEqual([])
  })

  test('surfaces chunks returned by retrieveContext for a real query', async () => {
    const chunk: RagRetrieveResult = {
      sourceId: 'm1',
      text: 'the user prefers dark mode',
      score: 0.9,
      table: 'messages',
      updatedAt: '2026-07-18T00:00:00Z',
    }
    const retrieveContext = vi.fn().mockResolvedValue([chunk])
    useChatStore.setState({ retrieveContext })

    const { result } = renderHook(() => useRecall())
    await act(async () => {
      await result.current.recall('dark mode preference')
    })

    expect(retrieveContext).toHaveBeenCalledWith('dark mode preference')
    expect(result.current.chunks).toEqual([chunk])
    expect(result.current.isRecalling).toBe(false)
  })
})
