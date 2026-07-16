#!/usr/bin/env bash
# Build universal XCFramework for iOS device + simulator.
set -euo pipefail
PROFILE="${1:-release}"
ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
RUST_DIR="$ROOT/rust"
BUILD="$ROOT/scripts/ios/build"
FLAGS=(); [[ "$PROFILE" == "release" ]] && FLAGS+=(--release)
mkdir -p "$BUILD"
# The FFI staticlib crate is gen_ui_ffi (not the original architecture doc's
# gen_ui_core name — this PoC's mobile FFI leaf, see rust/crates/gen_ui_ffi).
# -p scopes the cross-compile to just this crate + its dependency graph;
# building the whole workspace for iOS targets would also try (and fail) to
# cross-compile desktop-only crates like tauri-plugin-gen-ui.
cargo build --manifest-path "$RUST_DIR/Cargo.toml" -p gen_ui_ffi --target aarch64-apple-ios "${FLAGS[@]}"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" -p gen_ui_ffi --target aarch64-apple-ios-sim "${FLAGS[@]}"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" -p gen_ui_ffi --target x86_64-apple-ios "${FLAGS[@]}"
SIM_FAT="$BUILD/libgen_ui_ffi_sim.a"
lipo -create \
  "$RUST_DIR/target/aarch64-apple-ios-sim/$PROFILE/libgen_ui_ffi.a" \
  "$RUST_DIR/target/x86_64-apple-ios/$PROFILE/libgen_ui_ffi.a" \
  -output "$SIM_FAT"
XCFW="$BUILD/GenUICore.xcframework"
rm -rf "$XCFW"
xcodebuild -create-xcframework \
  -library "$RUST_DIR/target/aarch64-apple-ios/$PROFILE/libgen_ui_ffi.a" \
  -library "$SIM_FAT" \
  -output "$XCFW"
mkdir -p "$ROOT/mobile/ios/Frameworks"
cp -R "$XCFW" "$ROOT/mobile/ios/Frameworks/"
echo "✓ XCFramework → mobile/ios/Frameworks/"
