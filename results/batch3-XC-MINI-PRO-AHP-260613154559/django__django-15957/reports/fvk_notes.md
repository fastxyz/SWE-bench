# reports/fvk_notes.md — FVK audit outcome for django__django-15957

## Verdict: **V1 stands; no source changes.**

Applying `/formalize` + `/verify` to the V1 fix discharged the one obligation where a
bug of this shape normally hides (the slice off-by-one) and the two control-flow
obligations introduced by the guard change, and routed the genuine ORM/SQL-machinery
obligations to the trusted base with spot-checks. **No finding rose to a correctness bug
in the supported domain.** Per the task's rule ("if V1 is already correct according to
your spec and proof obligations, it may stand unchanged … justified by the FVK
artifacts"), the three V1 edits are confirmed and left exactly as they were.

The V1 edits under audit (unchanged):
1. `related_descriptors.py`: new `_filter_prefetch_queryset` helper + imports.
2. `related_descriptors.py`: reverse-FK and m2m `get_prefetch_queryset` call the helper.
3. `query.py`: `_filter_or_exclude` slice guard gains `and not self._defer_next_filter`.

---

## Why each part stands — traced to the artifacts

### Edit 1 — the `_filter_prefetch_queryset` helper → confirmed by `(WSLICE)` / PO1–PO3
The helper's risk is entirely in the slice→row-number arithmetic. SPEC.md F1 states the
contract; PROOF_OBLIGATIONS PO1 (bounded), PO2 (`high=None`), PO3 (chained slices) and
PO0 (boundaries) are all **PROVEN** in PROOF.md via `(WSLICE)`/`(WLOOP)` over
`mini-orm.k`. The closed form `max(0, min(m,high) − low)` equals `len(rows[low:high])`,
and V1's emitted bounds `RowNumber() > low` / `RowNumber() <= high` select exactly the
positions Python `rows[low:high]` selects. So the helper is correct; I changed nothing.
- The redundant `RowNumber() > 0` when `low == 0` (FINDINGS Finding 4 / PO0) is
  **provably harmless** (size delta 0) and the QUALIFY rewrite dedupes it. The possible
  `if low_mark:` micro-optimization is behaviour-identical, so I **rejected** it
  (ITERATION_GUIDANCE G4): divergence from the established pattern with zero correctness
  gain is the wrong trade under an audit whose job is correctness.
- The `NotSupportedError` on backends without window functions (FINDINGS Finding 5) is the
  intended explicit failure, not a degradation. Kept.

### Edit 2 — the two descriptor call sites → confirmed by PO4 / PO5 (trusted base)
SPEC.md F2 fixes the tuple shape (unchanged) and the join/partition contract. PO4 (the
window `partition_by=field_name` reuses the `__in` join — one `add_q`, plus m2m
`_next_is_sticky()` preserved by V1) and PO5 (the m2m `.extra(select=…)` join-table column
survives the QUALIFY rewrite) are **TRUSTED**, but I did not take them on faith: PROOF.md
§5 and PROOF_OBLIGATIONS PO5 record a spot-check of `compiler.py:296–313` showing
extra-select aliases are *not* renamed by `with_col_aliases` (only `alias is None` model
columns become `colN`) and are re-selected in the masking branch. That removed my main
residual doubt about the m2m path. Nothing to change.

### Edit 3 — the `_filter_or_exclude` guard relaxation → confirmed by PO6 / PO7
This was V1's least-certain change, so the audit targeted it hardest. SPEC.md F3 states the
intended contract (eager filters on sliced querysets still raise; only the internal,
deferred `_apply_rel_filters` path is exempted). Two obligations, both **PROVEN** in
PROOF.md §4:
- **PO7 (containment):** a whole-repo `grep` confirms `_defer_next_filter = True` is set in
  exactly the two `_apply_rel_filters` methods, so the new clause changes behaviour for no
  user-facing eager filter. The existing tests pin both sides
  (`queries…test_slicing_cannot_filter_queryset_once_sliced` still raises;
  `queryset_pickle…test_filter_deferred` is non-sliced, hence untouched by the new
  `is_sliced` term).
- **PO6 (never executed):** in the no-`to_attr` path the deferred filter lands on a
  queryset whose `_result_cache` is then set, so `_fetch_all` short-circuits and the
  deferred filter is never compiled to SQL — relaxing the guard cannot emit a wrong query.

Because these hold, the guard relaxation is **safe and necessary** for the general issue
intent ("Prefetch objects don't work with slices" — both `to_attr` and no-`to_attr`
forms), so I kept it. FINDINGS Finding 2 records the natural consequence — the cached
no-`to_attr` queryset is itself sliced, so a *further* `.filter()` on it raises — and
classifies it as a documented limitation, not a bug. ITERATION_GUIDANCE G2 flags the one
open *intent* question (support no-`to_attr`, or require `to_attr`?) for the product owner;
the implementation is correct either way and a reversal would be a one-line change with no
other coupling.

---

## What the audit deliberately did NOT change
- **No "tidying" of the proven bounds** (G1/G4) — the proof says they are exactly right;
  touching them only risks reintroducing the off-by-one the proof rules out.
- **No auto-ordering for unordered slices** (FINDINGS Finding 3 / G3) — would silently
  change result sets; it is a docs matter, and matches plain unordered-slice semantics.
- **No new support for single-valued / GenericRelation prefetch** (FINDINGS Findings 6–7 /
  PO8/PO9 / G5) — out of scope; slicing a ≤1-per-parent relation is not meaningful, and the
  generic case needs a composite partition (a larger, separate change).

## Honesty gate
The proof is **constructed, not machine-checked** (the MVP does not run `kompile`/`kprove`;
commands are in PROOF.md §6). The Findings (no domain bug; Findings 1–7 as classified) do
not depend on that run. Test-redundancy advice (PROOF.md §7) is advisory only and
conditioned on the machine check; in practice I recommend **keeping essentially all tests**,
since the arithmetic proof covers the index math, not the ORM/SQL wiring (PO4/PO5) which
remains in the trusted base. No test files were read for pass/fail or modified.
