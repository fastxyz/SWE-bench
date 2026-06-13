# ITERATION_GUIDANCE.md — django-15128

Next-iteration feedback distilled from the audit. The kit's default is to **stop
with the evidence package**, not to silently re-patch; the one code decision this
pass makes (keep V1) is justified below and in `reports/fvk_notes.md`.

---

## 1. Verdict for this iteration

**Confirm V1.** The constructed proof discharges the top-level goal G
(no `change_aliases` assert can fire from a `combine`-built map) for the reachable
branch, and the audit found **no new code bug**. The two design-critical
subtleties (base-table exclusion F3; `table_map` list copy F6) are already correct
in V1. No source edit is made in this pass.

## 2. Proof-derived findings → actions (the `/verify` critic loop)

For each obstacle the proof surfaced: evidence, classification, the
intent-elicitation question it implies, and the recommended change (here, mostly
"none — already handled").

### IG1 — disjointness must be *established*, not asserted blindly
- **Evidence:** `change_aliases`'s `assert` (PO-DISJOINT); the original
  `{T4:T5,T5:T6}` failure (F1).
- **Classification:** code bug (in V0), fixed in V1.
- **UltimatePowers question:** "When two querysets are OR/AND-combined, must the
  result be deterministic and order-independent in its aliases?" → Yes; the fix
  makes the relabelling well-defined.
- **Recommended change:** none — V1's prefix bump establishes the invariant.

### IG2 — the base alias must survive the bump
- **Evidence:** PO-KEYS / SC3; F3. `combine` skips `rhs.alias_map[0]` and never
  remaps rhs's base.
- **Classification:** needed code guard (the `exclude={rhs.base_table}`).
- **UltimatePowers question:** "Is the base table guaranteed identical on both
  sides of a combine?" → Yes (same model). The `exclude` encodes it.
- **Recommended change:** none — already present and necessary.

### IG3 — clone must not share mutable `table_map` lists
- **Evidence:** PO-NOMUT / F6; `Query.clone()` shallow-copies `table_map`;
  `change_aliases` mutates list values in place.
- **Classification:** code bug avoided (would corrupt the caller's `rhs`).
- **UltimatePowers question:** "Is `combine` contractually forbidden from
  mutating `rhs`?" → Yes (docstring). The list copy enforces it.
- **Recommended change:** none — already present. *Defense-in-depth option (not
  applied):* make `change_aliases` rebuild the `table_map` list instead of
  mutating in place, which would neutralize this shared-list hazard for *all*
  clone-then-`change_aliases` call sites (e.g. `relabeled_clone`), not just
  combine. Deferred: it touches a hot, widely-used method; V1's localized copy is
  sufficient for this ticket. Flag for a future hardening pass.

### IG4 — name-vs-name collision (resolved, no action)
- **Evidence:** F4 / PO-KEYS. Proven impossible because the bump leaves rhs with
  no `name(_)` keys.
- **Classification:** corner case, closed by the proof.
- **Recommended change:** none.

### IG5 — unconditional clone (perf only)
- **Evidence:** F9. Clones even when `rhs_tables` is empty.
- **Classification:** performance gap (not correctness).
- **UltimatePowers question:** "Is `|`/`&` on the hot path for this codebase?" If
  ever yes → add `and len(rhs.alias_map) > 1` to the guard (provably output-
  preserving: empty `rhs_tables` ⇒ empty change_map ⇒ nothing to relabel).
- **Recommended change:** optional micro-opt; **declined** for minimality. Safe to
  apply later.

### IG6 — pre-existing `'Z'` prefix wraparound (out of scope)
- **Evidence:** F10. `chr(ord('Z')+1)` → `alphabet.index('[')` `ValueError`.
- **Classification:** pre-existing capability gap, untouched by V1 (which does not
  accumulate prefixes across combines).
- **Recommended change:** none here; separate ticket if ever hit.

## 3. Test-redundancy report (Benefit 1) — recommendation only

**Honesty gate:** the proof is *constructed, not machine-checked*. Do **not**
remove any test until `kprove combine-aliasing-spec.k` returns `#Top`. The
project test suite is also fixed/hidden in this task, so this section is advisory
and changes nothing.

Once machine-checked, tests whose assertion is *entailed by G within the verified
domain* become redundant:

- **Subsumed (after machine-check):** a unit test asserting that one specific
  `qs1 | qs2` (same model, sharing prefix `'T'`, with the colliding-alias shape of
  F1) *does not raise* and returns the union — G proves no in-domain combine
  asserts, so any single such point is covered. Likewise a point test that
  `qs1 | qs2` and `qs2 | qs1` yield equal rows (PO-EQUIV makes the alias scheme
  equivalent).
- **KEEP — always:**
  - **rhs-not-mutated** tests (PO-NOMUT is a side proof, exactly the kind of
    contract worth pinning with a real assertion — and the F6 corruption is its
    failure mode).
  - **Out-of-domain / different-model / sliced / distinct-mismatch** tests (the
    four `TypeError` guards — outside the verified domain).
  - **Termination / performance** tests (partial correctness only).
  - **Integration / end-to-end** ORM tests exercising real SQL generation and DB
    round-trips (the proof covers the alias bookkeeping unit, not the wiring).
  - Any test for the pre-existing `'Z'`-wraparound or deep-subquery recursion
    limits (F10) — out of scope of this proof.

**Estimated CI saving:** negligible and not worth acting on — this is a
correctness fix, and the high-value tests (no-raise regression, rhs-immutability,
equivalence, integration) are all in the KEEP set. Recommendation: **keep all
tests**; rely on the proof as additional assurance, not as a license to delete.

## 4. If a future pass wants to *strengthen* the fix

Ranked, all optional:
1. **`change_aliases` list rebuild (IG3)** — turns the localized `table_map` copy
   into a global hardening; highest value, low risk, but out of this ticket's
   minimal scope.
2. **Guard the clone (IG5)** — perf only.
3. **`bump_prefix` `'Z'` wraparound (IG6)** — separate pre-existing bug.

None are required for django-15128; G holds with V1 as written.
