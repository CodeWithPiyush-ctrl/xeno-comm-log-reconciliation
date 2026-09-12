# Xeno — Comm-Log Send Reconciliation

## Objective

Reconcile Finance's reported `target_base` of 22 for merchant 501
for October 2026 using the campaign and communication-log data.

---

## Approach

The investigation started with a naive count of communication-log
rows and then reconciled the difference by applying the reporting
eligibility and retry rules.

The key business rules are:

1. Only campaigns with a finalized creation status and
   `processing_status = 'processed'` are eligible.
2. Campaigns connected through `parent_id` form retry chains.
3. Within a retry chain, a customer is counted once across the
   underlying communication.
4. Standalone campaigns are different: every send is an independent
   event, even when the same customer appears more than once.

---

## Reconciliation Bridge

| Step | Description | Result | Reason |
|---|---|---:|---|
| 0 | Naive raw communication-log count | 30 | Starting point |
| 1 | Exclude campaign 9004 | 26 | `approval_awaiting` campaigns are not eligible for official reporting |
| 2 | Collapse retry family 9001 → 9002 → 9003 | 23 | 13 attempts represent 10 distinct customers |
| 3 | Collapse retry family 9201 → 9202 | 22 | 6 attempts represent 5 distinct customers |
| 4 | Preserve repeated C20 sends in standalone 9101 | 22 | Standalone sends are separate events |

### Final result

**target_base = 22**

The final calculation is:

- Retry family `9001 → 9002 → 9003`: 10 customers
- Standalone campaign `9101`: 7 send events
- Retry family `9201 → 9202`: 5 customers

**10 + 7 + 5 = 22**

---

## Investigation

### 1. Naive count

The first query counted all October campaign communication-log
rows for merchant 501 and returned 30.

### 2. Campaign eligibility

Campaign 9004 had communication-log rows but its creation status was
`approval_awaiting`, so its 4 rows were excluded from official
reporting.

### 3. Retry chains

The campaign hierarchy showed:

`9001 → 9002 → 9003`

and

`9201 → 9202`

These are retry chains rather than independent communications.
Customers appearing across the same chain therefore count once.

### 4. Standalone campaign

Campaign 9101 has no retry relationship. Customer C20 appears twice,
but both rows represent legitimate independent send events and
therefore both are retained.

---

## SQL

The final reconciliation query is available in:

`sql/solution.sql`

The exploratory queries used during investigation are available in:

`sql/investigation_queries.sql`

---

## Result

Finance's target_base:

# 22
