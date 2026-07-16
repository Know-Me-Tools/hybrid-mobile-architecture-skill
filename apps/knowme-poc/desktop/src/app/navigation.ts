// TJ-ARCH-MOB-001 compliant
//! Top-level navigation destinations, shared by every layout that renders them.
//!
//! ONE list, so a destination can't drift between the phone-width bottom bar and
//! the wide-width rail — mirroring the Flutter surface's single `_tabs` list in
//! lib/app/router.dart.
import type { ComponentType, SVGProps } from 'react'
import { MessageSquare, Brain } from 'lucide-react'

export interface Destination {
  path: string
  label: string
  icon: ComponentType<SVGProps<SVGSVGElement>>
}

/**
 * Top-level destinations, in bar order.
 *
 * Kept in lockstep with Flutter's `_tabs`, minus Notes: the React surface has no
 * notes feature (Flutter's `features/notes/` has no counterpart here), and a
 * destination that leads nowhere is worse than an absent one. Add it here the
 * moment a React notes feature exists.
 *
 * M3 wants 3–5 destinations in a navigation bar and says to use tabs below 3
 * (https://m3.material.io/components/navigation-bar/guidelines). At 2 we're under
 * that floor — an honest consequence of the surface only having two features, not
 * a design choice. Revisit when Notes lands and this reaches 3.
 */
export const DESTINATIONS: readonly Destination[] = [
  { path: '/', label: 'Chat', icon: MessageSquare },
  { path: '/memory', label: 'Memory', icon: Brain },
] as const
