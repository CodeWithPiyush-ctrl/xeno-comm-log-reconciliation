# Xeno Comm-Log Send Reconciliation

## Objective

Reconcile the Finance-provided `target_base` of **22** for:

- Merchant: `501`
- Month: October 2026
- Communication type: `2`
- Campaign scope: Diwali campaigns

The analysis starts with a straightforward count of communication-log rows and then applies the reporting rules around campaign eligibility, retry chains, and standalone campaigns.

---

## Reconciliation Bridge

| Step | Adjustment | Count | Reason |
|---|---|---:|---|
| 0 | Naive in-scope communication-log count | **30** | Starting point: all communication-log rows for merchant 501, communication type 2, during October 2026 |
| 1 | Exclude campaign `9004` | **26** | Campaign `9004` has `creation_status = 'approval_awaiting'`, so it is not an eligible campaign even though communication-log rows exist |
| 2 | Collapse retry family `9001 → 9002 → 9003` | **23** | 13 send attempts represent 10 distinct customers within the same retry family; subtract 3 duplicate retry attempts |
| 3 | Collapse retry family `9201 → 9202` | **22** | 6 send attempts represent 5 distinct customers within the same retry family; subtract 1 duplicate retry attempt |
| 4 | Preserve repeated sends in standalone campaign `9101` | **22** | Campaign `9101` has no retry parent, so its sends are treated as separate events. Customer `C20` appearing twice is therefore retained as two events |

### Final Reconciliation

The final `target_base` can also be expressed as:

```text
Retry family 9001 → 9002 → 9003 : 10
Standalone campaign 9101         :  7
Retry family 9201 → 9202         :  5
                                      --
Total                             : 22
