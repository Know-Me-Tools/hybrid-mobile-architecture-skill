# Model registry audit

**Audit date:** 2026-07-18
**Registry:** `docs/prompting/model-registry.yaml`
**OpenSpec change:** `prompting-guide-foundation`

This audit checked every requested model label against current official sources
before the prompting guide uses the registry for routing.

`gpt-5.6` by itself is not a valid model identifier. Prompts, skills, and
registry entries must use an exact routed identifier such as `gpt-5.6-sol`,
`gpt-5.6-terra`, or `gpt-5.6-luna`; when asking for the frontier GPT-5.6 route,
use `gpt-5.6-sol`.

## Findings

| Requested label | Registry disposition | Official evidence |
|---|---|---|
| GPT-5.6 Sol | supported exact | OpenAI model catalog lists `gpt-5.6-sol`, context, output limit, reasoning efforts, endpoints, and tool support. |
| GPT-5.6 Terra | supported exact | OpenAI model catalog lists `gpt-5.6-terra`, context, output limit, reasoning efforts, endpoints, and tool support. |
| GPT-5.6 Luna | supported exact | OpenAI model catalog lists `gpt-5.6-luna`, context, output limit, reasoning efforts, endpoints, and tool support. |
| Claude Sonnet 5 | supported exact | Anthropic model overview and launch post list `claude-sonnet-5`, availability, API use, and effort behavior. |
| Claude Opus 4.8 | supported exact | Anthropic model overview and launch post list `claude-opus-4-8`, availability, and effort behavior. |
| Claude Fable 5 | supported exact | Anthropic model overview and Fable page list `claude-fable-5`, availability, safeguards, and data-retention constraints. |
| Kimi K3 | supported exact | Kimi Code model docs list `k3`, Kimi K3, context tiers, reasoning efforts, and availability constraints. |
| Kimi K2.7 Code | supported exact | Kimi Code model docs list `kimi-for-coding` and `kimi-for-coding-highspeed` as Kimi K2.7 Code variants. |
| Kimi K2.6 | supported family/route | Kimi Code model docs state that disabling thinking for K3 or K2.7 routes to K2.6; this audit did not confirm a standalone exact API model ID. |
| MiniMax M3 | supported exact | MiniMax M3 announcement and API docs list `MiniMax-M3`, 1M context, multimodal support, thinking modes, and OpenAI-compatible calls. |
| Qwen 3.7 Max | supported exact, low confidence | Alibaba Cloud docs list Qwen3.7 family models and official Claude Code configuration examples mention `qwen3.7-max`; exact primary model-card evidence was weaker than other entries. |
| Qwen 3.6 variants | supported family | Alibaba Cloud docs list Qwen3.6 Plus and official Claude Code examples mention `qwen3.6-plus` and `qwen3.6-flash`. |
| DeepSeek V4 Pro | supported exact | DeepSeek API docs list `deepseek-v4-pro`, 1M context, tool calls, thinking modes, and pricing. |
| DeepSeek V4 Flash | supported exact | DeepSeek API docs list `deepseek-v4-flash`, 1M context, tool calls, thinking modes, pricing, and legacy alias retirement on 2026-07-24. |

## Source URLs

- https://developers.openai.com/api/docs/models
- https://developers.openai.com/api/docs/models/compare
- https://www.anthropic.com/news/claude-sonnet-5
- https://docs.anthropic.com/en/docs/about-claude/models/overview
- https://www.anthropic.com/claude/fable
- https://www.kimi.com/code/docs/en/kimi-code/models
- https://www.minimax.io/blog/minimax-m3
- https://platform.minimax.io/docs/guides/text-generation
- https://www.alibabacloud.com/help/en/model-studio/models
- https://www.alibabacloud.com/help/en/model-studio/claude-code
- https://api-docs.deepseek.com/quick_start/pricing/
- https://api-docs.deepseek.com/updates

## Registry Rules Applied

- Unsupported exact IDs are not routed as producer or critic recommendations.
- Bare `gpt-5.6` is rejected; exact suffixed IDs are required.
- Vendor benchmark and capability claims are treated as vendor-reported leads, not
  permanent proof.
- Operators must refresh the registry before production model routing because
  availability, pricing, context windows, and API aliases change.
