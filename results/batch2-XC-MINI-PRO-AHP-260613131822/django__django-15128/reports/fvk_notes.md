# reports/fvk_notes.md — FVK audit decisions for django-15128

This explains every decision taken in the FVK pass — each kept line of V1 and
each declined change — by tracing it to entries in
[`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## Outcome in one line

**V1 stands, unchanged.** The constructed proof discharges the top-level goal
(`combine` never builds an intersecting `change_map`, so no `change_aliases`
assert can fire) and the audit found no new bug. Two design-critical subtleties
the spec forced out are already handled correctly in V1.

---

## 1. What I formalized

The fix's behaviour is a property of the `change_map` that `Query.combine` builds
(`fvk/combine-aliasing.k` models that loop). The contract (`fvk/SPEC.md`):

> after the loop, `set(change_map).isdisjoint(change_map.values())` — exactly the
> precondition `Query.change_aliases` asserts (PO-DISJOINT).

The proof (`fvk/PROOF.md`) reduces this to a **loop circularity** preserving the
invariant *keys are `pref(Pr,_)`, values are `pref(Ps,_)`/`name(_)`, `Pr ≠ Ps`*,
closed by the **core structural lemma** (PO-LEMMA): different prefix or different
constructor ⇒ no key equals any value.

## 2. Decisions on the V1 code (all: keep)

### 2a. `combine`: clone rhs + copy `table_map` lists + bump with `exclude`
**Kept verbatim.** Justification chain:
- The **prefix bump** is what establishes PO-PREFIX (`Pr ≠ Ps`, SC1) and PO-KEYS
  (every key becomes `pref(Pr,_)`, SC2). Together with PO-VALS these are the three
  preconditions the proof needs (`fvk/PROOF.md` §5). Removing the bump reinstates
  F1 (the `{T4:T5,T5:T6}` AssertionError).
- **`exclude={rhs.base_table}`** is required by PO-KEYS/SC3 and F3: the merge
  skips rhs's base (`rhs_tables = list(rhs.alias_map)[1:]`) and relies on rhs's
  base alias equalling self's. Relabelling the base (what a bare `bump_prefix`
  does) would break that. The audit confirms excluding it is *necessary*, not
  cosmetic.
- **`rhs = rhs.clone()` + the `table_map` list copy** discharge PO-NOMUT (F6):
  `clone()` shallow-copies `table_map`, whose list values `change_aliases` mutates
  in place, so without the copy the bump would corrupt the caller's `qs2`. I
  re-verified F6 by enumerating *every* structure `change_aliases` writes
  (PROOF_OBLIGATIONS PO-NOMUT): `table_map`'s lists are the **only** shared-mutable
  one, and the copy isolates exactly it.
- **Output unchanged** (PO-EQUIV): I checked that the bump preserves the relative
  order of `rhs_tables` — the bump's `change_map` is built in `alias_map` order and
  `change_aliases` re-adds relabelled aliases in that order with the base kept
  first — and that `self.join`'s reuse/mint decisions depend only on join
  *structure* (which the bump preserves), not on alias *names*. So the combined
  query is byte-for-byte the one the pre-bug code intended; existing
  (non-crashing) combine behaviour is not perturbed.

### 2b. `bump_prefix(other_query, exclude=None)`: the new parameter
**Kept.** PO-KEYS needs `bump_prefix` to relabel *all* non-base aliases (including
first-occurrence table names) so there are no `name(_)` keys — this is the same
relabelling the method already did, now made selective via `exclude`. PO-BACKCOMPAT
(F7) shows `exclude=None ⇒ {}` reproduces the old behaviour exactly for the two
existing positional callers (`resolve_expression`, `split_exclude`); the
`outer_query→other_query` rename is keyword-safe (no `outer_query=` caller exists).

### 2c. `change_aliases`: the assertion comment
**Kept.** F2 / PO-DISJOINT: the disjointness `assert` is a *real, previously
undocumented precondition* (sequential rename would otherwise relabel an alias
twice). The reporter asked for the comment; V1 adds it and — crucially — makes
`combine` *establish* the precondition rather than leave it to chance. The
assertion itself is correctly retained as the invariant guard.

## 3. Changes considered and **declined** (with justification)

### 3a. Guard the clone with `len(rhs.alias_map) > 1` — declined
**Trace:** F9 `[PERF]`, IG5. The unconditional clone wastes work when rhs has no
joins, but this is a *performance* observation, not a correctness defect (partial
correctness says nothing about cost), and PO-EQUIV shows the output is identical
either way. Declined for minimality/clarity; the cost is comparable to the
`_chain()` that `QuerySet.__or__` already performs, and `combine` is not a hot
loop. Recorded as safe-to-apply-later.

### 3b. Make `change_aliases` rebuild the `table_map` list instead of mutating it
in place — declined
**Trace:** F6, IG3. This would neutralize the shared-list hazard for *all*
clone-then-`change_aliases` sites (e.g. `relabeled_clone`), a genuine hardening.
But it touches a hot, widely-used method (broader blast radius) and is **not
needed** for this ticket: V1's localized `table_map` copy already discharges
PO-NOMUT for the only new call path the fix introduces. Per the minimal-change
mandate, deferred to a future hardening pass and flagged in ITERATION_GUIDANCE §4.

### 3c. Handle the no-bump branch / name-vs-name collision — declined (no-op)
**Trace:** F4 `[CORNER]`, PO-KEYS. The audit *proved* this collision impossible:
after the bump rhs has no `name(_)` keys, and the no-bump branch is reached only
by an already-bumped (hence fully-prefixed) rhs — and is in practice unreachable
for top-level `combine` (operands always carry the default prefix `'T'`). No code
change is warranted; documented so the reasoning is on record.

### 3d. Soften / remove the `change_aliases` assertion — declined
**Trace:** F2, PO-DISJOINT. The assertion encodes a true precondition; the correct
fix is to *satisfy* it (which V1 does), not to weaken it. Weakening would mask
future regressions of the same class.

## 4. Items explicitly out of scope (no action)

- **A1** (PO-A1, F5): table names never look like generated aliases — a standing
  Django invariant the fix neither relies on (PO-LEMMA is constructor-based) nor
  changes.
- **`'Z'` prefix wraparound** (F10, IG6): pre-existing `bump_prefix` limitation;
  V1 does not worsen it (it bumps a fresh rhs clone one level and never
  accumulates prefixes on `self`).
- **Empty / single-alias rhs** (F8): handled gracefully (empty `change_map`).

## 5. Honesty / residual risk

The K proof is **constructed, not machine-checked** (FVK MVP; no `kprove` run).
The Map-fold induction that lifts the per-step invariant to the whole `change_map`
is stated as an explicit `[ESCALATION BOUNDARY]` (PROOF §6), not faked as
`[trusted]`; the decisive per-step / per-pair content is fully given and is the
entire mathematical substance. Test-redundancy is recommendation-only and
conditioned on a future `kprove #Top`; the practical recommendation is to **keep
all tests** (the high-value ones — no-raise regression, rhs-immutability,
equivalence, integration — are all out of the subsumed set). No test files were
touched.
