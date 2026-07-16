// TJ-ARCH-MOB-001 compliant — store layer
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { subscribeWithSelector } from 'zustand/middleware'
import { isTauri } from '@tauri-apps/api/core'
import { onChatEvent, streamAgentA2ui } from '@prometheus-ags/tauri-plugin-gen-ui'
import type { ContentBlock, Message, MessageUsage } from '@/bridge/a2ui/types'
import { applyA2uiEvent } from '@/bridge/a2ui/driver'
import { streamWebLlm } from '../api/webllmLane'
import { useLaneStore } from './laneStore'

/**
 * Drive the in-browser WebLLM lane, feeding its CoreA2uiEvents through the same
 * applyA2uiEvent path the Tauri lane's events take, and timing the run so the UI
 * can report honest on-device tok/s.
 *
 * Token count is approximated by counting streamed chunks: WebLLM's streaming
 * response carries no usage totals, and one chunk is one token in practice. It
 * is labelled an estimate in the UI rather than presented as exact.
 */
async function streamLocalWeb(text: string, assistantId: string, history: string[]): Promise<void> {
  const turns = history.reduce<{ role: 'user' | 'assistant'; text: string }[]>((acc, _, i, arr) => {
    if (i % 2 === 0 && (arr[i] === 'user' || arr[i] === 'assistant')) {
      acc.push({ role: arr[i] as 'user' | 'assistant', text: arr[i + 1] ?? '' })
    }
    return acc
  }, [])

  const store = useChatStore.getState()
  const startedAt = performance.now()
  let tokens = 0
  try {
    for await (const event of streamWebLlm(text, assistantId, turns)) {
      if (event.type === 'contentBlock') tokens += 1
      applyA2uiEvent(event, store.streamBlock, store.finalizeMessage)
    }
    useLaneStore.getState().recordThroughput(tokens, (performance.now() - startedAt) / 1000)
  } catch (e: unknown) {
    // Surface the failure in the transcript rather than leaving the message
    // spinning forever.
    store.streamBlock({
      messageId: assistantId,
      block: { type: 'text', text: `Local inference failed: ${e instanceof Error ? e.message : String(e)}` },
    })
    store.finalizeMessage(assistantId)
  }
}

interface ChatState {
  messages: Message[]
  isStreaming: boolean
  activeRunId: string | null
}

interface ChatActions {
  sendMessage: (text: string) => Promise<void>
  streamBlock: (params: { messageId: string; blockIndex?: number; block: ContentBlock }) => void
  finalizeMessage: (messageId: string, usage?: MessageUsage) => void
  initListeners: () => () => void
}

export const useChatStore = create<ChatState & ChatActions>()(
  subscribeWithSelector(
    immer((set, get) => ({
      messages: [],
      isStreaming: false,
      activeRunId: null,

      streamBlock: ({ messageId, blockIndex, block }) =>
        set((s) => {
          const msg = s.messages.find((m) => m.id === messageId)
          if (!msg) return
          if (blockIndex !== undefined && blockIndex < msg.content.length) {
            msg.content[blockIndex] = block
          } else {
            msg.content.push(block)
          }
        }),

      finalizeMessage: (messageId, usage) =>
        set((s) => {
          const msg = s.messages.find((m) => m.id === messageId)
          if (msg) { msg.isStreaming = false; if (usage) msg.usage = usage }
          s.isStreaming = false
        }),

      sendMessage: async (text: string) => {
        const userMsg: Message = { id: crypto.randomUUID(), role: 'user', content: [{ type: 'text', text }], timestamp: new Date().toISOString() }
        const assistantId = crypto.randomUUID()
        const assistantMsg: Message = { id: assistantId, role: 'assistant', content: [], timestamp: new Date().toISOString(), isStreaming: true }
        set((s) => { s.messages.push(userMsg, assistantMsg); s.isStreaming = true })

        const history = get().messages.slice(0, -1).flatMap(
          (m) => [m.role, m.content.find((b) => b.type === 'text')?.text ?? ''],
        )

        // Outside Tauri the Rust lane doesn't exist, so a `local` selection is
        // fulfilled in-browser by WebLLM. Inside Tauri, lane selection lives in
        // the Rust config DB and stream_agent_a2ui already routes accordingly —
        // hence no lane branch on that path.
        const lane = useLaneStore.getState().lane
        if (!isTauri() && lane === 'local') {
          await streamLocalWeb(text, assistantId, history)
          return
        }

        // Store calls invoke() (via the plugin's typed wrapper) — never
        // component or hook.
        await streamAgentA2ui(text, history).catch(console.error)
      },

      initListeners: () => {
        // Wire A2UI events from Rust to store — no-op outside a real Tauri
        // context (this bundle also serves as a plain web page with no
        // __TAURI_INTERNALS__ bridge, where listen() throws synchronously).
        if (!isTauri()) return () => {}
        const unlistenPromise = onChatEvent((payload: unknown) => {
          const store = useChatStore.getState()
          applyA2uiEvent(payload as never, store.streamBlock, store.finalizeMessage)
        })
        return () => { unlistenPromise.then((fn) => fn()) }
      },
    }))
  )
)
