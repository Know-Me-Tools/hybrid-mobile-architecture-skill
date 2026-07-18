// TJ-ARCH-MOB-001 compliant
// C-129: recall chips for the composer — client-RAG context for the message
// about to be sent, surfaced with provenance before it goes out. Deliberately
// small: a recall list, not a retrieval panel (Rule 2/40).
import { useCallback, useState } from 'react'
import { useChatStore } from '../stores/chatStore'
import type { RagRetrieveResult } from '@prometheus-ags/tauri-plugin-gen-ui'

export function useRecall() {
  const retrieveContext = useChatStore((state) => state.retrieveContext)
  const [chunks, setChunks] = useState<RagRetrieveResult[]>([])
  const [isRecalling, setIsRecalling] = useState(false)

  const recall = useCallback(
    async (query: string) => {
      if (!query.trim()) {
        setChunks([])
        return
      }
      setIsRecalling(true)
      try {
        setChunks(await retrieveContext(query))
      } finally {
        setIsRecalling(false)
      }
    },
    [retrieveContext],
  )

  const clear = useCallback(() => setChunks([]), [])

  return { chunks, isRecalling, recall, clear }
}
