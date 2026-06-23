# django__django-13028

## Summary

**Severity:** Low — baseline narrows the `filterable` rejection to expression
objects, but its inline guard still lets a non-expression RHS be walked as an
expression container through the unrelated `get_source_expressions()` method, so
the residual defect needs a contrived object shape and the blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches: baseline gates the `filterable` read with an inline
`hasattr(...) and not getattr(...)`, while the FVK arm adds an **early return**
for any value lacking `resolve_expression`. The FVK return fires *before* any
expression-only metadata or method is inspected, closing the
`get_source_expressions()` traversal boundary that the baseline guard left open.
FVK located that boundary by **formalizing the expression-protocol entry
predicate and auditing every metadata access gated by it** — not by running a
test (none exists; no execution environment was available).

| Arm | Non-expression RHS with `filterable=False` and an unrelated `get_source_expressions` | Resolved |
|---|---|---|
| baseline | guard skips `filterable`, but source walk still reachable | partial |
| gold (human oracle) | early return before any expression metadata | yes |
| **fvk** | [early return before any expression metadata](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_fvk.patch#L9) | **yes** |

## 1. The issue and the real defect

The reported issue: a queryset raises `NotSupportedError` when the right-hand
side of a lookup has a `filterable=False` attribute. The reproducer filters a
foreign key against a related model instance —
`ProductMetaData.objects.filter(..., metadata_type=self.brand_metadata)` —
and Django answers `ProductMetaDataType is disallowed in the filter clause`
([`fvk/SPEC.md` E-01/E-02](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L39),
restated from the benchmark's `PROBLEM.md`, which is not shipped in the run
artifacts; see the task framing in
[`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/prompts/fvk.md#L12)).

`Query.check_filterable()` in `django/db/models/sql/query.py` is meant to reject
ORM **expressions** that set `filterable = False` (such as `Window`) from a
`WHERE` clause. The original body read the `filterable` attribute of *every*
value passed to it:

```python
def check_filterable(self, expression):
    """Raise an error if expression cannot be used in a WHERE clause."""
    if not getattr(expression, 'filterable', True):
        raise NotSupportedError(...)
```

Because an ordinary model instance used as lookup data can also carry an
application field named `filterable`, a `False` value there
**silently collides with Django's internal expression flag** and rejects valid
lookup data
([`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/reports/baseline_notes.md#L5)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_baseline.patch#L9)
narrowed the `filterable` guard so it only fires on objects that expose
`resolve_expression`, the ORM's expression-protocol discriminator:

```python
if (
    hasattr(expression, 'resolve_expression') and
    not getattr(expression, 'filterable', True)
):
    raise NotSupportedError(...)
```

Baseline was not careless. Its notes show it deliberately rejected the looser
alternatives — renaming user fields, or dropping the `filterable` check entirely
— and reasoned that `resolve_expression` is the right discriminator because the
surrounding query code already uses it
([`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/reports/baseline_notes.md#L32)).
That fixes the reported collision.

But the guard only protects the **`filterable` read**. The body of
`check_filterable()` continues past that branch into a recursive walk over
`expression.get_source_expressions()`. Baseline left that walk ungated: a
non-expression RHS that happens to define an unrelated method named
`get_source_expressions` would still be traversed as an expression container.
The unmet obligation is *"a value that is not an expression must not be inspected
for **any** expression-only metadata or method"*, not just the `filterable`
flag.

## 3. How FVK formally captured the gap

FVK started from intent, not the symptom. The decisive intent item generalizes
the issue to *all* expression-only metadata, not the single reported attribute:

> **I-01.** *An ordinary RHS lookup value must not be rejected merely because it
> has an application attribute or model field named `filterable` with value
> `False`.*
> — [`fvk/SPEC.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L24)

The evidence ledger pins that intent to a concrete code fact found by **source
audit** — the ORM's own convention for distinguishing expressions from data —
not to the reported traceback:

> **E-05.** *`resolve_lookup_value()` and other ORM paths use
> `hasattr(value, 'resolve_expression')` to decide expression participation.*
> Obligation: *non-expression RHS values should not be walked as expression
> containers.*
> — [`fvk/SPEC.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L67)

That fact is discharged into a formal obligation strong enough to cover the
source walk, not only the flag:

> **PO-01.** *for every value `v`, if `hasattr(v, 'resolve_expression')` is
> false, then `check_filterable(v)` returns without raising `NotSupportedError`
> **and without inspecting `v.filterable` or `v.get_source_expressions()`**.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/PROOF_OBLIGATIONS.md#L6)

This is the crux: PO-01 names `get_source_expressions()` explicitly. The
expression-protocol entry predicate (`HAS_RESOLVE`) is lifted into a claim over
the whole method body —
[`NON-EXPRESSION-RHS`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L91):
*"for every object with `HAS_RESOLVE == false`, `checkFilterable()` returns `ok`,
regardless of `FILTERABLE`, `HAS_SOURCES`, or `SOURCES`."* Baseline's inline
guard satisfies the `FILTERABLE` half of that claim but not the `SOURCES` half;
the gap was located by reasoning over the predicate, not by observing a failure.

## 4. From formal output to the fix

The FVK audit treats the baseline patch as **V1** and records the exact finding
where the formalism diverged from it:

- **F-01** documents the original collision that V1 already fixes — ordinary RHS
  instances with `filterable=False` and no `resolve_expression`
  ([`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L6)).
- The completeness audit against PO-01 raised the residual finding:

  > **F-02: V1 still partially treated non-expressions as expression
  > containers.** *the `filterable` flag was gated by `resolve_expression`, but
  > the recursive `get_source_expressions()` walk could still run on that
  > non-expression value … Non-expression RHS values should return from
  > `check_filterable()` before any expression-only metadata or methods are
  > inspected.*
  > — [`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L27)

- The iteration guidance turned F-02 / PO-01 into the concrete code change:

  > *"V1 was directionally correct but incomplete at the expression-protocol
  > boundary identified by F-02. V2 refines the fix by returning immediately from
  > `check_filterable()` for any object that lacks `resolve_expression`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the change and traces it to F-01, F-02, and PO-01:

  > *"The new first branch in `check_filterable()` is `if not hasattr(expression,
  > 'resolve_expression'): return`."* … *"PO-01 requires non-expression RHS
  > values to return before inspecting either `filterable` or source-expression
  > metadata."*
  > — [`reports/fvk_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/reports/fvk_notes.md#L13)

The causal chain is fully on the record:

```
SPEC I-01  ->  E-05 (code audit: ORM uses hasattr(resolve_expression) as the predicate)
           ->  PO-01 (obligation: non-expression RHS skips filterable AND get_source_expressions)
           ->  F-02  (V1 audit: source walk still reachable on a non-expression)
           ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 early-return patch
```

The resulting
[V2 patch](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_fvk.patch#L9)
replaces baseline's compound guard with a single early return at the top of the
method:

```python
if not hasattr(expression, 'resolve_expression'):
    return
if not getattr(expression, 'filterable', True):
    raise NotSupportedError(...)
```

The `V1 -> V2` transition was driven by **F-02 / PO-01**, not by a new failing
test — no test for this boundary exists, and the run had no execution
environment
([`fvk/FINDINGS.md` F-05](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L87)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This case is not on the harness
and there is no executed demonstration. The benchmark explicitly forbade running
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/prompts/fvk.md#L26)),
so verification rests on inspection of:

- the two patches —
  [baseline](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_baseline.patch#L9)
  (compound `hasattr ... and not getattr` guard) vs
  [fvk](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_fvk.patch#L9)
  (early return before the `filterable` read) — confirmed to differ exactly at
  the `get_source_expressions()` boundary described in F-02;
- the constructed proof
  ([`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/PROOF.md#L26)),
  whose `NON-EXPRESSION-RHS` claim shows the early return returns before both the
  `filterable` guard and the source walk;
- the preservation findings F-03/F-04
  ([`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L49)),
  which confirm by source inspection that real non-filterable expressions
  (e.g. `Window`) are still rejected and that recursive source validation is
  unchanged for genuine expressions.

**FVK vs the human oracle.** The early-return form is the same shape the Django
maintainers ultimately adopted upstream; baseline's compound guard is the
correct-but-narrower variant. No gold patch is archived for this non-curated
case, so this comparison is by code shape, not by a linked file.

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect requires an unusual object shape: a
  lookup RHS that simultaneously lacks `resolve_expression`, carries
  `filterable=False`, *and* defines an unrelated method named
  `get_source_expressions`. That trigger is narrow, so the practical blast radius
  is small and the value demonstrated is **detection completeness** at the
  protocol boundary, not impact magnitude
  ([`fvk/FINDINGS.md` F-02](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L27)).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-query.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/mini-django-query.k),
  [`query-filterable-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/query-filterable-spec.k))
  and the `kompile`/`kprove` commands were **written but never run** — the FVK
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/PROOF.md#L3),
  [F-05](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L87)).
  We therefore claim **proof-structured reasoning**, not a machine-checked proof.
  The proof is a partial-correctness argument over a small abstract model and
  does not cover SQL generation or database behavior
  ([`fvk/PROOF.md` Residual Risk](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/PROOF.md#L99)).
- **Attribution.** Because no test executes this path, the claim that the
  baseline source walk is reachable is an inference from reading the unchanged
  method body, not an observed failure — F-02 is classified as a *proof-derived
  code improvement*, not a reproduced crash
  ([`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L27)).
  Both arms pass the official evaluation, so the residual defect was not caught
  by the harness; the `V1 -> V2` ordering can be reconstructed from
  [`transcripts/fvk.jsonl.gz`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`fvk/SPEC.md` E-01/E-02](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L39) |
| Problem framing (PROBLEM.md not shipped) | [`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/prompts/fvk.md#L12) |
| Root cause | [`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/reports/baseline_notes.md#L5) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_baseline.patch#L9) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/reports/baseline_notes.md#L32) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/solutions/solution_fvk.patch#L9) |
| Intent I-01 | [`fvk/SPEC.md#L24`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L24) |
| Evidence E-05 | [`fvk/SPEC.md#L67`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L67) |
| Obligation PO-01 | [`fvk/PROOF_OBLIGATIONS.md#L6`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/PROOF_OBLIGATIONS.md#L6) |
| Claim NON-EXPRESSION-RHS | [`fvk/SPEC.md#L91`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/SPEC.md#L91) |
| Finding F-01 | [`fvk/FINDINGS.md#L6`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L6) |
| Finding F-02 (residual) | [`fvk/FINDINGS.md#L27`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L27) |
| Preservation F-03/F-04 | [`fvk/FINDINGS.md#L49`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L49) |
| Honesty note F-05 | [`fvk/FINDINGS.md#L87`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/FINDINGS.md#L87) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L13`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/reports/fvk_notes.md#L13) |
| Constructed proof | [`fvk/PROOF.md#L26`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/PROOF.md#L26) |
| Constructed K core | [`fvk/mini-django-query.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/mini-django-query.k), [`fvk/query-filterable-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/fvk/query-filterable-spec.k) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13028/transcripts/fvk.jsonl.gz) |
