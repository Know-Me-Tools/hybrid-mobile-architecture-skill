// TJ-ARCH-MOB-001 compliant — component imports the hook only.
import { useState, type FormEvent } from 'react'
import { useChat } from '../hooks/useChat'

export function ChatInput() {
  const { sendMessage, isStreaming } = useChat()
  const [value, setValue] = useState('')

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const text = value.trim()
    if (!text || isStreaming) return
    setValue('')
    void sendMessage(text)
  }

  return (
    <form onSubmit={handleSubmit} className="flex gap-2 border-t border-[color:var(--color-border)] p-4">
      <label htmlFor="chat-input" className="sr-only">
        Message
      </label>
      <textarea
        id="chat-input"
        value={value}
        onChange={(event) => setValue(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault()
            event.currentTarget.form?.requestSubmit()
          }
        }}
        placeholder="Ask KnowMe anything…"
        rows={1}
        disabled={isStreaming}
        className="flex-1 resize-none rounded-md border border-[color:var(--color-border)] bg-[color:var(--color-bg)] px-3 py-2 text-sm text-[color:var(--color-fg)] focus-visible:outline-2 focus-visible:outline-[color:var(--color-ember)]"
      />
      <button
        type="submit"
        disabled={isStreaming || !value.trim()}
        className="rounded-md bg-[color:var(--color-ember)] px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
      >
        Send
      </button>
    </form>
  )
}
