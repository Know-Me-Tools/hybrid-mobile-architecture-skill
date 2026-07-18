#!/usr/bin/env bash
# scripts/add-auth.sh
# Add authentication to a Flutter or Tauri project.
# Usage: bash scripts/add-auth.sh <provider: kratos|supabase|both> <platform: flutter|tauri> [project-root]

set -euo pipefail

PROVIDER="${1:-supabase}"
PLATFORM="${2:-flutter}"
ROOT="${3:-.}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }

echo ""
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo -e "${CYAN}  Adding auth: $PROVIDER ($PLATFORM)   ${NC}"
echo -e "${CYAN}══════════════════════════════════════${NC}"

# ── Flutter ───────────────────────────────────────────────────────────────
if [[ "$PLATFORM" == "flutter" ]]; then

  AUTH_DIR="$ROOT/lib/features/auth"
  mkdir -p "$AUTH_DIR"/{data/{datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

  # Auth entity
  cat > "$AUTH_DIR/domain/entities/auth_user.dart" << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_user.freezed.dart';

@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    String? displayName,
    @Default([]) List<String> roles,
  }) = _AuthUser;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial()                    = _Initial;
  const factory AuthState.loading()                    = _Loading;
  const factory AuthState.authenticated({required AuthUser user}) = _Authenticated;
  const factory AuthState.unauthenticated()            = _Unauthenticated;
  const factory AuthState.error({required String message}) = _Error;
}
EOF
  ok "domain/entities/auth_user.dart"

  # Repository interface
  cat > "$AUTH_DIR/domain/repositories/auth_repository.dart" << 'EOF'
// TJ-ARCH-MOB-001 compliant
import '../entities/auth_user.dart';
abstract interface class AuthRepository {
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({required String email, required String password});
  Future<void>     signOut();
  Future<AuthUser?> currentUser();
  Stream<AuthState> get authStateChanges;
}
EOF
  ok "domain/repositories/AuthRepository"

  # Riverpod auth provider
  cat > "$AUTH_DIR/presentation/providers/auth_provider.dart" << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
part 'auth_provider.g.dart';

// Override this in main() with the real implementation
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => throw UnimplementedError('Override in ProviderScope overrides');

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Check initial session
    _checkInitialSession();
    return const AuthState.loading();
  }

  Future<void> _checkInitialSession() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    state = user != null ? AuthState.authenticated(user: user) : const AuthState.unauthenticated();
  }

  Future<void> signIn(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
      state = AuthState.authenticated(user: user);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signUp(email: email, password: password);
      state = AuthState.authenticated(user: user);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState.unauthenticated();
  }
}

// Convenience selector
@riverpod
bool isAuthenticated(Ref ref) =>
    ref.watch(authNotifierProvider) is _Authenticated;
EOF
  ok "presentation/providers/AuthNotifier (Riverpod)"

  if [[ "$PROVIDER" == "supabase" ]] || [[ "$PROVIDER" == "both" ]]; then
    step "Adding Supabase implementation"

    cat > "$AUTH_DIR/data/repositories/supabase_auth_repository.dart" << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Sign in failed');
    return AuthUser(id: res.user!.id, email: res.user!.email ?? email);
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (res.user == null) throw Exception('Sign up failed');
    return AuthUser(id: res.user!.id, email: res.user!.email ?? email);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<AuthUser?> currentUser() async {
    final user = _client.auth.currentUser;
    return user == null ? null : AuthUser(id: user.id, email: user.email ?? '');
  }

  @override
  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        return user != null
            ? AuthState.authenticated(user: AuthUser(id: user.id, email: user.email ?? ''))
            : const AuthState.unauthenticated();
      });
}
EOF
    ok "data/repositories/SupabaseAuthRepository"
    warn "Add supabase_flutter to pubspec.yaml if not present"
    warn "Call Supabase.initialize(url:, anonKey:) in main() before runApp()"
  fi

  if [[ "$PROVIDER" == "kratos" ]] || [[ "$PROVIDER" == "both" ]]; then
    step "Adding Ory Kratos implementation"

    cat > "$AUTH_DIR/data/repositories/kratos_auth_repository.dart" << 'EOF'
// TJ-ARCH-MOB-001 compliant
// Requires: ory_client (generated from Kratos OpenAPI spec)
// pubspec.yaml: ory_client: ^1.0.0
// or generate with: openapi-generator using https://raw.githubusercontent.com/ory/kratos/master/spec/api.json
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class KratosAuthRepository implements AuthRepository {
  final String kratosPublicUrl;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'kratos_session_token';

  KratosAuthRepository({required this.kratosPublicUrl})
      : _storage = const FlutterSecureStorage();

  // Uses raw HTTP until ory_client Dart SDK is available
  // Replace with ory_client generated FrontendApi when available

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    // 1. Create native login flow
    // 2. Submit password method
    // 3. Store session token in secure storage
    // See references/auth/patterns.md for full implementation
    throw UnimplementedError('Wire ory_client Dart SDK here');
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    throw UnimplementedError('Wire ory_client Dart SDK here');
  }

  @override
  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey);
  }

  @override
  Future<AuthUser?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    // Validate session with Kratos admin API via gen_ui_core
    return null;
  }

  @override
  Stream<AuthState> get authStateChanges =>
      Stream.value(const AuthState.unauthenticated());
}
EOF
    ok "data/repositories/KratosAuthRepository (stub)"
    warn "Full Kratos implementation: see references/auth/patterns.md"
  fi

  echo ""
  ok "Flutter auth scaffolded in $AUTH_DIR"
  echo ""
  echo "  Register implementation in ProviderScope overrides:"
  echo "    ProviderScope("
  echo "      overrides: ["
  echo "        authRepositoryProvider.overrideWithValue(SupabaseAuthRepository()),"
  echo "      ],"
  echo "      child: AppRoot(),"
  echo "    )"

