// TJ-ARCH-MOB-001 compliant — component imports the hook only.
import { useEffect } from 'react'
import { useLane } from '../hooks/useLane'

/**
 * Cloud/local inference toggle, plus the honest cost of running locally:
 * download progress while weights load, tok/s once a local run completes.
 *
 * Renders nothing when no local lane exists (no Rust engine, no WebGPU) — an
 * absent capability is better hidden than shown broken.
 */
export function LaneSwitcher() {
  const { lane, localAvailable, loadProgress, throughput, error, switchLane, initLane } = useLane()

  useEffect(() => {
    void initLane()
  }, [initLane])

  if (!localAvailable) return null

  const isLoading = loadProgress !== null
  const isLocal = lane === 'local'

  return (
    <div className="flex items-center gap-3 border-b border-[color:var(--color-border)] px-4 py-2 text-xs">
      <div role="radiogroup" aria-label="Inference lane" className="flex gap-1">
        {(['cloud', 'local'] as const).map((option) => (
          <button
            key={option}
            type="button"
            role="radio"
            aria-checked={lane === option}
            disabled={isLoading}
            onClick={() => void switchLane(option)}
            className={
              lane === option
                ? 'rounded-md bg-[color:var(--color-ember)] px-3 py-1 font-medium text-white disabled:opacity-50'
                : 'rounded-md border border-[color:var(--color-border)] px-3 py-1 text-[color:var(--color-fg)] disabled:opacity-50'
            }
          >
            {option === 'cloud' ? 'Cloud' : 'On-device'}
          </button>
        ))}
      </div>

      {/* Progress and throughput are announced politely — they update mid-run
          and shouldn't interrupt a screen-reader user's current context. */}
      {isLoading && (
        <span aria-live="polite" className="text-[color:var(--color-fg)] opacity-70">
          Downloading model… {Math.round(loadProgress.progress * 100)}%
        </span>
      )}

      {!isLoading && isLocal && throughput && (
        <span aria-live="polite" className="text-[color:var(--color-fg)] opacity-70">
          {/* Labelled an estimate: WebLLM reports no usage totals, so this counts
              streamed chunks (≈1 token each) rather than measuring exactly. */}
          ~{throughput.tokensPerSecond.toFixed(1)} tok/s
        </span>
      )}

      {error && (
        <span role="alert" className="text-[color:var(--color-ember)]">
          {error}
        </span>
      )}
    </div>
  )
}
