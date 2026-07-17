#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant — pin Rust and patch generated Cargokit archives.
set -euo pipefail

MOBILE_DIR="${1:-mobile}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/dedup_archive.dart"
if [[ ! -f "$TEMPLATE" ]]; then
  TEMPLATE="${SCRIPT_DIR}/../assets/templates/cargokit/dedup_archive.dart"
fi
BUILD_TOOL="$MOBILE_DIR/rust_builder/cargokit/build_tool/lib/src"
BUILD_POD="$BUILD_TOOL/build_pod.dart"
OPTIONS="$BUILD_TOOL/options.dart"
BUILDER="$BUILD_TOOL/builder.dart"
RUSTUP="$BUILD_TOOL/rustup.dart"

if [[ ! -f "$BUILD_POD" ]]; then
  echo "Cargokit build_pod.dart not found; run flutter_rust_bridge_codegen first." >&2
  exit 1
fi

cp "$TEMPLATE" "$BUILD_TOOL/dedup_archive.dart"
ruby -e '
  options, builder, rustup = ARGV

  text = File.read(options)
  enum_block = "enum Toolchain {\n  stable,\n  beta,\n  nightly,\n}\n\n"
  text = text.sub(enum_block, "")
  text = text.sub("final Toolchain toolchain;", "final String toolchain;")
  old_parser = <<~DART.chomp
      static Toolchain _toolchainFromNode(YamlNode node) {
        if (node case YamlScalar(value: String name)) {
          final toolchain =
              Toolchain.values.firstWhereOrNull((element) => element.name == name);
          if (toolchain != null) {
            return toolchain;
          }
        }
        throw SourceSpanException(
            \x27Unknown toolchain. Must be one of \${Toolchain.values.map((e) => e.name)}.\x27,
            node.span);
      }
  DART
  new_parser = <<~DART.chomp
      static String _toolchainFromNode(YamlNode node) {
        if (node case YamlScalar(value: String name)) {
          if (name.isNotEmpty && RegExp(r\x27^[A-Za-z0-9._-]+\$\x27).hasMatch(name)) {
            return name;
          }
        }
        throw SourceSpanException(
            \x27Invalid rustup toolchain. Expected a version, channel, or named toolchain.\x27,
            node.span);
      }
  DART
  text = text.sub(old_parser, new_parser)
  text = text.sub("Toolchain toolchain = Toolchain.stable;", "String toolchain = \x271.96\x27;")
  abort "failed to pin Cargokit options toolchain" unless text.include?("String toolchain = \x271.96\x27;")
  File.write(options, text)

  text = File.read(builder)
  text = text.sub(
    "String get _toolchain => _buildOptions?.toolchain.name ?? \x27stable\x27;",
    "String get _toolchain => _buildOptions?.toolchain ?? \x271.96\x27;",
  )
  abort "failed to pin Cargokit builder toolchain" unless text.include?("?? \x271.96\x27;")
  File.write(builder, text)

  text = File.read(rustup)
  text = text.sub(
    "Pattern nonCustom = RegExp(r\x22^(stable|beta|nightly)\x22);",
    "Pattern nonCustom = RegExp(r\x22^(stable|beta|nightly|[0-9])\x22);",
  )
  abort "failed to retain version-pinned rustup toolchains" unless text.include?("nightly|[0-9]")
  File.write(rustup, text)
' "$OPTIONS" "$BUILDER" "$RUSTUP"

ruby -e '
  path = ARGV.fetch(0)
  text = File.read(path)
  import_marker = "import \x27builder.dart\x27;\n"
  import_line = "import \x27dedup_archive.dart\x27;\n"
  unless text.include?(import_line)
    abort "build_pod import marker missing" unless text.include?(import_marker)
    text = text.sub(import_marker, import_marker + import_line)
  end
  call_marker = "    if (staticLibs.isNotEmpty) {\n"
  call = call_marker +
    "      for (final lib in staticLibs) {\n" +
    "        if (dedupArchiveMembers(lib.path) > 0) {\n" +
    "          runCommand(\x22ranlib\x22, [lib.path]);\n" +
    "        }\n" +
    "      }\n"
  unless text.include?("dedupArchiveMembers(lib.path)")
    abort "build_pod static library marker missing" unless text.include?(call_marker)
    text = text.sub(call_marker, call)
  end
  File.write(path, text)
' "$BUILD_POD"

echo "Patched Cargokit Rust 1.96 pin and archive dedup: $BUILD_POD"
