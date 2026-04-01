#!/usr/bin/env bash
# scripts/scaffold-flutter.sh
# Scaffold a Flutter + Rust FFI mobile app with Riverpod, clean architecture, shadcn_flutter
# Usage: bash scripts/scaffold-flutter.sh <output-dir> <app-name>

set -euo pipefail

OUT="${1:-mobile}"
APP_NAME="${2:-my_app}"
SNAKE_NAME="$(echo "$APP_NAME" | tr '-' '_' | tr '[:upper:]' '[:lower:]')"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

step "Creating Flutter app: $APP_NAME"
flutter create \
  --org ai.prometheusags \
  --template app \
  --platforms ios,android,macos \
  --no-pub \
  "$OUT"

cd "$OUT"

# ── pubspec.yaml ───────────────────────────────────────────────────────────
step "Writing pubspec.yaml"
cat > pubspec.yaml << PUBEOF
name: ${SNAKE_NAME}
description: "${APP_NAME} — Hybrid mobile application (Prometheus AGS pattern)"
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # ── State management ──────────────────────────────────────────────────
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # ── Models ────────────────────────────────────────────────────────────
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # ── FFI bridge ────────────────────────────────────────────────────────
  flutter_rust_bridge: ^2.3.0

  # ── UI components (shadcn/ui equivalent) ─────────────────────────────
  shadcn_flutter: ^0.1.6

  # ── Navigation ────────────────────────────────────────────────────────
  go_router: ^15.0.0

  # ── Markdown + code highlighting ─────────────────────────────────────
  markdown_widget: ^2.3.2+6
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0

  # ── Typography ────────────────────────────────────────────────────────
  google_fonts: ^6.2.1

  # ── Animation ─────────────────────────────────────────────────────────
  flutter_animate: ^4.5.0

  # ── Storage / auth ────────────────────────────────────────────────────
  flutter_secure_storage: ^9.2.2
  supabase_flutter: ^2.8.0

  # ── Utilities ─────────────────────────────────────────────────────────
  gap: ^3.0.1
  uuid: ^4.5.1
  intl: ^0.19.0
  path_provider: ^2.1.4
  collection: ^1.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.3
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.3

flutter:
  uses-material-design: true
PUBEOF
ok "pubspec.yaml"

# ── Directory structure ───────────────────────────────────────────────────
step "Creating feature-based clean architecture"
mkdir -p lib/{app,core/{theme,errors,extensions},shared/{widgets,providers},bridge/{a2ui,agui}}
mkdir -p lib/features/{chat/{data/{repositories,datasources,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets/blocks}},auth/{data,domain,presentation/{providers,screens,widgets}},memory/{data,domain,presentation},settings/{data,domain,presentation}}

# ── analysis_options.yaml ─────────────────────────────────────────────────
cat > analysis_options.yaml << EOF
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "lib/bridge/generated_api.dart"
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_single_quotes: true
    avoid_print: true
    require_trailing_commas: true
    sort_pub_dependencies: false
EOF
ok "analysis_options.yaml"

# ── App theme stub ────────────────────────────────────────────────────────
mkdir -p lib/core/theme
cat > lib/core/theme/tokens.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// Design tokens — travisjames.ai brand system
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class T {
  // Backgrounds
  static const bgPrimary  = Color(0xFF0D0D18);
  static const bgSurface  = Color(0xFF121220);
  static const bgElevated = Color(0xFF181828);
  static const bgOverlay  = Color(0xFF1E1E35);

  // Accents
  static const ember   = Color(0xFFFF6A3D);
  static const violet  = Color(0xFF8B78FF);
  static const cyan    = Color(0xFF22D3EE);
  static const amber   = Color(0xFFF5A623);
  static const green   = Color(0xFF34D399);
  static const red     = Color(0xFFF87171);

  // Text
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9898C0);
  static const textTertiary  = Color(0xFF5E5E88);
  static const textDisabled  = Color(0xFF3A3A60);

  // Typography
  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.03, color: textPrimary);
  static TextStyle get uiMd      => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary);
  static TextStyle get prose     => GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.75);
  static TextStyle get mono      => GoogleFonts.jetBrainsMono(fontSize: 12.5, fontWeight: FontWeight.w400, color: textPrimary, height: 1.55);
}
EOF
ok "lib/core/theme/tokens.dart"

