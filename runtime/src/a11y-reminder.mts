// TJ-ARCH-MOB-001 compliant
import { fstatSync, readFileSync } from 'node:fs';
export function reminder(payload: unknown): object | undefined {
  if (!payload || typeof payload !== 'object') return;
  const tool = (payload as { tool_input?: { file_path?: unknown } }).tool_input;
  if (typeof tool?.file_path !== 'string') return;
  const path = tool.file_path.replaceAll('\\', '/');
  if (!(path.endsWith('.dart') ? /(^|\/)lib\//.test(path) : /\.(tsx|jsx)$/.test(path) && /(^|\/)src\//.test(path))) return;
  return { hookSpecificOutput: { hookEventName: 'PostToolUse', additionalContext:
    `UI file edited (${tool.file_path}). Before marking done, invoke the a11y-gate skill and run the WCAG 2.2 AA checklist (contrast in both themes, keyboard reachability, accessible names, reduced motion, live-region announcements).` } };
}
try {
  const input = fstatSync(0);
  if (input.isFIFO() || input.isFile() || input.isSocket()) {
    const result = reminder(JSON.parse(readFileSync(0, 'utf8')));
    if (result) process.stdout.write(`${JSON.stringify(result)}\n`);
  }
} catch { /* Advisory only, including malformed or absent input. */ }
