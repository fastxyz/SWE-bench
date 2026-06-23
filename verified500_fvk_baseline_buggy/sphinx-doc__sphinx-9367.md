# sphinx-doc__sphinx-9367

## Summary

**Severity:** Low — baseline silently renders one-element tuple subscript syntax
(`obj[1,]`) as a different operation, but only for that uncommon form, so the
practical blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for issue #9367,
with **different** patches. The FVK patch fixed a **second instance of the same
bug** in a sibling renderer (`visit_Subscript`) that the baseline patch, the
official gold patch, and even the real upstream Sphinx fix all left unrepaired.
The defect itself is minor; the case matters because FVK located it by
**formalizing the issue as an invariant and auditing every path that must satisfy
it** — not by running more tests.

| Arm | [`test_unparse_one_element_tuple_subscript`](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/test_fvk_regression.py) | Resolved |
|---|---|---|
| baseline | [**FAIL (RED)**](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/baseline.report.json) | no |
| gold (human oracle) | [**FAIL (RED)**](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/gold.report.json) | no |
| **fvk** | [**PASS (GREEN)**](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/fvk.report.json) | **yes** |

## 1. The issue and the real defect

**GitHub issue [sphinx-doc/sphinx#9367](https://github.com/sphinx-doc/sphinx/issues/9367)** —
*"1-element tuple rendered incorrectly":* `(1,)` is rendered as `(1)` but should
keep the trailing comma
([`problem_statement.md`](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/problem_statement.md#L7)).

`sphinx/pycode/ast._UnparseVisitor` turns a Python AST back into source text,
used by autodoc to render default arguments and annotations
(`sphinx/ext/autodoc/preserve_defaults.py` calls `unparse()`). The trailing comma
is load-bearing: `(1,)` is a **tuple**, `(1)` is the integer `1`. The original
`visit_Tuple()` dropped it:

```python
def visit_Tuple(self, node: ast.Tuple) -> str:
    if node.elts:
        return "(" + ", ".join(self.visit(e) for e in node.elts) + ")"
    else:
        return "()"
```

For a one-element tuple this **silently turns a tuple into a scalar** in rendered
output.

## 2. Baseline's fix — and where it stopped

[Baseline](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/baseline.patch)
added the obvious branch — correct for the reported case and **logically
identical to [gold](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/gold.patch)**:

```python
if len(node.elts) == 1:
    return "(%s,)" % self.visit(node.elts[0])
elif node.elts:
    ...
```

Baseline was not careless. Its notes show it *consciously considered* the
neighboring subscript renderer and chose to leave it alone:

> *"I considered changing subscript tuple handling in `visit_Subscript()`, but
> that code intentionally removes tuple parentheses for simple subscription lists
> such as `Tuple[int, int]`; changing it would affect a separate behavior and is
> not needed for the reported `(1,)` failure."*
> — [`reports/baseline_notes.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/reports/baseline_notes.md#L26)

That reasoning is **half right**: `visit_Subscript()` *should* strip the parens.
But it overlooked that the **comma**, not the parens, encodes tuple cardinality.
So baseline (and gold, and upstream) fixed exactly one of the two code paths that
feed `unparse()`.

## 3. How FVK formally captured the gap

FVK started from a spec, not from the symptom. The decisive intent item
generalizes the issue beyond the single reported method:

> **I-004:** *If `pycode.ast.unparse()` formats a tuple through an alternate local
> contributor, that contributor must preserve tuple cardinality as well. In
> particular, a one-element tuple slice in a subscript must retain a comma,
> because `obj[1,]` and `obj[1]` are different AST shapes.*
> — [`fvk/SPEC.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/SPEC.md#L33)

The evidence ledger pins that intent to a concrete code fact found by source
audit — **not** to the reported test:

> **E-005 (implementation):** *`visit_Subscript()` manually joins simple tuple
> slice elements instead of calling `visit_Tuple()`* → *sibling formatter must be
> audited for the same one-element cardinality defect.*
> — [`fvk/SPEC.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/SPEC.md#L48)

Which is discharged into a formal obligation:

> **PO-3 — One-element simple tuple slice in subscript.** The rendered subscript
> must include the tuple comma: `visit(value) + "[" + visit(E) + ",]"`. *The
> parentheses may be omitted … but the comma cannot, because it carries the tuple
> cardinality.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/PROOF_OBLIGATIONS.md#L34)

This is the crux of FVK's value: **the second bug was located by reasoning, not
observation.** The issue says "a one-element tuple needs its comma"; FVK lifts
that into an invariant over *every* contributor to the `unparse()` string, and
the code audit (E-005) shows `visit_Subscript()` is a second such contributor
that bypasses the fixed method.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** (first attempt) fixed `visit_Tuple()` only — identical to what baseline
  shipped.
- The completeness audit against the spec raised a finding:

  > **F-002: V1 left a sibling one-element tuple formatter incomplete.** … *For
  > one element it would render `obj[1]`, erasing the comma … Classification: code
  > bug found by FVK completeness audit. Proof obligations: PO-3, PO-4.*
  > — [`fvk/FINDINGS.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/FINDINGS.md#L23)

- The iteration guidance turned the finding into an instruction for the next
  revision:

  > *"Keep the V2 subscript helper fix. Finding F-002 and obligations PO-3/PO-4
  > show that V1 did not cover the separate simple tuple-slice formatter in
  > `visit_Subscript()`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/ITERATION_GUIDANCE.md#L10)

- The decision log records the resulting code change and its provenance:

  > **D-002: Add a V2 fix for one-element simple tuple slices in
  > `visit_Subscript()`.** *Trace: Finding F-002 … PO-3 requires preserving the
  > comma … The new `render_simple_tuple()` helper satisfies both.*
  > — [`reports/fvk_notes.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/reports/fvk_notes.md#L12)

The causal chain is fully on the record:

```
SPEC I-004  ->  E-005 (code audit: visit_Subscript bypasses visit_Tuple)
            ->  F-002 (V1 audit: sibling formatter still erases the comma)
            ->  PO-3  (obligation: subscript must keep the comma)
            ->  ITERATION_GUIDANCE / D-002  ->  V2 patch
```

The resulting [V2 patch](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/fvk.patch)
routes both the modern and legacy subscript branches through one helper:

```python
def render_simple_tuple(value: ast.Tuple) -> str:
    elts = ", ".join(self.visit(e) for e in value.elts)
    if len(value.elts) == 1:
        return elts + ","
    else:
        return elts
```

The `V1 -> V2` transition was driven by `F-002`/`PO-3`, **not** by a new failing
test — no test for `obj[1,]` exists anywhere in the suite (see §5).

## 5. Verification

**Harness (official SWE-bench Docker).** A regression test for the *subscript*
case was run against all three patched trees
([baseline](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/baseline.report.json) →
**RED**,
[gold](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/gold.report.json) →
**RED**,
[fvk](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/fvk.report.json) →
**GREEN**).

**Behavioral demonstration.** Input `obj[1,]` (slice is the 1-element tuple
`(1,)`):

| Variant | Output | Round-trips to same AST? |
|---|---|---|
| original / baseline / gold | `obj[1]` | **No** — bug survives |
| **fvk** | `obj[1,]` | **Yes** — faithful |

`p[1,]` calls `__getitem__((1,))` (tuple key); `p[1]` calls `__getitem__(1)`
(scalar key) — genuinely different operations, so this is a correctness defect,
not cosmetics. No regression: `is_simple_tuple` only fires on a `Tuple` slice
node, so `Tuple[int]` (a `Name` slice), `Tuple[int, int]`, and `obj[1, 2]` render
unchanged.

**FVK beat the human oracle.** Gold changed only `visit_Tuple`. Inspection of
Sphinx git history confirms even the real upstream fix (commit `b9158b96d`)
left `visit_Subscript` on the plain `", ".join(...)`. FVK's extra fix goes beyond
what the maintainers themselves shipped.

## 6. Boundaries & honesty

- **Severity: Low.** One-element tuple *subscripts* (`obj[1,]`) are uncommon in
  default arguments / annotations, so the practical blast radius is small. The
  value demonstrated here is **detection power and completeness**, not impact
  magnitude — sell the method, not the bug.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-pycode-unparse.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/mini-pycode-unparse.k),
  [`pycode-ast-tuple-spec.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/pycode-ast-tuple-spec.k))
  and the `kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/PROOF.md#L3),
  [finding F-004](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/FINDINGS.md#L63)).
  We therefore claim **proof-structured reasoning** (a formal spec with
  obligations discharged by construction), **not a machine-checked proof**. The
  bug-detection value does not depend on the unrun `kprove`; the fix's
  correctness is independently confirmed by the harness RED→GREEN above.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the full ordering can be
  timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`_materials/problem_statement.md`](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/problem_statement.md#L7) |
| Baseline patch | [`_materials/baseline.patch`](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/reports/baseline_notes.md#L26) |
| FVK patch | [`_materials/fvk.patch`](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/sphinx-doc__sphinx-9367/_materials/gold.patch) |
| Intent I-004 | [`fvk/SPEC.md#L33`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/SPEC.md#L33) |
| Evidence E-005 | [`fvk/SPEC.md#L48`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/SPEC.md#L48) |
| Obligation PO-3 | [`fvk/PROOF_OBLIGATIONS.md#L34`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/PROOF_OBLIGATIONS.md#L34) |
| Finding F-002 | [`fvk/FINDINGS.md#L23`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/FINDINGS.md#L23) |
| Honesty note F-004 | [`fvk/FINDINGS.md#L63`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/FINDINGS.md#L63) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L10`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/ITERATION_GUIDANCE.md#L10) |
| Decision trace D-002 | [`reports/fvk_notes.md#L12`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/reports/fvk_notes.md#L12) |
| Constructed K core | [`fvk/mini-pycode-unparse.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/mini-pycode-unparse.k), [`fvk/pycode-ast-tuple-spec.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/fvk/pycode-ast-tuple-spec.k) |
| Harness RED/GREEN verdicts | [`enhanced_tests/_proof/`](../verified500_analysis/sphinx-doc__sphinx-9367/enhanced_tests/_proof/) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9367/transcripts/fvk.jsonl.gz) |
