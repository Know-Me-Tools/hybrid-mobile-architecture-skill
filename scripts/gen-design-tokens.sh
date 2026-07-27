#!/usr/bin/env bash
# scripts/gen-design-tokens.sh
# Emit BOTH surfaces' design tokens from assets/templates/design-tokens/tokens.toml.
#
# Usage: bash scripts/gen-design-tokens.sh <project-root> [tokens.toml]
#
# Writes:
#   <root>/desktop/src/theme.css              Tailwind 4 @theme block
#   <root>/mobile/lib/core/theme/tokens.dart  Dart token class
#
# The hybrid-design-tokens skill says "one token source feeds both". Before this
# script that was aspirational: the two files were hand-mirrored and had already
# diverged (#0D0D18 vs #0B0F14 for the same background role) with nothing to
# catch it. Now they are generated, so divergence is impossible rather than
# merely discouraged.
#
# Re-run after editing tokens.toml. Never hand-edit either output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-.}"
TOKENS="${2:-$SCRIPT_DIR/../assets/templates/design-tokens/tokens.toml}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

[[ -f "$TOKENS" ]] || { echo "FATAL: token source not found: $TOKENS" >&2; exit 1; }

step "Generating design tokens from $(basename "$TOKENS")"

python3 - "$TOKENS" "$ROOT" <<'PYEOF'
import sys, pathlib, tomllib

tokens_path, root = sys.argv[1], pathlib.Path(sys.argv[2])
t = tomllib.load(open(tokens_path, 'rb'))

BANNER = "GENERATED FROM assets/templates/design-tokens/tokens.toml — DO NOT EDIT."
REGEN = "Edit that file and re-run: bash scripts/gen-design-tokens.sh <root>"

dark, light = t['dark'], t['light']
space, font, types = t['space'], t['font'], t['type']

# Token names are GROUP-PREFIXED. A flat namespace collides on the obvious
# words — `surface` is a background, `primary` is a text role, and both want the
# bare name. Prefixing also makes the role legible at the call site: `textPrimary`
# says what it is, `primary` does not.
PREFIX = {'surface': 'bg', 'text': 'text', 'accent': '', 'status': ''}

def token_name(group, name):
    p = PREFIX[group]
    return name if not p else p + name[0].upper() + name[1:]

def groups(theme):
    """Flatten {surface:{...}, text:{...}} into ordered (group, name, value)."""
    for group in ('surface', 'text', 'accent', 'status'):
        for name, value in theme.get(group, {}).items():
            yield group, token_name(group, name), value

# ── Tailwind 4 @theme ───────────────────────────────────────────────────────
# Dark is the @theme default; light overrides under :root[data-theme="light"].
css = [f"/* {BANNER}", f"   {REGEN} */", "", "@theme {"]
for group, name, value in groups(dark):
    css.append(f"  --color-{name}: {value};")
css.append("")
for key, px in space.items():
    css.append(f"  --spacing-{key}: {px}px;")
css.append("")
css.append(f"  --font-display: '{font['display']}', sans-serif;")
css.append(f"  --font-sans: '{font['sans']}', sans-serif;")
css.append(f"  --font-prose: '{font['prose']}', serif;")
css.append(f"  --font-mono: '{font['mono']}', monospace;")
css.append("}")
css.append("")
css.append("/* Light theme. Same token NAMES, different values — so no component")
css.append("   ever branches on theme; it reads the role and gets the right colour. */")
css.append(':root[data-theme="light"] {')
for group, name, value in groups(light):
    css.append(f"  --color-{name}: {value};")
css.append("}")

css_out = root / "desktop" / "src" / "theme.css"
if css_out.parent.exists():
    css_out.write_text("\n".join(css) + "\n")
    print(f"  wrote {css_out.relative_to(root)}")

# ── Dart token class ────────────────────────────────────────────────────────
cls = t['meta']['dart_class']

def dart_color(hex_value):
    return f"Color(0xFF{hex_value.lstrip('#').upper()})"

