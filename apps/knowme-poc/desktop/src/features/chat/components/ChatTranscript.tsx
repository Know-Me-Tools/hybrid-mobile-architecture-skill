// TJ-ARCH-MOB-001 compliant
import { ContentBlockView } from '@prometheus-ags/gen-ui-react'
import { useChat } from '../hooks/useChat'

export function ChatTranscript() {
  const { messages } = useChat()
  return <ol aria-live="polite">{messages.map((message) => <li key={message.id}>{message.content.map((block, index) => <ContentBlockView key={`${message.id}:${index}`} block={block} />)}</li>)}</ol>
}
