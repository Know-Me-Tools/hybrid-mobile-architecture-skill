// TJ-ARCH-MOB-001 compliant
import { createRouter, createRoute, createRootRouteWithContext, redirect } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'
import type { AuthState } from '@/features/auth/stores/authStore'

interface RouterContext { auth: AuthState; queryClient: QueryClient }

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: () => <div className="h-screen bg-background">outlet placeholder</div>,
})

const protectedRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'protected',
  beforeLoad: ({ context }) => {
    // '/login' is not yet a registered route in this placeholder tree — the real
    // auth route lands with the auth feature; cast keeps intent visible until then.
    if (!context.auth.isAuthenticated) throw redirect({ to: '/login' as '/' })
  },
})

export const router = createRouter({
  routeTree: rootRoute.addChildren([protectedRoute]),
  context: { auth: undefined!, queryClient: undefined! },
})

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
