// TJ-ARCH-MOB-001 compliant
//! DIY write queue: durable local action log replayed through a [`WriteSink`]
//! (forge Quarry API) with idempotent keys, exponential backoff, and a poison
//! handler. Read-path is Electric; this is the write-path half of local-first.
//!
//! The in-memory queue here is the replay engine; durability (survive restart) is
//! delegated to the same [`LocalStore`]-backed action-log table C-003 owns — this
//! module keeps the seam so persistence wires in without changing the replay logic.
use super::config::SyncConfig;
use super::seam::{PendingWrite, WriteOutcome, WriteSink};
use super::status::SyncStatusHandle;
use std::collections::VecDeque;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;

/// Backoff schedule for transient write failures (capped exponential).
const BACKOFF_BASE: Duration = Duration::from_millis(200);
const BACKOFF_MAX: Duration = Duration::from_secs(30);

fn backoff_for(attempt: u32) -> Duration {
    // 200ms, 400ms, 800ms, … capped at 30s. saturating shift avoids overflow panics.
    let factor = 1u64.checked_shl(attempt.min(20)).unwrap_or(u64::MAX);
    BACKOFF_BASE.saturating_mul(factor.min(u32::MAX as u64) as u32).min(BACKOFF_MAX)
}

pub(crate) struct WriteQueue {
    sink: Arc<dyn WriteSink>,
    status: SyncStatusHandle,
    max_attempts: u32,
    batch: usize,
    // tokio::Mutex: guard is held across the sink `.await`, so a std/parking_lot
    // mutex would be !Send here. Contention is low (one drain task + enqueues).
    pending: Mutex<VecDeque<PendingWrite>>,
    poison: Mutex<Vec<PendingWrite>>,
}

impl WriteQueue {
    pub(crate) fn new(cfg: &SyncConfig, sink: Arc<dyn WriteSink>, status: SyncStatusHandle) -> Self {
        Self {
            sink,
            status,
            max_attempts: cfg.max_write_attempts,
            batch: cfg.write_batch,
            pending: Mutex::new(VecDeque::new()),
            poison: Mutex::new(Vec::new()),
        }
    }

    /// Enqueue a local mutation for replay. Idempotency-keyed so retries dedupe
    /// server-side. Updates the pending-writes count that drives the UI chip.
    pub(crate) async fn enqueue(&self, write: PendingWrite) {
        let len = {
            let mut q = self.pending.lock().await;
            q.push_back(write);
            q.len() as u32
        };
        self.status.set_pending(len);
    }

    /// Drain up to `batch` writes, replaying each through the sink. Transient
    /// failures are re-queued (front) after a backoff sleep; poison writes are moved
    /// to the poison list and surfaced. Returns how many writes remain pending.
    pub(crate) async fn drain(&self) -> u32 {
        for _ in 0..self.batch {
            let Some(mut write) = ({ self.pending.lock().await.pop_front() }) else {
                break; // queue empty
            };

            match self.sink.send(&write).await {
                WriteOutcome::Applied => {
                    // dropped — the write succeeded (or idempotently deduped).
                }
                WriteOutcome::Retry => {
                    write.attempts += 1;
                    if write.attempts >= self.max_attempts {
                        self.quarantine(write, "max attempts exceeded").await;
                    } else {
                        let delay = backoff_for(write.attempts);
                        tracing::warn!(
                            key = %write.idempotency_key,
                            attempt = write.attempts,
                            ?delay,
                            "write retry scheduled"
                        );
                        tokio::time::sleep(delay).await;
                        self.pending.lock().await.push_front(write);
                    }
                }
                WriteOutcome::Poison { reason } => self.quarantine(write, &reason).await,
            }
        }

        let remaining = self.pending.lock().await.len() as u32;
        self.status.set_pending(remaining);
        remaining
    }

    async fn quarantine(&self, write: PendingWrite, reason: &str) {
        tracing::error!(
            key = %write.idempotency_key,
            table = %write.table,
            reason,
            "write quarantined (poison)"
        );
        self.poison.lock().await.push(write);
    }

    /// Snapshot of quarantined writes for UI surfacing / manual retry tooling.
    pub(crate) async fn poison_writes(&self) -> Vec<PendingWrite> {
        self.poison.lock().await.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Boundary behavior: backoff grows exponentially from the base and never
    // exceeds the cap, even at absurd attempt counts (no overflow panic).
    #[test]
    fn backoff_is_exponential_and_capped() {
        assert_eq!(backoff_for(0), BACKOFF_BASE);
        assert_eq!(backoff_for(1), BACKOFF_BASE * 2);
        assert_eq!(backoff_for(2), BACKOFF_BASE * 4);
        assert_eq!(backoff_for(1000), BACKOFF_MAX);
        assert!(backoff_for(50) <= BACKOFF_MAX);
    }
}
