# django__django-13012

## Summary

**Severity:** Low — the baseline patch unconditionally forwards `alias=` from
`ExpressionWrapper.get_group_by_cols()` to the wrapped expression, which raises
`TypeError` for the deprecated-but-still-supported custom override whose
`get_group_by_cols(self)` lacks an `alias` parameter; the trigger is narrow
(legacy custom expressions on a transitional Django 3.2 path), so the blast
radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. FVK kept baseline's delegation fix but added a
signature guard so a wrapped legacy child stays on Django's existing
`RemovedInDjango40Warning` deprecation path instead of crashing. The defect is
minor; the case shows FVK locating the gap by **generalizing the issue into a
compatibility invariant and auditing the wrapper's dispatch against the public
deprecation API** — not by running a new test.

| Arm | `ExpressionWrapper(MissingAlias()).get_group_by_cols(alias=None)` | Resolved |
|---|---|---|
| baseline | forwards `alias=` → **TypeError** on legacy child | no |
| gold (human oracle) | (no curated gold file for this run) | — |
| **fvk** | signature-guarded → emits `RemovedInDjango40Warning`, no-arg call | **yes** |

## 1. The issue and the real defect

The reported issue: *"Constant expressions of an `ExpressionWrapper` object are
incorrectly placed at the `GROUP BY` clause"*
([`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/prompts/fvk.md#L2)).
`ExpressionWrapper` delegated SQL rendering to its child but **not** group-by
column resolution, so it inherited `BaseExpression.get_group_by_cols()`, which
returns `[self]` for a non-aggregate expression. Wrapping a constant `Value(...)`
therefore made Django group by the wrapper even though `Value.get_group_by_cols()`
correctly returns `[]`
([`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/reports/baseline_notes.md#L5)).

The user-facing observable that is wrong: a wrapped constant annotation emits an
extra, incorrect column in the generated SQL `GROUP BY`.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/solutions/solution_baseline.patch)
added the obvious delegating method:

```python
def get_group_by_cols(self, alias=None):
    return self.expression.get_group_by_cols(alias=alias)
```

This is correct for the reported bug and well-reasoned. The baseline notes show
the choice was deliberate: it treats grouping transparently, *"the same way it
already behaves for SQL rendering through `as_sql()`"*, and explicitly rejected
the broader alternatives of special-casing `Value` or changing
`BaseExpression`
([`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/reports/baseline_notes.md#L22)).

Where it stopped: the unconditional `alias=alias` forward assumes **every** child
accepts the `alias` keyword. Django 3.2 still supports custom expressions whose
`get_group_by_cols(self)` override predates `alias=None`, routing them through a
deprecation warning rather than a crash. Forwarding `alias=` to such a child
passes an unsupported keyword and raises `TypeError` — the one obligation
baseline left unmet.

## 3. How FVK formally captured the gap

FVK started from intent, not from the symptom. The decisive intent-spec item
lifts the issue into a compatibility invariant over the wrapped child's API:

> *"Django 3.2 publicly supports custom expressions whose `get_group_by_cols()`
> override lacks `alias=None` only through a deprecation warning. Wrapping such
> an expression must not convert that supported transitional path into a raw
> `TypeError`."*
> — [`fvk/SPEC.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/SPEC.md#L34)

The evidence ledger pins that intent to a concrete code fact found by source
audit — Django's own group-by path already gates the `alias` call on a signature
check — **not** to any reported test:

> **E-005:** *`Query` checks `inspect.signature(annotation.get_group_by_cols)`
> and warns if `alias` is missing before calling without the keyword* →
> *`alias=None` is a public transition point; missing-alias overrides are
> deprecated but still handled.*
> — [`fvk/SPEC.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/SPEC.md#L49)

That fact is discharged into a formal obligation the baseline patch violates:

> **PO-004 — Legacy missing-alias child overrides remain on the deprecation
> path.** *the wrapper emits `RemovedInDjango40Warning` using the existing
> message shape and calls the child method without `alias`; it does not raise
> `TypeError` solely because `alias` was forwarded.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF_OBLIGATIONS.md#L40)

This is the crux: the second defect was located by **reasoning**. The issue is
about constants in `GROUP BY`; FVK generalized it to "the wrapper must be
transparent for *every* child contract," and the audit of Django's existing
deprecation handling (E-005, mirroring `repo/tests/expressions/test_deprecation.py`
in E-006) revealed that the wrapper's blanket `alias=` forward breaks a child
contract Django still officially supports.

## 4. From formal output to the fix

The FVK arm keeps baseline's V1 delegation and adds one guarded branch. The
artifacts record the exact step where the audit changed the patch.

- The completeness audit against the spec raised the finding:

  > **F-002: V1 introduced a nested legacy-signature compatibility risk.** *V1
  > observed behavior by inspection: `ExpressionWrapper.get_group_by_cols()`
  > always called `self.expression.get_group_by_cols(alias=alias)`, which would
  > pass an unsupported keyword to a legacy child override.*
  > — [`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/FINDINGS.md#L19)

- The iteration guidance turned the finding into the next-revision instruction:

  > *"V1 fixed the reported constant-wrapper bug but was incomplete against the
  > full public compatibility intent. V2 keeps V1's delegation and adds the
  > missing signature compatibility guard."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code change and its provenance:

  > *"Improved V1 by preserving the missing-`alias` deprecation path … now
  > inspects `self.expression.get_group_by_cols`. If the child method lacks an
  > `alias` parameter, it emits `RemovedInDjango40Warning` and calls the child
  > method without the keyword. … V1 would have forwarded `alias` through the
  > wrapper and risked a `TypeError`."*
  > — [`reports/fvk_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/reports/fvk_notes.md#L12)

The causal chain is on the record:

```
SPEC §4 (intent: wrapping must not break the deprecation path)
  ->  E-005 (code audit: Query gates the alias call on inspect.signature)
  ->  F-002 (V1 audit: wrapper forwards alias unconditionally -> TypeError)
  ->  PO-004 (obligation: legacy child stays on RemovedInDjango40Warning)
  ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch (signature guard)
```

The resulting
[FVK patch](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/solutions/solution_fvk.patch)
guards the forward on the child's signature:

```python
def get_group_by_cols(self, alias=None):
    signature = inspect.signature(self.expression.get_group_by_cols)
    if 'alias' not in signature.parameters:
        expression_class = self.expression.__class__
        msg = (
            '`alias=None` must be added to the signature of '
            '%s.%s.get_group_by_cols().'
        ) % (expression_class.__module__, expression_class.__qualname__)
        warnings.warn(msg, category=RemovedInDjango40Warning)
        return self.expression.get_group_by_cols()
    return self.expression.get_group_by_cols(alias=alias)
```

The `V1 -> V2` transition was driven by **F-002 / PO-004**, the formal
completeness audit — **not** by a new failing test (the run forbade running or
modifying tests; see §5–§6).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This run is not curated and has
no harness proof reports, and the FVK environment explicitly forbade execution
([`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/prompts/fvk.md#L2),
[`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF.md#L3)).
What was inspected:

- The two patches were diffed: baseline forwards `alias=alias` unconditionally;
  FVK adds the `inspect.signature` guard plus the `warnings` /
  `RemovedInDjango40Warning` imports and the no-arg legacy branch
  ([`solution_baseline.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/solutions/solution_fvk.patch)).
- The obligation discharge in
  [`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF.md#L33),
  which walks the missing-alias branch step by step against PO-004.

Both arms were marked **resolved** by the official SWE-bench evaluation, but that
verdict is the benchmark's hidden-test pass, not a local demonstration of the
residual TypeError, which has no executed reproduction in this run.

**Gold comparison.** This run has no curated gold patch, so no byte-level gold
diff is available. By the FVK reasoning, the residual `TypeError` afflicts only
the deprecated missing-`alias` override contract; a child that already carries
`alias=None` (the common case, e.g. `Value`, `Subquery`) renders identically
under both patches.

## 6. Boundaries & honesty

- **Severity: Low.** Per the rubric the trigger is narrow: it requires a
  *custom* expression whose `get_group_by_cols(self)` override omits `alias=None`
  (a deprecated Django 3.2 transitional shape), *and* that expression to be
  wrapped in an `ExpressionWrapper` whose grouping is resolved with an alias.
  Mainstream expressions already carry `alias=None`, so the practical blast
  radius is small. The value here is **completeness against a public deprecation
  contract**, not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K core
  ([`mini-django-expressions.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/mini-django-expressions.k),
  [`expression-wrapper-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/expression-wrapper-spec.k))
  and the `kompile`/`kprove` commands were *written but never run* — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF.md#L3),
  finding [F-004](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/FINDINGS.md#L46)).
  We claim **proof-structured reasoning** (a formal spec with obligations
  discharged by construction), **not** a machine-checked proof.
- **Attribution.** The `V1 -> V2` step is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`, and the patches differ on the
  record, so the link from PO-004 to the signature guard is observed, not
  reconstructed. The residual `TypeError` itself is argued by source audit, not
  reproduced — there is no executed demonstration of the failing legacy case in
  this run.

## Artifact map

| Claim | Source |
|---|---|
| Issue text (constants in GROUP BY) | [`prompts/fvk.md#L2`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/prompts/fvk.md#L2) |
| Root cause (inherited `[self]`) | [`reports/baseline_notes.md#L5`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/reports/baseline_notes.md#L5) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md#L22`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/reports/baseline_notes.md#L22) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/solutions/solution_fvk.patch) |
| Intent §4 (deprecation invariant) | [`fvk/SPEC.md#L34`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/SPEC.md#L34) |
| Evidence E-005 (signature gate) | [`fvk/SPEC.md#L49`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/SPEC.md#L49) |
| Obligation PO-004 | [`fvk/PROOF_OBLIGATIONS.md#L40`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF_OBLIGATIONS.md#L40) |
| Finding F-002 | [`fvk/FINDINGS.md#L19`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/FINDINGS.md#L19) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L12`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/reports/fvk_notes.md#L12) |
| Honesty note F-004 | [`fvk/FINDINGS.md#L46`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/FINDINGS.md#L46) |
| Proof status / unrun kprove | [`fvk/PROOF.md#L3`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF.md#L3), [`fvk/PROOF.md#L33`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/PROOF.md#L33) |
| Constructed K core | [`fvk/mini-django-expressions.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/mini-django-expressions.k), [`fvk/expression-wrapper-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13012/fvk/expression-wrapper-spec.k) |
</content>
</invoke>
