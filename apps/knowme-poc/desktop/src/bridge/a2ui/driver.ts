// TJ-ARCH-MOB-001 compliant
import type { ContentBlock, MessageUsage } from './types'

export type CoreA2uiEvent =
  | { type: 'contentBlock'; messageId: string; blockIndex?: number; block: ContentBlock }
  | { type: 'messageComplete'; messageId: string; usage?: MessageUsage }

export function applyA2uiEvent(
  event: CoreA2uiEvent,
  streamBlock: (value: { messageId: string; blockIndex?: number; block: ContentBlock }) => void,
  finalize: (messageId: string, usage?: MessageUsage) => void,
): void {
  switch (event.type) {
    case 'contentBlock': streamBlock(event); break
    case 'messageComplete': finalize(event.messageId, event.usage); break
  }
}
