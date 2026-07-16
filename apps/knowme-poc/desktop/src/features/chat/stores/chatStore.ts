// TJ-ARCH-MOB-001 compliant — store layer
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { subscribeWithSelector } from 'zustand/middleware'
import { isTauri } from '@tauri-apps/api/core'
import { onChatEvent, streamAgentA2ui } from '@prometheus-ags/tauri-plugin-gen-ui'
import type { ContentBlock, Message, MessageUsage } from '@/bridge/a2ui/types'
import { applyA2uiEvent } from '@/bridge/a2ui/driver'

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
        // Store calls invoke() (via the plugin's typed wrapper) — never
        // component or hook.
        await streamAgentA2ui(
          text,
          get().messages.slice(0, -1).flatMap((m) => [m.role, m.content.find(b => b.type === 'text')?.text ?? '']),
        ).catch(console.error)
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