# ── main.dart stub ────────────────────────────────────────────────────────
cat > lib/main.dart << EOF
// TJ-ARCH-MOB-001 compliant
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'app/router.dart';
// import 'bridge/rust_bridge_provider.dart'; // Uncomment after frb codegen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialise Rust runtime (uncomment after building gen_ui_core)
  // final dir = await getApplicationDocumentsDirectory();
  // await initRustBridge(dataDir: dir.path);
  // await setApiKey(const String.fromEnvironment('ANTHROPIC_API_KEY'));

  runApp(const ProviderScope(child: AppRoot()));
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) => ShadcnApp.router(
    theme: ShadcnThemeData(
      colorScheme: ShadcnColorScheme.dark(),
      radius: BorderRadius.circular(8),
    ),
    debugShowCheckedModeBanner: false,
    routerConfig: appRouter,
  );
}
EOF
ok "lib/main.dart"

# ── Router stub ───────────────────────────────────────────────────────────
cat > lib/app/router.dart << EOF
// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Center(child: Text('${APP_NAME}')))),
  ],
);
EOF
ok "lib/app/router.dart"

# ── Bridge stubs ──────────────────────────────────────────────────────────
cat > lib/bridge/rust_bridge_provider.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// Uncomment imports and replace stubs after running: flutter_rust_bridge_codegen generate
// import 'generated_api.dart' as ffi;

Future<void> initRustBridge({String? dataDir}) async {
  // await ffi.initCore(workerThreads: null, dataDir: dataDir);
}

Future<void> setApiKey(String key) async {
  // await ffi.setApiKey(key: key);
}
EOF
ok "lib/bridge/rust_bridge_provider.dart"

# ── Build scripts ──────────────────────────────────────────────────────────
mkdir -p ../scripts/{android,ios}
cat > ../scripts/android/build.sh << 'BEOF'
#!/usr/bin/env bash
# Build gen_ui_core for all Android ABIs
set -euo pipefail
PROFILE="${1:-release}"
ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
RUST_DIR="$ROOT/rust"
OUT="$ROOT/mobile/android/app/src/main/jniLibs"
declare -A ABIS=(["arm64-v8a"]="aarch64-linux-android" ["armeabi-v7a"]="armv7-linux-androideabi" ["x86_64"]="x86_64-linux-android")
for ABI in "${!ABIS[@]}"; do
  TARGET="${ABIS[$ABI]}"
  cargo ndk --target "$ABI" --platform 24 -- build --manifest-path "$RUST_DIR/Cargo.toml" --target "$TARGET" $([[ "$PROFILE" == "release" ]] && echo "--release")
  mkdir -p "$OUT/$ABI"
  cp "$RUST_DIR/target/$TARGET/$PROFILE/libgen_ui_core.so" "$OUT/$ABI/"
  echo "✓ $ABI"
done
if command -v flutter_rust_bridge_codegen &>/dev/null; then
  flutter_rust_bridge_codegen generate \
    --rust-input "$RUST_DIR/gen_ui_core/src/api.rs" \
    --dart-output "$ROOT/mobile/lib/bridge/generated_api.dart"
  echo "✓ Dart bindings generated"
fi
BEOF
chmod +x ../scripts/android/build.sh

cat > ../scripts/ios/build-xcframework.sh << 'BEOF'
#!/usr/bin/env bash
# Build universal XCFramework for iOS + Simulator
set -euo pipefail
PROFILE="${1:-release}"
ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
RUST_DIR="$ROOT/rust"
BUILD="$ROOT/scripts/ios/build"
FLAGS=(); [[ "$PROFILE" == "release" ]] && FLAGS+=(--release)
mkdir -p "$BUILD"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" --target aarch64-apple-ios "${FLAGS[@]}"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" --target aarch64-apple-ios-sim "${FLAGS[@]}"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" --target x86_64-apple-ios "${FLAGS[@]}"
SIM_FAT="$BUILD/libgen_ui_core_sim.a"
lipo -create \
  "$RUST_DIR/target/aarch64-apple-ios-sim/$PROFILE/libgen_ui_core.a" \
  "$RUST_DIR/target/x86_64-apple-ios/$PROFILE/libgen_ui_core.a" \
  -output "$SIM_FAT"
XCFW="$BUILD/GenUICore.xcframework"
rm -rf "$XCFW"
xcodebuild -create-xcframework \
  -library "$RUST_DIR/target/aarch64-apple-ios/$PROFILE/libgen_ui_core.a" \
  -library "$SIM_FAT" \
  -output "$XCFW"
mkdir -p "$ROOT/mobile/ios/Frameworks"
cp -R "$XCFW" "$ROOT/mobile/ios/Frameworks/"
echo "✓ XCFramework → mobile/ios/Frameworks/"
BEOF
chmod +x ../scripts/ios/build-xcframework.sh
ok "Build scripts"

step "Installing Flutter dependencies"
flutter pub get
ok "flutter pub get"

echo ""
echo -e "${GREEN}✅ Flutter app scaffolded in $OUT/${NC}"
