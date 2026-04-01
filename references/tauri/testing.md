# Tauri + React Testing Reference
> Vitest · React Testing Library · @testing-library/user-event · msw

## Unit testing Zustand stores

```typescript
// src/features/chat/stores/__tests__/chatStore.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useChatStore } from '../chatStore'

// Reset store between tests
beforeEach(() => {
  useChatStore.setState({
    messages:    [],
    isStreaming:  false,
    activeRunId: null,
  })
})

describe('chatStore', () => {
  it('streamBlock appends a new block', () => {
    const { streamBlock, messages } = useChatStore.getState()

    // First add a message to stream into
    useChatStore.setState({
      messages: [{ id: 'msg-1', role: 'assistant', content: [], timestamp: new Date().toISOString() }],
    })

    streamBlock({
      messageId: 'msg-1',
      block: { type: 'text', text: 'Hello', isStreaming: true },
    })

    const updated = useChatStore.getState().messages
    expect(updated[0].content).toHaveLength(1)
    expect(updated[0].content[0]).toMatchObject({ type: 'text', text: 'Hello' })
  })

  it('finalizeMessage sets isStreaming to false', () => {
    useChatStore.setState({
      messages: [{ id: 'msg-1', role: 'assistant', content: [], isStreaming: true, timestamp: '' }],
      isStreaming: true,
    })

    useChatStore.getState().finalizeMessage('msg-1', { outputTokens: 42 })

    const state = useChatStore.getState()
    expect(state.messages[0].isStreaming).toBe(false)
    expect(state.isStreaming).toBe(false)
  })
})
```

## Testing hooks with React Testing Library

```typescript
// src/features/memory/hooks/__tests__/useMemory.test.ts
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { vi, describe, it, expect } from 'vitest'
import { useMemory } from '../useMemory'

// Mock Tauri invoke
vi.mock('@tauri-apps/api/core', () => ({
  invoke: vi.fn(),
}))

const createWrapper = () => {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  )
}

describe('useMemory', () => {
  it('returns filtered memories', async () => {
    const { invoke } = await import('@tauri-apps/api/core')
    vi.mocked(invoke).mockResolvedValue([
      { key: 'note-1', value: 'Flutter patterns', memoryType: 'semantic', namespace: 'default' },
      { key: 'note-2', value: 'Rust patterns',    memoryType: 'semantic', namespace: 'default' },
    ])

    const { result } = renderHook(() => useMemory('Flutter'), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(result.current.memories).toHaveLength(1)
    expect(result.current.memories[0].key).toBe('note-1')
  })
})
```

## Component testing

```typescript
// src/features/auth/components/__tests__/LoginForm.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { LoginForm } from '../LoginForm'
import { useAuthStore } from '../../stores/authStore'

beforeEach(() => {
  useAuthStore.setState({ user: null, isAuthenticated: false, isLoading: false, error: null })
})

describe('LoginForm', () => {
  it('calls signIn with email and password', async () => {
    const mockSignIn = vi.fn().mockResolvedValue(undefined)
    useAuthStore.setState({ signIn: mockSignIn } as never)

    render(<LoginForm />)

    await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com')
    await userEvent.type(screen.getByLabelText(/password/i), 'secret123')
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(mockSignIn).toHaveBeenCalledWith('test@example.com', 'secret123')
    })
  })

  it('shows error message when auth fails', async () => {
    useAuthStore.setState({ error: 'Invalid credentials', isLoading: false } as never)
    render(<LoginForm />)
    expect(screen.getByText(/invalid credentials/i)).toBeInTheDocument()
  })
})
```

## TanStack Query testing with MSW

```typescript
// src/test/handlers.ts (MSW handlers for Supabase REST)
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('*/rest/v1/profiles', () => {
    return HttpResponse.json([
      { id: '1', email: 'test@example.com', display_name: 'Test User', role: 'user' },
    ])
  }),
  http.post('*/auth/v1/token', () => {
    return HttpResponse.json({
      access_token: 'mock_token',
      user: { id: '1', email: 'test@example.com' },
    })
  }),
]
```

## Integration test: layer contract enforcement

```typescript
// src/features/chat/components/__tests__/MessageBubble.test.tsx
// Verifies that component does not import stores directly

import { describe, it, expect } from 'vitest'
import { readFileSync } from 'fs'

describe('Layer contract: MessageBubble', () => {
  it('does not import stores directly', () => {
    const src = readFileSync('src/features/chat/components/MessageBubble.tsx', 'utf-8')
    expect(src).not.toMatch(/from.*stores\/.*Store/)
    expect(src).not.toMatch(/invoke\(/)
  })

  it('only imports from hooks layer', () => {
    const src = readFileSync('src/features/chat/components/MessageBubble.tsx', 'utf-8')
    // Should import from hooks, not stores
    const storeImports = (src.match(/from ['"]\.\.\/stores/g) ?? []).length
    expect(storeImports).toBe(0)
  })
})
```
