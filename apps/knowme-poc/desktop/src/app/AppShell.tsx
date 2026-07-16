// TJ-ARCH-MOB-001 compliant — component; imports the router's own hooks only.
//
// Top-level navigation chrome. ONE convention, no platform detection:
//
//   phone width  → bottom navigation bar
//   wider        → side rail
//
// WHY no platform detection (C-113 T2, user-ratified — see the phase decision log):
// iOS and Android do NOT disagree here. Apple's HIG puts the tab bar at the BOTTOM
// for "top-level sections"; Material 3 says navigation bars are "always placed at
// the bottom" for "top-level destinations". A single bottom bar satisfies both at
// once, so adaptive nav would buy nothing — while costing UA-sniffing (fragile;
// Client Hints deliberately reduce the signal) and two nav trees to test. M3's top
// tabs are a different component for a different purpose ("navigation for distinct
// pages and tabs for related content within a page"), not a rival placement.
//
// The real split is by FORM FACTOR, not OS: Apple moves the tab bar to the top on
// iPad; M3 swaps the bottom bar for a rail at expanded widths. Both abandon bottom
// placement as windows widen — hence the breakpoint below, not a platform check.
// The same bundle serves Tauri desktop and mobile-web PWA, so this is one layout
// responding to width, exactly as both platforms prescribe.
import { Link, useRouterState } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import { DESTINATIONS } from './navigation'

// The `sm:` breakpoint is set to 600px in index.css — M3's compact→medium
// window-size-class boundary, not Tailwind's 640px default. Below it: bottom bar.
// At/above it: rail.

function useIsActive(path: string): boolean {
  const pathname = useRouterState({ select: (s) => s.location.pathname })
  // '/' is the chat index — exact-match it, or it would light up on every route.
  return path === '/' ? pathname === '/' : pathname.startsWith(path)
}

function NavItem({ path, label, icon: Icon }: (typeof DESTINATIONS)[number]) {
  const isActive = useIsActive(path)
  return (
    <Link
      to={path}
      aria-current={isActive ? 'page' : undefined}
      className={[
        'flex flex-1 flex-col items-center justify-center gap-1 rounded-md py-2 text-xs',
        'focus-visible:outline-2 focus-visible:outline-[color:var(--color-ember)]',
        'sm:w-full sm:flex-none',
        isActive
          ? 'text-[color:var(--color-ember)]'
          : 'text-[color:var(--color-fg)] opacity-60 hover:opacity-100',
      ].join(' ')}
    >
      <Icon aria-hidden width={20} height={20} />
      <span>{label}</span>
    </Link>
  )
}

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex h-full flex-col sm:flex-row">
      {/* Rail — wide windows only. Leading in the row layout.
          Both navs are labelled distinctly: only one is ever visible, but
          `hidden` still leaves the other in the a11y tree in some engines, and two
          identically-named "Main" landmarks would be ambiguous to a screen reader. */}
      <nav
        aria-label="Main (rail)"
        className="hidden shrink-0 flex-col gap-1 border-r border-[color:var(--color-border)] p-2 sm:flex sm:w-20"
      >
        {DESTINATIONS.map((d) => (
          <NavItem key={d.path} {...d} />
        ))}
      </nav>

      <main className="min-h-0 flex-1 overflow-hidden">{children}</main>

      {/* Bottom bar — phone width only. Rendered after <main> so it sits below
          content in the column layout; env(safe-area-inset-bottom) clears the iOS
          home indicator when installed as a PWA. */}
      <nav
        aria-label="Main (bottom bar)"
        className="flex shrink-0 border-t border-[color:var(--color-border)] pb-[env(safe-area-inset-bottom)] sm:hidden"
      >
        {DESTINATIONS.map((d) => (
          <NavItem key={d.path} {...d} />
        ))}
      </nav>
    </div>
  )
}
