// TJ-ARCH-MOB-001 compliant
import { ChatTranscript } from '../components/ChatTranscript'
import { ChatInput } from '../components/ChatInput'
import { LaneSwitcher } from '../components/LaneSwitcher'

export function ChatScreen() {
  return (
    <div className="flex h-full flex-col overflow-hidden">
      <LaneSwitcher />
      <div className="flex-1 overflow-y-auto p-4">
        <ChatTranscript />
      </div>
      <ChatInput />
    </div>
  )
}
