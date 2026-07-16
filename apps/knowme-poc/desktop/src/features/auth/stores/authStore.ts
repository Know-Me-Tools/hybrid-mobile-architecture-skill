// TJ-ARCH-MOB-001 compliant — store layer (called only by hooks, never by components)
import { create } from 'zustand'
import { subscribeWithSelector, persist } from 'zustand/middleware'

export interface AuthState {
  user: { id: string; email: string } | null
  session: unknown | null
  isAuthenticated: boolean
}

interface AuthActions {
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

export const useAuthStore = create<AuthState & AuthActions>()(
  subscribeWithSelector(
    persist(
      (set) => ({
        user: null,
        session: null,
        isAuthenticated: false,
        signIn: async (email, _password) => {
          // TODO: implement via Supabase or Kratos
          // Store calls invoke() or supabase SDK here — never a component
          set({ user: { id: '1', email }, isAuthenticated: true })
        },
        signOut: async () => {
          set({ user: null, session: null, isAuthenticated: false })
        },
      }),
      { name: 'auth-state' }
    )
  )
)
