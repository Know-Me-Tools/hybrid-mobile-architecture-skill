// TJ-ARCH-MOB-001 compliant — store layer
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { subscribeWithSelector } from 'zustand/middleware'
import { invoke, isTauri } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'
import type { ContentBlock, Message, MessageUsage } from '@/bridge/a2ui/types'
import { applyA2uiEvent, type A2uiEvent } from '@/bridge/a2ui/driver'

// Mirrors tauri-plugin-gen-ui/src/lib.rs's GEN_UI_CHAT_EVENT constant
// ("gen-ui://chat-event") — the single channel chat_subscribe forwards every
// active run's A2uiEvents onto.
const GEN_UI_CHAT_EVENT = 'gen-ui://chat-event'

interface ChatState {
  messages: Message[]
  isStreaming: boolean
  activeRunId: string | null
  threadId: string
  /** run_id -> assistant messageId, so the single global GEN_UI_CHAT_EVENT
   * listener (one channel, many concurrent runs) can route each event to the
   * Message it belongs to — the wire event itself only carries run_id. */
  runToMessageId: Record<string, string>
}

interface ChatActions {
  sendMessage: (text: string) => Promise<void>
  streamBlock: (params: { messageId: string; block: ContentBlock }) => void
  finalizeMessage: (messageId: string, usage?: MessageUsage) => void
  initListeners: () => () => void
}

export const useChatStore = create<ChatState & ChatActions>()(
  subscribeWithSelector(
    immer((set, get) => ({
      messages: [],
      isStreaming: false,
      activeRunId: null,
      threadId: crypto.randomUUID(),
      runToMessageId: {},

      streamBlock: ({ messageId, block }) =>
        set((s) => {
          const msg = s.messages.find((m) => m.id === messageId)
          if (!msg) return
          msg.content.push(block)
        }),

      finalizeMessage: (messageId, usage) =>
        set((s) => {
          const msg = s.messages.find((m) => m.id === messageId)
          if (msg) {
            msg.isStreaming = false
            if (usage) msg.usage = usage
          }
          s.isStreaming = false
          for (const [runId, mid] of Object.entries(s.runToMessageId)) {
            if (mid === messageId) delete s.runToMessageId[runId]
          }
        }),

      sendMessage: async (text: string) => {
        const userMsg: Message = {
          id: crypto.randomUUID(),
          role: 'user',
          content: [{ type: 'text', text }],
          timestamp: new Date().toISOString(),
        }
        const assistantId = crypto.randomUUID()
        const assistantMsg: Message = {
          id: assistantId,
          role: 'assistant',
          content: [],
          timestamp: new Date().toISOString(),
          isStreaming: true,
        }
        set((s) => {
          s.messages.push(userMsg, assistantMsg)
          s.isStreaming = true
        })
        try {
          // chat_send's producer task can finish and deregister before
          // chat_subscribe attaches for very fast responses/errors (a
          // documented gap from T6/T7 — see gen_ui_agent::RunRegistry's doc
          // comment). Registering the run_id -> messageId mapping and firing
          // chat_subscribe immediately (no intervening await) after chat_send
          // resolves is the best mitigation available from the caller side;
          // it cannot fully close the window since chat_send must complete
          // before the run_id to subscribe with is even known.
          const runId = await invoke<string>('chat_send', { threadId: get().threadId, message: text })
          set((s) => {
            s.activeRunId = runId
            s.runToMessageId[runId] = assistantId
          })
          await invoke<void>('chat_subscribe', { runId })
        } catch (err) {
          const message = err instanceof Error ? err.message : String(err)
          get().streamBlock({ messageId: assistantId, block: { type: 'text', text: `⚠️ ${message}` } })
          get().finalizeMessage(assistantId)
        }
      },

      initListeners: () => {
        // Wire A2UI events from Rust to store — no-op outside a real Tauri
        // context (this bundle also serves as a plain web page with no
        // __TAURI_INTERNALS__ bridge, where listen() throws synchronously).
        if (!isTauri()) return () => {}
        const unlistenPromise = listen<A2uiEvent>(GEN_UI_CHAT_EVENT, (event) => {
          const store = useChatStore.getState()
          const payload = event.payload
          const runId = 'run_id' in payload ? payload.run_id : undefined
          const messageId = runId ? store.runToMessageId[runId] : undefined
          if (!messageId) return
          applyA2uiEvent(payload, messageId, store.streamBlock, store.finalizeMessage)
        })
        return () => {
          unlistenPromise.then((fn) => fn())
        }
      },
    })),
  ),
)
