// TJ-ARCH-MOB-001 compliant
/// ContentBlock — the cross-platform UI contract, mirrored from gen_ui_types.
/// In the host app this is the frb-generated union; this sealed hierarchy lets
/// the widget package compile and be tested standalone. Dart's exhaustive
/// switch on a sealed type is a compile error if a variant is unhandled — the
/// same guarantee the Rust match site has.
sealed class ContentBlock {
  const ContentBlock();
}

class TextBlock extends ContentBlock {
  final String text;
  const TextBlock(this.text);
}

class ThinkingBlock extends ContentBlock {
  final String text;
  const ThinkingBlock(this.text);
}

class CodeBlock extends ContentBlock {
  final String language;
  final String code;
  const CodeBlock(this.language, this.code);
}

class CitationBlock extends ContentBlock {
  final String source;
  final String quote;
  const CitationBlock(this.source, this.quote);
}

class MemoryBlock extends ContentBlock {
  final String operation;
  final String key;
  final String? value;
  const MemoryBlock(this.operation, this.key, this.value);
}

class ToolUseBlock extends ContentBlock {
  final String id;
  final String name;
  final String inputJson;
  const ToolUseBlock(this.id, this.name, this.inputJson);
}

class ToolResultBlock extends ContentBlock {
  final String toolUseId;
  final String outputJson;
  final bool isError;
  const ToolResultBlock(this.toolUseId, this.outputJson, this.isError);
}

class SkillBlock extends ContentBlock {
  final String name;
  final String status;
  const SkillBlock(this.name, this.status);
}

class ArtifactBlock extends ContentBlock {
  final String id;
  final String kind;
  final String content;
  const ArtifactBlock(this.id, this.kind, this.content);
}

class ImageBlock extends ContentBlock {
  final String? url;
  final String? dataBase64;
  final String mime;
  const ImageBlock(this.url, this.dataBase64, this.mime);
}

class DividerBlock extends ContentBlock {
  const DividerBlock();
}
