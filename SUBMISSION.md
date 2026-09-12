# Comm-Log Send Reconciliation — Submission

Merchant 501, October 2026, all Diwali campaigns. Target (per Finance): **22**.

## 1. Reconciliation Bridge

| Step | Description | Result | Reason |
|---|---|---|---|
| 0 | Naive count: `SELECT COUNT(*) FROM communication_log` | 30 | Starting point — every send-attempt row, no filtering applied. |
| 0.5 | Confirm scope (`merchant_id = 501`, `communication_type = '2'`, sends in October 2026) | 30 (no change) | Checked rather than assumed — every row already satisfies the assignment's stated scope, so no rows are dropped here. |
| 1 | Exclude rows belonging to campaigns that haven't cleared approval (`creation_status = 'approval_awaiting'`) | 26 (−4) | Campaign 9004 (a retry of 9001) already has `processing_status = 'processed'` and 4 log rows exist for it, but per the data dictionary a campaign only counts once *both* creation **and** processing have cleared. The send pipeline ran ahead of approval bookkeeping. These 4 rows (customers C11–C14) don't belong in reporting yet. |
| 2a | Within retry chain 9001 → 9002 → 9003, collapse to distinct customers rather than counting every attempt | 23 (−3) | A retry chain is one underlying communication. 13 remaining rows in this chain, but only 10 distinct customers — C2 and C3 were each attempted twice within the chain before landing (or failing every time). |
| 2b | Within retry chain 9201 → 9202, collapse to distinct customers | 22 (−1) | Same logic: 6 rows, 5 distinct customers — D1 was retried once within the chain. |
| final | Standalone campaign 9101 (no parent, no children) is left un-collapsed | **22** | Its 7 rows all stay as 7 qualifying sends. C20's two sends under 9101 are a genuine re-target (no `parent_id` link), not a retry — the data dictionary explicitly distinguishes this from a retry chain, and collapsing it would have undercounted to 21. |

## 2. SQL Query

See [`solution.sql`](./solution.sql) — runnable directly against `data/comm_log.db`:

```
sqlite3 data/comm_log.db < solution.sql
```

Per-chain breakdown it produces: chain 9001 → 10, chain 9201 → 5, standalone 9101 → 7 → **22 total**.

Key logic: `chain_size` is computed over *all* campaigns in the structural retry chain (including ineligible ones like 9004) — a chain still "exists" structurally even if one retry branch hasn't cleared approval. Eligibility only gates which log rows get counted, not whether the chain is treated as a chain. Chains with more than one campaign are deduplicated by customer; chains of size 1 (standalone campaigns) count every row.

## 3. What surprised me

Two things stood out during investigation. First, campaign 9004 already had 4 fully-delivered log rows despite sitting in `approval_awaiting` — a reminder that "the send pipeline can run ahead of approval bookkeeping" isn't just a hypothetical caveat in the README, it's live in the data, and a naive query would silently count sends for a campaign Finance hasn't signed off on. Second, the standalone campaign 9101 has customer C20 appearing twice, ten days apart — visually identical to a retry-chain duplicate, but with no `parent_id` link it's a legitimate independent re-target. My first instinct was to collapse any repeated customer regardless of chain structure, which would have undercounted by 1 (giving 21 instead of 22). The distinction only becomes clear once you check whether an actual chain structure (via `parent_id`) exists, rather than pattern-matching on repeated customer IDs alone.
