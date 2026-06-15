# FVK audit notes — django__django-12325

This records every decision from the FVK pass over the V1 fix, tracing each to
entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md). **Outcome: V1 stands
unchanged**, justified below.

## What V1 is (recap)

In `repo/django/db/models/base.py` (`ModelBase.__new__`), the `parent_links`
collection loop was changed so that a regular `OneToOneField` never overwrites
one already recorded with `parent_link=True`:

```python
existing = parent_links.get(related_key)
if existing is not None and existing.remote_field.parent_link:
    continue
parent_links[related_key] = field
```

Net selection rule, proved as `selectResult(L)` in
[`fvk/parent-links-spec.k`](../fvk/parent-links-spec.k): among the
`OneToOneField`s targeting a given parent, **the first `parent_link=True` one
wins; else the last field; else none.**

## Decision 1 — keep the fix in `base.py` (no code change)

*Traces to:* O1, O5, O5b ([`PROOF.md`](../fvk/PROOF.md) §3–§5); findings C1, C2.

The formalization shows V1 satisfies the core intent **I1** (E1/E2/E7):
`(CASE-A)` `[True,False] → 1` and `(CASE-B)` `[False,True] → 2` both select the
`parent_link=True` field, so the winner is **order-independent** — exactly the
reported bug, fixed in both declaration orders (FINDINGS C1). The change-confinement
proof (O5, PROOF §5) shows `selectResult` equals the original "last write wins"
on *every* input except the precise multiple-reference ambiguity, so nothing else
is perturbed (frame condition I4). The consumer trace (O5c, PROOF §6) shows the
selected `parent_link` field becomes the pk, resolving the thread's "model still
broken / `document_ptr_id` not populated" follow-up (FINDINGS C2). No obligation
is violated, so there is nothing to repair.

## Decision 2 — do **not** change the lone-unmarked-OTO behavior

*Traces to:* O2; finding F1; the SUSPECT-resolution duty in `intent-evidence.md` §1.

A thread comment (ledger **E5**) calls the lone-`OneToOneField` error "the same
bug," which made `test_missing_parent_link` (**E8**) a SUSPECT obligation — I was
not allowed to keep it merely because it exists. I therefore re-derived the lone
case from positive intent: the Django **docs** (**E6**: "implicit promotion of a
`OneToOneField` to a `parent_link` … deprecated … *Add `parent_link=True`*";
"removed" in 2.0; **E7**) and the live `options.py` error positively require that
an unmarked selected field raise `Add parent_link=True`. So the behavior is
documented intent, not legacy inertia, and V1 correctly preserves it (O2, finding
F1). Widening the fix to silence that case would contradict E6 and is a *separate*
deprecation decision (see ITERATION_GUIDANCE question 1), not part of fixing the
**multiple-reference** issue actually reported.

## Decision 3 — reject the "filter to `parent_link` only" alternative

*Traces to:* O6; finding F-ALT; [`PROOF.md`](../fvk/PROOF.md) §7.

The methodology forbids dropping a *named* change on scope grounds, so I promoted
the literal reading of hint **E3** (`isinstance(field, OneToOneField) and
field.remote_field.parent_link`) to a tested hypothesis and ran a two-column
derivation (PROOF §7). It agrees with V1 on the reported case (O1) but, on a lone
unmarked field, returns "no selection" → the `Add parent_link=True` error becomes
unreachable and a `…_ptr` column is injected silently → it **fails O2/E6** and
breaks `test_missing_parent_link`. Hence V1's *priority-not-filter* design is
forced, not merely preferred. (Note: during V1 development I had actually applied
this exact filter and reverted it; the FVK pass re-derives that reversal formally
rather than from memory.)

## Decision 4 — reject the community sort+first-wins PR and the within-base-sort

*Traces to:* O5b; finding F2; [`ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md).

The issue's community PR (sort `parent_link`-first + `if related_key not in
parent_links`) fixes the single-class case but, combined with the existing
`reversed([new_class] + parents)` iteration, becomes "first base wins," letting a
plain OTO on an abstract base shadow a child's `parent_link` (cross-base scenario
X). V1's "never overwrite a stored `parent_link`" guard instead makes the marked
field win regardless of which base owns it — both scenario X (child marked wins)
and scenario Y (abstract marked wins, = `test_abstract_parent_link`, E9) come out
right (O5b, PROOF §4). So V1 is strictly more correct than that PR; keeping V1 is
the right call, and a regenerator should not "simplify" toward the PR.

## Decision 5 — no public-compatibility action

*Traces to:* O7; SPEC §5 (`PUBLIC_COMPATIBILITY_AUDIT`).

V1 touches only the body of the private `parent_links` loop. No public signature,
return type, or virtual-dispatch call changes; `_meta.parents` keeps its
`{parent: field}` shape and every consumer reads a field object agnostic to which
OTO it is. Previously-working configs select an identical field; previously-erroring
multiple-reference configs now succeed (error→success, compatible). Audit clean —
nothing to adjust.

## Decision 6 — no test edits; redundancy recommendation deferred

*Traces to:* FINDINGS "Test-redundancy note"; the honesty gate in `verify.md`.

Tests are not modified (forbidden, and not warranted). The proof is *constructed,
not machine-checked*, so no removals are recommended; `test_missing_parent_link`
(O2) and `test_abstract_parent_link` (O5b) are explicitly **kept** as they pin the
boundaries this audit depends on, and they exercise real metaclass/`_prepare`
wiring the mini-python fragment abstracts away.

## Residual risk

Partial-correctness only (termination of the finite `local_fields` loop is not
part of the proved contract, N1); the trusted base is the per-key modelling
abstraction (SPEC §6), the coinduction metatheory + `kprove`, and the linear
arithmetic oracle; and the `.k` proof is constructed, not yet run (commands in
PROOF §8). None of these affect the Benefit-2 findings, which hold today.

## Bottom line

The FVK artifacts confirm V1 is correct and adequate against the **full** public
intent (issue + docs + API contract), and they actively falsify the two plausible
alternative patches. **V1 stands unchanged.**