# ── Tauri/React ────────────────────────────────────────────────────────────
elif [[ "$PLATFORM" == "tauri" ]]; then

  AUTH_DIR="$ROOT/src/features/auth"
  mkdir -p "$AUTH_DIR"/{api,stores,queries,hooks,components}

  # Auth types
  cat > "$AUTH_DIR/types.ts" << 'EOF'
// TJ-ARCH-MOB-001 compliant
export interface AuthUser {
  id: string;
  email: string;
  displayName?: string;
  roles: string[];
}

export interface AuthSession {
  user: AuthUser;
  accessToken: string;
  refreshToken?: string;
  expiresAt?: number;
}

export interface SignInInput { email: string; password: string }
export interface SignUpInput { email: string; password: string; displayName?: string }
EOF
  ok "types.ts"

  # Auth store (Zustand — client-side state)
  cat > "$AUTH_DIR/stores/authStore.ts" << 'EOF'
// TJ-ARCH-MOB-001 compliant — Zustand auth store
// Never imported directly by components — use useAuth() hook
import { create } from 'zustand';
import { persist, subscribeWithSelector } from 'zustand/middleware';
import type { AuthUser, AuthSession, SignInInput, SignUpInput } from '../types';

interface AuthState {
  user: AuthUser | null;
  session: AuthSession | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

interface AuthActions {
  signIn: (input: SignInInput) => Promise<void>;
  signUp: (input: SignUpInput) => Promise<void>;
  signOut: () => Promise<void>;
  clearError: () => void;
  _setSession: (session: AuthSession | null) => void;
}

export const useAuthStore = create<AuthState & AuthActions>()(
  subscribeWithSelector(
    persist(
      (set, _get) => ({
        user: null, session: null,
        isAuthenticated: false, isLoading: false, error: null,

        // Store manages all auth interactions — never components
        signIn: async ({ email, password }: SignInInput) => {
          set({ isLoading: true, error: null });
          try {
            // TODO: swap provider impl below
            const { supabaseAuth } = await import('../api/supabaseAuthApi');
            const session = await supabaseAuth.signIn(email, password);
            set({ session, user: session.user, isAuthenticated: true, isLoading: false });
          } catch (e) {
            set({ error: (e as Error).message, isLoading: false });
            throw e;
          }
        },

        signUp: async ({ email, password }: SignUpInput) => {
          set({ isLoading: true, error: null });
          try {
            const { supabaseAuth } = await import('../api/supabaseAuthApi');
            const session = await supabaseAuth.signUp(email, password);
            set({ session, user: session.user, isAuthenticated: true, isLoading: false });
          } catch (e) {
            set({ error: (e as Error).message, isLoading: false });
            throw e;
          }
        },

        signOut: async () => {
          const { supabaseAuth } = await import('../api/supabaseAuthApi');
          await supabaseAuth.signOut();
          set({ user: null, session: null, isAuthenticated: false });
        },

        clearError: () => set({ error: null }),
        _setSession: (session) => set({
          session, user: session?.user ?? null,
          isAuthenticated: !!session,
        }),
      }),
      { name: 'auth-state', partialize: (s) => ({ session: s.session, user: s.user, isAuthenticated: s.isAuthenticated }) }
    )
  )
);
EOF
  ok "stores/authStore.ts (Zustand)"

  # Supabase auth API
  if [[ "$PROVIDER" == "supabase" ]] || [[ "$PROVIDER" == "both" ]]; then
    cat > "$AUTH_DIR/api/supabaseAuthApi.ts" << 'EOF'
// TJ-ARCH-MOB-001 compliant — API layer (called only from auth store)
import { createClient } from '@supabase/supabase-js';
import type { AuthSession } from '../types';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
);

// Initialize auth state listener (call from store setup)
export function initSupabaseAuthListener(onSessionChange: (session: AuthSession | null) => void) {
  supabase.auth.onAuthStateChange((_, session) => {
    onSessionChange(session ? {
      user: { id: session.user.id, email: session.user.email!, roles: [] },
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      expiresAt: session.expires_at,
    } : null);
  });
}

