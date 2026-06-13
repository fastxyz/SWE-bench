# FVK notes — pytest-dev__pytest-10356

This explains, decision by decision, what the Formal Verification Kit audit concluded
about the V1 fix, and why **V1 stands unchanged**. Every decision is traced to a
specific entry in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## What was audited

The V1 fix (two changes in `repo/src/_pytest/mark/structures.py`):
1. `get_unpacked_marks` walks the full MRO for classes, reading each class's *own*
   `__dict__["pytestmark"]` over `reversed(obj.__mro__)`, and flattening.
2. `store_mark` calls `get_unpacked_marks(obj, consider_mro=False)` so it stores
   own-marks only.

I formalized the marker-collection algorithm in a mini-Python K fragment
([`fvk/SPEC.md`](../fvk/SPEC.md) §4–§5), stated four function contracts (C-CLASS-MRO,
C-CLASS-OWN, C-NONCLASS, C-STORE), and constructed the proof
([`fvk/PROOF.md`](../fvk/PROOF.md)). The proof is **constructed, not machine-checked**
(no execution environment; the `kompile`/`kprove` commands are written into SPEC §7 and
reasoned about, not run).

## Decision 1 — Keep `reversed(obj.__mro__)` (do not change the traversal)

- **Traces to:** PO3 **[forcing]**, FINDINGS F1, F2.
- **Reasoning:** PO3 requires the result order to equal the long-standing baseline order
  for single inheritance. The baseline trace (PROOF_OBLIGATIONS PO3) shows `B(A)` with
  `@a A`, `@b B` produced `[a, b]` (base-first). V1's `reversed([B, A, object]) =
  [object, A, B]` yields `own(A) ++ own(B) = [a, b]` — identical. A *forward* MRO walk
  would yield `[b, a]` and break compatibility. So the traversal direction is **forced**,
  and V1 picked the only compatible one. F2 records that the order question has a forced
  answer; F1 records that the traversal also fixes the reported multiple-inheritance bug
  (PO1). **No change.**

## Decision 2 — Keep `store_mark(..., consider_mro=False)` (do not revert to default)

- **Traces to:** PO4 **[forcing]**, PO2, FINDINGS F3, proof-derived PD1.
- **Reasoning:** PO4's forcing argument shows that if `store_mark` used the default
  `consider_mro=True`, then applying `@b` to `B(A)` would write
  `B.__dict__["pytestmark"] = [a, b]` (inherited `a` copied in), and the later MRO walk
  would compute `own(A) ++ own(B) = [a, a, b]` — a duplicate. The own-only write keeps
  each class's dict limited to its own marks, which is exactly the invariant PO2 (no
  diamond duplication) depends on. The two halves of the fix are **coupled**: reading the
  MRO is sound only because writes are own-only. V1 already does both. **No change.**

## Decision 3 — Keep reading `cls.__dict__` per class (do not use `getattr`)

- **Traces to:** PO2, FINDINGS F6.
- **Reasoning:** PO2 (no structural duplication) is discharged because (a) MRO-DISTINCT
  guarantees each class appears once in the MRO and (b) `__dict__.get` reads only that
  one class's own marks. Switching to `getattr(c, "pytestmark")` per MRO entry would
  re-resolve inheritance for each `c` and re-duplicate ancestor marks. The cost is F6: a
  metaclass that exposes `pytestmark` as a computed *property* is bypassed. I judged this
  an acceptable, documented limitation — the metaclass is itself a workaround for the bug
  being fixed, and supporting it would break PO2. **No change; documented in F6.**

## Decision 4 — Do not add name-based deduplication

- **Traces to:** PO2 (structural-only dedup), FINDINGS F4.
- **Reasoning:** The issue *floated* "deduplicating marker names by MRO," but pytest
  semantics (and the baseline) deliberately keep repeated marks — multiple `parametrize`,
  multiple `skipif`, etc. F4 shows `@x Foo`, `@x Bar`, `C(Foo, Bar)` yields `[x, x]`,
  matching baseline single-inheritance behavior. The implemented contract dedups
  *structurally* (each class visited once) but not by *name*. Adding name-dedup would be
  a semantic regression. **No change.**

## Decision 5 — Keep the `List[Mark]` return (the `list(...)` wrapper)

- **Traces to:** PO8, PO6, FINDINGS F9.
- **Reasoning:** PO8 shows all three call sites consume the result eagerly
  (`extend`/`[*...]`), so materializing a list breaks nothing and the annotation is more
  precise than the old `Iterable[Mark]`. F9 notes the only observable delta — `TypeError`
  is raised eagerly rather than lazily — which is unobservable given eager consumers and
  is arguably an improvement (fail-fast). **No change.**

## Decision 6 — Keep `store_mark`'s non-class path on the `else` branch

- **Traces to:** PO5, FINDINGS F8.
- **Reasoning:** `consider_mro` only affects the `isinstance(obj, type)` branch; for
  functions/modules the `else` branch runs and equals the baseline algorithm verbatim
  (PO5). F8 notes instances are never passed by pytest, so the unreachable
  instance-path is not a concern. Module- and function-level markers are therefore
  provably unaffected. **No change.**

## Intent questions surfaced (left to the user/maintainers, V1 chose issue-consistent answers)

- **F5 / PD3** — subclass body `pytestmark = [...]` now *merges* with inherited marks
  instead of *overriding* them. This is the maintainer-confirmed "marks transfer with the
  MRO" intent. Flagged for documentation, not changed.
- **F6 / PD4** — computed `pytestmark` properties are not supported (stored marks only).
- **F2 / PD2** — multi-base order is base-first (`C(A,B)` → `[b, a, c]`); the only order
  compatible with single inheritance.

None of these is a code defect; each is an intent clarification recorded in
[`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md).

## Bottom line

The audit produced a clean specification with a single side-condition-free loop
circularity and only associativity-with-unit VCs (no nonlinear arithmetic) — a strong
"low bug-likelihood" signal (FINDINGS *Spec-difficulty* section). All eight proof
obligations are discharged (constructed). The two choices that could have been wrong are
*forced* by PO3 and PO4, and V1 makes both. Therefore **V1 is confirmed and left
unchanged**; the only follow-ups are documentation/intent confirmations and
recommendation-only regression tests, none of which alters `repo/` source.
