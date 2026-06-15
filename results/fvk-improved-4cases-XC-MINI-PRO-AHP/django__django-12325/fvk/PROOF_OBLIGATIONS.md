# PROOF_OBLIGATIONS.md — parent-link selection (V1)

Each obligation traces to the intent ledger in [`SPEC.md`](SPEC.md) and is
discharged (or routed) in [`PROOF.md`](PROOF.md). `L` is the in-order list of
`parent_link` flags of the `OneToOneField`s targeting one parent model.

## Functional obligations

- **O1 — winner is the explicit parent link, order-independent.**
  *Source:* E1, E2, E7 (I1). *Statement:* if `containsTrue(L)` then the loop
  selects the field at `firstTrue(L)` (a `parent_link=True` field), and this
  result is invariant under any permutation of the **non-parent-link** fields and
  under moving the parent-link field to any position. *Discharge:* `(SELECT)`
  +  concretely `(CASE-A)` (=1) and `(CASE-B)` (=2). **MUST hold.**

- **O2 — lone / unmarked selection still errors (no silent auto-create).**
  *Source:* E6, E7, E8 (I2). *Statement:* for a non-empty `L` with
  `containsTrue(L) = false`, `selectResult(L) = lenB(L) ≥ 1 ≠ 0`, i.e. a field is
  still selected, so `Options._prepare()` raises `Add parent_link=True`.
  *Discharge:* `(CASE-LONE)` + the `selectResult` definition. **MUST hold.**
  *(This is the obligation that rejects the alternative "filter to parent_link
  only" patch — see F-ALT / O6.)*

- **O3 — empty ⇒ auto link.** *Source:* I3. *Statement:*
  `selectResult(.BList) = 0`, so the key is absent from `parent_links` and
  `base.py:250` auto-creates `…_ptr`. *Discharge:* `selectResult` base case.

- **O4 — legacy tie-break preserved for unmarked multiples.** *Source:* I4.
  *Statement:* if `containsTrue(L) = false`, `selectResult(L)` = the **last**
  field (original "last write wins"). *Discharge:* `(LOOP)` store branch with all
  flags false collapses to `lenB(L)`.

## Frame / preservation obligations

- **O5 — change confined to the ambiguous case.** *Source:* I4 (frame).
  *Statement:* `selectResult(L)` differs from the pre-V1 "last write wins" value
  **iff** `containsTrue(L)` and the last field is not the first parent link —
  exactly the multiple-reference ambiguity. All single-OTO and no-marker cases are
  byte-for-byte identical. *Discharge:* compare `selectResult` against
  `last(L)` (PROOF.md §5).

- **O5b — cross-base correctness.** *Source:* E9 (I1 across abstract bases).
  *Statement:* because processing order is
  `reversed([new_class] + parents) × local_fields`, a `parent_link` declared on
  an abstract base and a `parent_link`/plain field on the child both land in the
  same `L`; `firstTrue`/lock semantics still pick the marked field. In
  particular `test_abstract_parent_link` (abstract base owns the only marked
  field) ⇒ that field wins. *Discharge:* `(LOOP)` lock branch (PROOF.md §4,
  scenarios X/Y).

- **O5c — pk consistency.** *Source:* E4 (I5). *Statement:* the field returned by
  selection is stored in `_meta.parents[parent]` and promoted to the pk by
  `_prepare()`; selecting the `parent_link` field therefore makes the parent
  pointer == pk (resolves "…_ptr not populated"). *Discharge:* consumer trace
  (PROOF.md §6); no contradicting VC.

## Adequacy / audit obligations

- **O6 — reject the "filter to `parent_link` only" alternative (F-ALT).**
  *Source:* E3 vs E6 (SUSPECT-resolution duty). *Statement:* the named
  alternative `if isinstance(field, OneToOneField) and
  field.remote_field.parent_link` must be derived side-by-side and kept only if it
  satisfies all public obligations. It makes `selectResult'(L)=0` whenever
  `containsTrue(L)=false`, violating **O2/E6**. *Discharge:* two-column
  derivation, PROOF.md §7 — alternative **fails O2**, V1 kept.

- **O7 — no public-compatibility break.** *Source:* §5 SPEC. *Statement:* no
  changed public signature/return/dispatch; `_meta.parents` shape preserved.
  *Discharge:* `PUBLIC_COMPATIBILITY_AUDIT` (SPEC §5) — clean.

## Non-obligations (explicitly out of domain)

- **N1 — termination.** Partial correctness only. The loop visits a finite
  `local_fields` list; termination is obvious but **not** part of the proved
  contract unless requested.
- **N2 — two `parent_link=True` fields to the same parent.** Invalid input
  (user declared two parent links). `selectResult` returns the first; intent does
  not specify. Recorded as Finding F3, not an obligation.
