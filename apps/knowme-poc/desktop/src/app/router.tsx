// TJ-ARCH-MOB-001 compliant
import { createRouter, createRoute, createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'
import type { AuthState } from '@/features/auth/stores/authStore'
import { ChatScreen } from '@/features/chat/screens/ChatScreen'

interface RouterContext { auth: AuthState; queryClient: QueryClient }

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: () => <Outlet />,
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

export const router = createRouter({
  routeTree: rootRoute.addChildren([indexRoute]),
  context: { auth: undefined!, queryClient: undefined! },
})

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