export const supabaseAuth = {
  signIn: async (email: string, password: string): Promise<AuthSession> => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error || !data.session) throw new Error(error?.message ?? 'Sign in failed');
    return {
      user: { id: data.user.id, email: data.user.email!, roles: [] },
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
    };
  },

  signUp: async (email: string, password: string): Promise<AuthSession> => {
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error || !data.user) throw new Error(error?.message ?? 'Sign up failed');
    return { user: { id: data.user.id, email: data.user.email!, roles: [] }, accessToken: '' };
  },

  signOut: () => supabase.auth.signOut().then(({ error }) => { if (error) throw error; }),

  // Export for registered Prometheus Entity Management transports
  client: supabase,
};
EOF
    ok "api/supabaseAuthApi.ts"
    warn "Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY to .env"
  fi

  # Kratos auth API
  if [[ "$PROVIDER" == "kratos" ]] || [[ "$PROVIDER" == "both" ]]; then
    cat > "$AUTH_DIR/api/kratosAuthApi.ts" << 'EOF'
// TJ-ARCH-MOB-001 compliant — Ory Kratos API (called only from auth store)
// Uses Kratos public API (never admin API from client)
const KRATOS_URL = import.meta.env.VITE_KRATOS_PUBLIC_URL;

export const kratosAuth = {
  signIn: async (identifier: string, password: string) => {
    // 1. Init login flow
    const { id: flowId } = await fetch(`${KRATOS_URL}/self-service/login/api`)
      .then((r) => r.json());
    // 2. Submit credentials
    const res = await fetch(`${KRATOS_URL}/self-service/login?flow=${flowId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ method: 'password', identifier, password }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error?.message ?? 'Login failed');
    return {
      user: { id: data.session.identity.id, email: identifier, roles: [] },
      accessToken: data.session_token ?? '',
      sessionToken: data.session_token,
    };
  },

  signOut: async (sessionToken: string) => {
    await fetch(`${KRATOS_URL}/self-service/logout/api`, {
      method: 'DELETE',
      headers: { 'X-Session-Token': sessionToken },
    });
  },
};
EOF
    ok "api/kratosAuthApi.ts"
    warn "Add VITE_KRATOS_PUBLIC_URL to .env"
  fi

  # Feature hook
  cat > "$AUTH_DIR/hooks/useAuth.ts" << 'EOF'
// TJ-ARCH-MOB-001 compliant — Auth hook (what components use)
import { useAuthStore } from '../stores/authStore';
import type { SignInInput, SignUpInput } from '../types';

export function useAuth() {
  const user            = useAuthStore((s) => s.user);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading       = useAuthStore((s) => s.isLoading);
  const error           = useAuthStore((s) => s.error);
  const signIn          = useAuthStore((s) => s.signIn);
  const signUp          = useAuthStore((s) => s.signUp);
  const signOut         = useAuthStore((s) => s.signOut);
  const clearError      = useAuthStore((s) => s.clearError);

  return { user, isAuthenticated, isLoading, error, signIn, signUp, signOut, clearError };
}
EOF
  ok "hooks/useAuth.ts"

  # Login component
  cat > "$AUTH_DIR/components/LoginForm.tsx" << 'EOF'
// TJ-ARCH-MOB-001 compliant — Component imports only hook
import { useState } from 'react';
import { useAuth } from '../hooks/useAuth';

export function LoginForm() {
  const [email, setEmail]       = useState('');
  const [password, setPassword] = useState('');
  const { signIn, isLoading, error } = useAuth(); // ← only hook, never store directly

  return (
    <form className="flex flex-col gap-4 w-full max-w-sm" onSubmit={(e) => {
      e.preventDefault();
      signIn({ email, password });
    }}>
      {error && <p className="text-destructive text-sm">{error}</p>}
      <input
        type="email" value={email} onChange={(e) => setEmail(e.target.value)}
        placeholder="Email" required
        className="px-3 py-2 rounded-md border border-border bg-surface text-sm"
      />
      <input
        type="password" value={password} onChange={(e) => setPassword(e.target.value)}
        placeholder="Password" required
        className="px-3 py-2 rounded-md border border-border bg-surface text-sm"
      />
      <button type="submit" disabled={isLoading}
        className="px-4 py-2 rounded-md bg-ember text-white text-sm font-medium disabled:opacity-50">
        {isLoading ? 'Signing in...' : 'Sign in'}
      </button>
    </form>
  );
}
EOF
  ok "components/LoginForm.tsx"

  # TanStack Router auth guard
  cat > "$AUTH_DIR/guards/authGuard.ts" << 'EOF'
// TJ-ARCH-MOB-001 compliant — TanStack Router auth guard
import { redirect } from '@tanstack/react-router';
import { useAuthStore } from '../stores/authStore';

// Use as beforeLoad in protected routes:
// const protectedRoute = createRoute({
//   beforeLoad: authGuard,
// });
export function authGuard() {
  const isAuthenticated = useAuthStore.getState().isAuthenticated;
  if (!isAuthenticated) throw redirect({ to: '/login', search: { redirect: window.location.pathname } });
}
EOF
  ok "guards/authGuard.ts (TanStack Router)"

  echo ""
  ok "Tauri/React auth scaffolded in $AUTH_DIR"
fi
