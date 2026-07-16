// TJ-ARCH-MOB-001 compliant
import { createRouter, createRoute, createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'
import type { AuthState } from '@/features/auth/stores/authStore'
import { ChatScreen } from '@/features/chat/screens/ChatScreen'
import { MemoryScreen } from '@/features/memory/screens/MemoryScreen'
import { AppShell } from './AppShell'

interface RouterContext { auth: AuthState; queryClient: QueryClient }

// AppShell wraps every route, so the nav chrome is mounted once rather than by
// each screen. See AppShell for why placement responds to width, not platform.
const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: () => (
    <AppShell>
      <Outlet />
    </AppShell>
  ),
})

// PoC has no real auth backend wired yet (authStore.signIn is a stub) — the
// index route renders the chat surface directly. A '/login' route + real
// beforeLoad gate lands with the auth feature; do not gate the demo behind a
// route that doesn't exist yet.
const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: ChatScreen,
})

// Surfaces the memory/graph-RAG panel, which was built and wired but unreachable
// until C-113 added navigation. Paths here must match src/app/navigation.ts.
const memoryRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/memory',
  component: MemoryScreen,
})

export const router = createRouter({
  routeTree: rootRoute.addChildren([indexRoute, memoryRoute]),
  context: { auth: undefined!, queryClient: undefined! },
})

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
