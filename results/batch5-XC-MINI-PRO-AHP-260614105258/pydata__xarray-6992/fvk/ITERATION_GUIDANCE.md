# ITERATION GUIDANCE — next-pass feedback for `reset_index` / Dataset INV

Feedback package distilled from the FVK audit, for the next code/intent iteration.
Each item: evidence → classification → UltimatePowers question → recommended
change → tests. Items are ordered by leverage.

---

## G1 — Lock the class invariant `coord_names ⊆ variables` (the real contract)

- **Evidence:** FINDINGS F1/F2, PO1/PO5. The reported `ValueError` is a *symptom*
  of a broken class invariant; `DataVariables.__len__` is correct given it.
- **Classification:** code bug (fixed: V2) + missing internal assertion.
- **UltimatePowers question:** "Should `Dataset` validate `coord_names ⊆ variables`
  (e.g. in `_construct_direct`/`_replace` under a debug/check flag), so any future
  producer that breaks it fails loudly instead of at a distant `__len__`/repr?"
- **Recommended change:** keep the V2 one-liner; *optionally* add a cheap
  invariant check in the internal constructor guarded by an existing debug switch.
  Do **not** "fix" `DataVariables.__len__` defensively — that hides producers.
- **Tests:** the #6992 regression test should assert the **structural** invariant
  (`set(ds.coords) <= set(ds.variables)`, `len(ds.data_vars) >= 0`, `repr(ds)`
  succeeds), not merely "no exception" (FINDINGS F9). *(Recommendation only — test
  files are not edited here.)*

## G2 — Adopt the `set_index` idiom in `reset_index` (done in V2)

- **Evidence:** I5, F6, F8, PO2/PO7, PROOF §5. `set_index` line 4102 already uses
  `self._coord_names - set(drop_variables) | set(new_variables)`.
- **Classification:** consistency / latent corner-case fix.
- **UltimatePowers question:** "Are there other `coord_names` builders besides
  `set_index`/`reset_index`/`_reindex_callback` that should share one audited
  helper, e.g. `_drop_and_readd_coords(C, drop, new)`?"
- **Recommended change (applied):** `coord_names = (self._coord_names -
  set(drop_variables)) | set(new_variables)`. Future: factor the shared
  `(C − D) | N` idiom into one helper to prevent drift.
- **Tests:** none new required; PO4 guarantees `drop=False` parity.

## G3 — Resolve the multi-key `drop=True` semantics (the `N ∩ D` corner, PO9)

- **Evidence:** FINDINGS F3, PO9. `reset_index(["x", "level_1"], drop=True)` on a
  ≥3-level multi-index dim `x` both resets the whole index (`x`) *and* recreates a
  reduced index from the kept levels — conflicting intent. V2 keeps the output
  *consistent* (`x` stays a proper index coordinate), but whether a reduced index
  *should* survive when the dimension itself was reset is undecided.
- **Classification:** underspecified intent (out of scope for #6992).
- **UltimatePowers question:** "When `dims_or_levels` names *both* a multi-index
  dimension and some of its levels with `drop=True`, should the result (a) drop the
  whole index, (b) keep a reduced index over the un-named levels, or (c) raise for
  the ambiguous combination?"
- **Recommended change:** decide (a/b/c) explicitly; until then V2's
  consistency-preserving behaviour is a safe default (no malformed Dataset).
- **Tests:** add a case for `reset_index([dim, level], drop=True)` on a 3-level
  multi-index once the intended answer is chosen. *(Recommendation only.)*

## G4 — `dims` not recomputed by `reset_index`

- **Evidence:** FINDINGS F5, PO10. `reset_index` reuses `self._dims`.
- **Classification:** pre-existing, benign (every reachable output keeps ≥1 var per
  surviving dim); **no change recommended** now.
- **UltimatePowers question:** "Is there any `reset_index` path that can drop the
  last variable on a dimension, leaving a stale `_dims` entry? If so, pass
  recomputed `dims` to `_replace`."
- **Tests:** none unless G3's resolution can empty a dimension.

## G5 — Where the proof escalates (honesty)

- **Evidence:** PROOF §7 trusted base; PO8/PO9.
- **Classification:** proof-capability / scope boundary (not a code bug).
- **Note:** the invariant proof is induction-free finite set algebra — well within
  the bundled tier, **no `[ESCALATION BOUNDARY]`** needed. The only *unproved*
  things are deliberately out of scope: the loop's *value* semantics (PO9) and
  machine-checking (`kprove` not run — PROOF §6). Neither weakens the INV result.

---

## One-line summary for the next generator

Keep the V2 line `coord_names = (self._coord_names - set(drop_variables)) |
set(new_variables)`; it preserves the Dataset class invariant `coord_names ⊆
variables` (proved, PO1) for all inputs, fixes the reported negative-`__len__`
crash (PO5/PO6), keeps `drop=False` behaviour identical (PO4), and — unlike the V1
ordering — keeps recreated coordinates as coordinates (PO2). Remaining open items
(G1 optional guard, G3 multi-key intent) are out of scope for #6992 and tracked
above.
