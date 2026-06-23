# django__django-11555

## Summary

**Severity:** Low — the baseline expression resolver assumes every non-`F` child
is a copyable expression tree, so it can `AttributeError` on the uncommon class
of ordering expressions whose source children are non-expression nodes (e.g. a
conditional `Q` inside `Case/When`); the trigger is a specialized expression
shape, so the practical blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The FVK arm added one guard to
`_resolve_ordering_expression()` — `if not hasattr(expr, 'get_source_expressions'): return expr`
— so the helper stops imposing the `copy()` / source-expression protocol on
child nodes that do not implement it. The defect is minor; the case shows FVK
located the residual robustness gap by formalizing the child-traversal contract
and auditing it, not by running a new test.

| Arm | `_resolve_ordering_expression()` on a non-expression child | Resolved |
|---|---|---|
| baseline | falls through to `expr.copy()` / `get_source_expressions()` on every non-`F` child | no |
| gold (human oracle) | (no gold artifact in this non-curated run; see §5) | — |
| **fvk** | guards non-source children and returns them unchanged | **yes** |

## 1. The issue and the real defect

The task is the standard `order_by()`-a-relation crash: when an `order_by()`
target is a parent or related model whose `Meta.ordering` contains an
expression item such as `OrderBy(F('name'))` or `Lower('name')`, the recursive
related-ordering expansion passes that expression to the string-only
`get_order_dir()` helper, which indexes `field[0]` and crashes because an
expression is not subscriptable
([`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/prompts/fvk.md#L2)).
This run is non-curated: there is no separate `problem_statement.md` and no
upstream issue URL in the prior report, so none is asserted here.

The root cause is recorded by baseline itself: the related-model expansion path
`assumed every` item in the related model's `Meta.ordering` was a string and
passed it to `get_order_dir()`, while the top-level `get_order_by()` path
already accepted expressions
([`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/baseline_notes.md#L6)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_baseline.patch)
fixed the reported crash correctly. It added an early expression branch to
`find_ordering_name()` and a private helper,
[`_resolve_ordering_expression()`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_baseline.patch#L37),
that resolves plain `F()` leaves against the related model's `opts` and alias —
the same `_setup_joins()` / `trim_joins()` route the string path uses
([`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/baseline_notes.md#L26)).
For everything that is not a plain `F`, the helper recurses by cloning the
expression and rewriting each source child:

```python
clone = expr.copy()
clone.set_source_expressions([
    self._resolve_ordering_expression(source, opts, alias)
    if source is not None else None
    for source in clone.get_source_expressions()
])
```
([`solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_baseline.patch#L46))

The choice is reasonable: for the reported `OrderBy(F(...))` and `Lower('name')`
shapes every child *is* a normal expression. But the recursion is unconditional.
It assumes every non-`F` source child implements `copy()` and
`get_source_expressions()`, which the expression protocol does not guarantee for
all valid trees — leaving the **non-source-child** obligation unmet.

## 3. How FVK formally captured the gap

FVK fixed the verified domain by intent before auditing the code. The boundary
item names exactly the child shapes the helper must tolerate:

> **I7.** *The verified domain is expression ordering trees ... whose expression
> children either support the normal `copy()` plus source-expression protocol or
> are non-expression child nodes intentionally delegated to their own resolver.*
> — [`fvk/INTENT_SPEC.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/INTENT_SPEC.md#L30)

The evidence ledger pins that intent to a concrete code fact found by source
audit — not by the reported test, which never exercises a non-expression child:

> **E9 (implementation fact):** *Some expression source children such as `Q` are
> not normal `BaseExpression` trees with `copy()` and `get_source_expressions()`*
> → *the helper must not blindly copy non-expression child nodes.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13)

Which discharges into a formal obligation distinct from the reported-crash
obligations:

> **PO6. Expression tree rewriting must not assume every child is a normal
> `BaseExpression`.** *Code point: V2 guard `if not hasattr(expr, 'get_source_expressions'): return expr`.
> Discharge condition: non-source child nodes are preserved instead of causing
> helper-level `AttributeError`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PROOF_OBLIGATIONS.md#L40)

The defect was located by reasoning: I7 generalizes "resolve the ordering tree"
into a contract over *every* child node, E9 records by audit that some valid
children break the copy/source protocol, and PO6 makes the missing guard an
explicit obligation the baseline recursion does not satisfy.

## 4. From formal output to the fix

The audit raised a finding against the baseline (V1) recursion:

> **F2: V1 Assumed Every Non-F Child Was a Copyable Expression Tree.** ...
> *`_resolve_ordering_expression()` fell through to `expr.copy()` and
> `expr.get_source_expressions()` for every non-plain-F source. A non-expression
> child does not necessarily provide those methods.* ... *Proof obligations: PO6.*
> — [`fvk/FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/FINDINGS.md#L20)

The iteration guidance turned the finding into the one instruction that
distinguishes V2 from V1:

> *Add: non-source child guard because F2 showed V1 assumed too much about every
> expression child.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/ITERATION_GUIDANCE.md#L15)

The decision log records the exact code change and its provenance:

> **4. Changed V1 to add the non-source child guard** ... *Change: added
> `if not hasattr(expr, 'get_source_expressions'): return expr`. ... Trace:
> `fvk/FINDINGS.md` F2 and PO6.*
> — [`reports/fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/fvk_notes.md#L34)

The causal chain is on the record:

```
INTENT I7  ->  E9 (code audit: some source children lack copy()/get_source_expressions())
           ->  PO6 (obligation: helper must not assume every child is a BaseExpression)
           ->  F2 (V1 audit: baseline recursion copies every non-F child unconditionally)
           ->  ITERATION_GUIDANCE / fvk_notes decision 4  ->  V2 guard
```

The resulting [FVK patch](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_fvk.patch)
inserts the guard immediately before the clone/recurse step:

```python
if not hasattr(expr, 'get_source_expressions'):
    return expr
clone = expr.copy()
```
([`solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_fvk.patch#L46))

The V1→V2 change was driven by the formal finding F2/PO6, **not** by a new
failing test — no execution environment existed in this run, and the run notes
say the proof is constructed rather than test-driven (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This is a non-curated
run with no analysis directory, no gold patch, and no harness proof reports, so
there is no RED/GREEN table to present and none is fabricated. The FVK task
itself forbade execution: "*No execution environment exists: do not attempt to
run tests, Python, or K framework tooling*"
([`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/prompts/fvk.md#L26)),
and the FVK notes confirm "*no tests, Python, `kompile`, or `kprove` were run*"
([`reports/fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/fvk_notes.md#L3)).

What was inspected for this report:

- The two patches, byte-diffed: they differ only by the FVK guard
  ([`solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_baseline.patch#L46),
  [`solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_fvk.patch#L46)).
- The FVK artifacts under
  [`fvk/`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/SPEC.md):
  intent spec, evidence ledger, proof obligations, findings, iteration guidance,
  the constructed proof sketch, the spec audit, the compatibility audit, and the
  two `.k` artifacts
  ([`mini-django-ordering.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/mini-django-ordering.k),
  [`django-ordering-spec.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/django-ordering-spec.k)).
- Both decision logs
  ([`baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/baseline_notes.md#L26),
  [`fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/fvk_notes.md#L34)).

**Gold comparison (no artifact).** No gold patch is available in this run, so no
RED/GREEN comparison against the human oracle is possible. Both arms were marked
resolved by the official evaluation, which means the gold-equivalent reported
behavior was fixed by baseline already; the FVK guard addresses a robustness
case (non-expression child nodes) that the reported test does not exercise, so
its value is not visible in the pass/fail verdict.

## 6. Boundaries & honesty

- **Severity: Low.** Per the rubric, the trigger is a specialized expression
  shape — an ordering expression whose source children include a non-expression
  node such as a conditional `Q` inside `Case/When`
  ([`fvk/FINDINGS.md` F2](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/FINDINGS.md#L20)).
  The reported `OrderBy(F(...))` / `Lower('name')` family has only normal
  expression children, so baseline never crashes on the issue's own inputs. The
  value here is the completeness audit of the child-traversal contract, not the
  impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts and the
  `kompile` / `kprove` commands were written but never run; the proof document
  states so on its first line
  ([`fvk/PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PROOF.md#L3))
  and emits the future-reproduction command
  ([`fvk/PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PROOF.md#L74)).
  The PO6 discharge is therefore proof-structured reasoning over a finite
  expression tree, not a machine-checked result.
- **Residual boundary.** Even after the V2 guard, conditional `Q` lookup strings
  inside `Case/When` are not proved alias-relative; FVK records this explicitly
  as out of the proven domain rather than claiming it
  ([`fvk/FINDINGS.md` F3](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/FINDINGS.md#L36)).
- **Attribution.** The residual defect and its fix are reconstructed from the
  patch diff plus the FVK artifacts, not from an executed reproduction; the guard
  prevents a helper-level `AttributeError` by construction, and no test in this
  run demonstrates the crash on the baseline tree.

## Artifact map

| Claim | Source |
|---|---|
| Reported crash / task framing | [`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/prompts/fvk.md#L2) |
| No-execution constraint | [`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/prompts/fvk.md#L26) |
| Root cause (string assumption) | [`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/baseline_notes.md#L6) |
| Baseline patch | [`solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_baseline.patch#L37) |
| Baseline helper reasoning | [`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/baseline_notes.md#L26) |
| Unconditional clone/recurse | [`solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_baseline.patch#L46) |
| FVK patch (guard) | [`solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/solutions/solution_fvk.patch#L46) |
| Intent I7 (verified domain) | [`fvk/INTENT_SPEC.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/INTENT_SPEC.md#L30) |
| Evidence E9 (non-expression children) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13) |
| Obligation PO6 | [`fvk/PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PROOF_OBLIGATIONS.md#L40) |
| Finding F2 (residual defect) | [`fvk/FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/FINDINGS.md#L20) |
| Residual boundary F3 (PO8) | [`fvk/FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/FINDINGS.md#L36) |
| Iteration instruction (add guard) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/ITERATION_GUIDANCE.md#L15) |
| Decision trace (V1→V2) | [`reports/fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/reports/fvk_notes.md#L34) |
| Proof status (not machine-checked) | [`fvk/PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PROOF.md#L3) |
| Future kprove command | [`fvk/PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PROOF.md#L74) |
| Constructed K core | [`fvk/mini-django-ordering.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/mini-django-ordering.k), [`fvk/django-ordering-spec.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/django-ordering-spec.k) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11555/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L29) |