dart = [
    "// TJ-ARCH-MOB-001 compliant",
    f"// {BANNER}",
    f"// {REGEN}",
    "import 'package:flutter/material.dart';",
    "import 'package:google_fonts/google_fonts.dart';",
    "",
    "/// Design tokens. Names describe the ROLE a colour plays, never the colour",
    "/// itself — `accent` survives a rebrand, `ember` does not.",
    f"abstract final class {cls} {{",
]

LABELS = {
    'surface': 'Surfaces (background ladder)',
    'text': 'Text (on-surface roles)',
    'accent': 'Accents (interactive)',
    'status': 'Status (semantic, never decorative)',
}
for group in ('surface', 'text', 'accent', 'status'):
    dart.append(f"  // {LABELS[group]}")
    for name, value in dark.get(group, {}).items():
        dart.append(f"  static const {token_name(group, name)} = {dart_color(value)};")
    for name, value in light.get(group, {}).items():
        # Light variants keep the same role name with an `OnLight` suffix: it is
        # the SAME role adjusted for a light canvas, not a second token.
        dart.append(f"  static const {token_name(group, name)}OnLight = {dart_color(value)};")
    dart.append("")

# Colour-word aliases for the status roles. They exist ONLY so older call sites
# keep compiling; every new call site should use the semantic name. A token named
# for a colour cannot be re-themed — a "red" that has to become orange is a lie
# at every use — which is why these are deprecated rather than supported.
dart.append("  // Deprecated colour-word aliases. Use the semantic name instead:")
dart.append("  // a token named for a colour cannot survive a re-theme.")
for legacy, semantic in (('amber', 'warning'), ('green', 'success'), ('red', 'danger'), ('cyan', 'info')):
    if semantic in dark.get('status', {}):
        dart.append(f"  @Deprecated('Use {semantic}')")
        dart.append(f"  static const {legacy} = {semantic};")
dart.append("")

dart.append("  // Spacing scale — off-scale padding is how rhythm dies.")
for key, px in space.items():
    dart.append(f"  static const double space{key.upper()} = {px};")
dart.append("")

GF = {'display': 'spaceGrotesk', 'sans': 'inter', 'prose': 'roboto', 'mono': 'jetBrainsMono'}
dart.append("  // Typography")
for name, spec in types.items():
    fam = GF[spec['family']]
    args = [f"fontSize: {spec['size']}", f"fontWeight: FontWeight.w{spec['weight']}"]
    if 'letter_spacing' in spec:
        args.append(f"letterSpacing: {spec['letter_spacing']}")
    args.append(f"color: {token_name('text', spec['role'])}")
    if 'height' in spec:
        args.append(f"height: {spec['height']}")
    dart.append(f"  static TextStyle get {name} => GoogleFonts.{fam}({', '.join(args)});")
dart.append("")

# Flat 2.0: regions are separated by FILLED BACKGROUNDS only — no borders, no
# divider lines, no layout shadows. This helper exists so that rule is expressed
# once instead of re-decided at every call site.
dart.append("  /// Flat 2.0 block surface: background fill only, never a border or")
dart.append("  /// shadow. An accent is carried by a left edge bar, not an outline.")
dart.append("  static BoxDecoration blockDecoration({")
dart.append("    required Color bg,")
dart.append("    Color? accent,")
dart.append("  }) => BoxDecoration(")
dart.append("        color: bg,")
dart.append("        borderRadius: BorderRadius.circular(8),")
dart.append("        border: accent == null")
dart.append("            ? null")
dart.append("            : Border(left: BorderSide(color: accent, width: 3)),")
dart.append("      );")
dart.append("}")

dart_out = root / "mobile" / "lib" / "core" / "theme" / "tokens.dart"
if dart_out.parent.exists():
    dart_out.write_text("\n".join(dart) + "\n")
    print(f"  wrote {dart_out.relative_to(root)}")
PYEOF

ok "design tokens generated for both surfaces from one source"
