# sphinx-doc__sphinx-9602

## Summary

**Severity:** Medium — valid `Literal[...]` annotations whose values are signed
numbers (`Literal[-1]`) or non-parseable representations (`Literal[<Color.RED: 1>]`)
still emit a spurious missing-reference warning; the trigger is narrow (those two
value shapes inside `Literal`) but the symptom is a wrong, user-visible nitpick
warning on otherwise-correct documentation.

Baseline and FVK both passed the official SWE-bench evaluation for issue #9602
with **different** patches: both make `Literal[True]`-style values render as text
instead of class references, and both pass the same hidden test
`test_parse_annotation_Literal`. The FVK patch additionally closes two residual
holes baseline's literal-value handling left open — `ast.UnaryOp` (signed numeric
literals) and a constrained `SyntaxError` fallback for whole `Literal[...]`
strings. FVK located both by **lifting the issue into a literal-value grammar
obligation and auditing each value shape against it**, not by running more tests
(none were run).

| Arm | official `test_parse_annotation_Literal` | signed / fallback literal values | Resolved |
|---|---|---|---|
| baseline | [**PASS**](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/eval/baseline.report.json) | unhandled — falls back to a whole-annotation xref | no |
| gold (human oracle) | PASS | not covered by the official test | — |
| **fvk** | [**PASS**](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/eval/fvk.report.json) | `ast.UnaryOp` + constrained fallback | **yes** |

## 1. The issue and the real defect

Issue #9602 — *a value present in a type annotation as `Literal` is treated as a
`py:class`*: with nitpick enabled, `typing.Literal[True]` makes Sphinx emit a
missing-reference warning for `True`, because `True` is rendered as a class
cross-reference rather than a literal value
([`prompts/fvk.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/prompts/fvk.md#L12)).

`sphinx.domains.python._parse_annotation()` flattens an annotation into text and
punctuation nodes, then turns **every** non-empty text node into a Python-domain
cross-reference
([`reports/baseline_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/baseline_notes.md#L7)).
Inside `Literal[...]`, the bracketed arguments are data values, not type names, so
that blanket conversion produces a `pending_xref` for `True` and, with nitpick on,
a missing-reference warning on otherwise-valid documentation. The trailing user-
facing observable is a wrong warning, not a crash.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/solutions/solution_baseline.patch)
added recognition for `Literal`, `typing.Literal`, and `typing_extensions.Literal`,
then suppressed xref conversion while walking the bracketed literal-value region and
used `repr()` for constants inside it — correct for the reported `Literal[True]`
case and enough to pass the hidden test. Its notes show the reasoning was deliberate,
explicitly enumerating which value kinds it treated as text:

> *"I treated string, numeric, boolean, `None`, ellipsis, and dotted literal values
> inside `Literal[...]` as non-reference text. This matches the issue wording about
> literal values rather than only special-casing booleans."*
> — [`reports/baseline_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/baseline_notes.md#L26)

That enumeration is reasonable but **incomplete in two specific ways**. It assumes
every literal value reaches the constant branch of the AST unparser. It does not,
for two shapes: a *signed* number such as `-1` parses as an `ast.UnaryOp` (which the
baseline `unparse()` does not handle, so it raises `SyntaxError`), and a value whose
`repr()` is not a parseable Python expression (e.g. an enum's `<Color.RED: 1>`) also
fails to parse. In both cases baseline falls through to the catch-all
`except SyntaxError: return [type_to_xref(annotation, env)]`, turning the **whole**
annotation back into a single missing-reference xref — exactly the warning the fix
was supposed to remove. That is the unmet obligation: *every* literal-value shape,
not just the parseable-constant ones, must stay out of the xref path.

## 3. How FVK formally captured the gap

FVK did not start from the failing symptom; it generalized the issue into an
obligation over the full space of literal values. The intent item lifts "whatever
literal value" from the issue text into an enumerated grammar:

> **I4:** *Source: issue phrase "whatever literal value" plus
> `sphinx.util.typing.stringify()` using `repr()` for `Literal` arguments. Obligation:
> string, numeric, signed numeric, boolean, `None`, ellipsis, dotted values, and value
> representations that appear inside recognized `Literal[...]` brackets must not become
> xrefs.*
> — [`fvk/SPEC.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/SPEC.md#L38)

The evidence ledger pins that intent to a concrete code fact found by **source
inspection** of how the value reaches the unparser — `repr()`-based stringification
can produce text that is not a parseable AST expression:

> *"`Literal[<Color.RED: 1>]`, representative of value text that can occur from
> `repr()`-style stringification but is not a parseable Python expression … the AST
> parser would raise `SyntaxError`; the fallback would produce one `pending_xref` for
> the entire annotation string."*
> — [`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L35)

Those facts are discharged into two obligations that the parseable-constant fix does
not satisfy:

> **PO-004 — Literal Constant Formatting.** *`claim parseAnn("Literal[-1]") => XRef("Literal") Punct("[") Text("-1") Punct("]")`* … *unary plus/minus under that flag combines the sign with a single text operand where possible.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/PROOF_OBLIGATIONS.md#L65)

> **PO-005 — SyntaxError Fallback for Recognized Literal Strings.** *When the full
> annotation string has a recognized `Literal[...]` head but the argument text is not
> parseable as a Python AST expression, the fallback must still avoid xrefs for the
> bracketed value text.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/PROOF_OBLIGATIONS.md#L87)

This is FVK's value here: both residual cases were found by **reasoning about the
value grammar**, not by observing a failing test. The issue gives one example
(`Literal[True]`); FVK turns "whatever literal value" into an invariant over every
value shape that can appear in `Literal[...]`, and the source audit (`F-002`,
`F-003`) shows two shapes — signed numbers and unparseable reprs — escape the
baseline's constant-only handling into the whole-annotation fallback.

## 4. From formal output to the fix

The FVK arm's repair is a V1→V2 iteration, and the artifacts record each step from
finding to obligation to patch hunk.

- The completeness audit of V1 (the baseline-style fix) raised two findings:

  > **F-002: V1 Missed Signed Numeric Literal Values.** *Python parses `-1` as
  > `ast.UnaryOp`, which V1 did not handle. That raised `SyntaxError` … so the
  > annotation could still produce a missing-reference warning … Status: fixed in V2
  > by handling `ast.UAdd` and `ast.USub` under `literal_args`. Covered by `PO-004`.*
  > — [`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L20)

  > **F-003: V1 Did Not Cover Unparseable Literal Value Representations.** *Status:
  > fixed in V2 by a constrained fallback for full `Literal[...]`, `typing.Literal[...]`,
  > and `typing_extensions.Literal[...]` strings. Covered by `PO-005`.*
  > — [`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L35)

- The iteration guidance turned each finding into an instruction for V2:

  > *"Extend V1 for signed numeric literal values. Justification: `F-002` and `PO-004`.
  > Add a constrained fallback for recognized `Literal[...]` strings that are not
  > parseable by the AST parser. Justification: `F-003` and `PO-005`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/ITERATION_GUIDANCE.md#L10)

- The decision log records the resulting code changes with their provenance:

  > *"Added `ast.UnaryOp` handling for `+` and `-` while `literal_args` is true. V1
  > missed signed numeric literals such as `Literal[-1]` … justified by `F-002` and
  > `PO-004`. Added `parse_literal_annotation_fallback()` … justified by `F-003` and
  > `PO-005`."*
  > — [`reports/fvk_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/fvk_notes.md#L10)

The causal chain is fully on the record:

```
SPEC I4   ->  F-002 (audit: signed -1 parses as UnaryOp, escapes to whole-annotation xref)
          ->  F-003 (audit: unparseable repr text escapes the same way)
          ->  PO-004 (obligation: signed literal stays text)
          ->  PO-005 (obligation: recognized-Literal fallback stays text)
          ->  ITERATION_GUIDANCE  ->  V2 patch
```

The [V2 patch](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/solutions/solution_fvk.patch)
adds the `ast.UnaryOp` branch under `literal_args` and the constrained fallback:

```python
elif isinstance(node, ast.UnaryOp):
    if literal_args and isinstance(node.op, (ast.UAdd, ast.USub)):
        sign = '-' if isinstance(node.op, ast.USub) else '+'
        operand = unparse(node.operand, literal_args)
        ...
def parse_literal_annotation_fallback(annotation: str) -> Optional[List[Node]]:
    for literal_name in ('Literal', 'typing.Literal', 'typing_extensions.Literal'):
        prefix = literal_name + '['
        if annotation.startswith(prefix) and annotation.endswith(']'):
            return [type_to_xref(literal_name, env), ...]
```

The V1→V2 transition was driven by findings `F-002`/`F-003` and obligations
`PO-004`/`PO-005`, **not** by a new failing test — no test exercising `Literal[-1]`
or an unparseable-repr value exists in the available suite, and the prompt forbade
running or editing tests
([`prompts/fvk.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/prompts/fvk.md#L26)).

## 5. Verification

**Evidence tier: source-and-artifact reviewed; not executed.** The FVK process ran
no tests, Python, or K tooling — the artifacts state this explicitly
([`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L3),
[`reports/fvk_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/fvk_notes.md#L43)) —
so there is no FVK-specific RED/GREEN demonstration table for the residual cases.
What was inspected, and what supports the claim:

- **The two patches**, side by side: the FVK diff adds exactly the `ast.UnaryOp`
  branch and `parse_literal_annotation_fallback()` over the baseline tree
  ([baseline](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/solutions/solution_baseline.patch),
  [fvk](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/solutions/solution_fvk.patch)).
  The patch delta confirms the §2/§4 narrative is faithful to the shipped code.
- **The official SWE-bench evaluation**, both arms `resolved: true`, both passing the
  same hidden test `tests/test_domain_py.py::test_parse_annotation_Literal`
  ([baseline.report.json](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/eval/baseline.report.json),
  [fvk.report.json](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/eval/fvk.report.json)).
  That both arms pass the *same* test is the point: the official test covers the
  reported `Literal[True]` case but **not** the signed/fallback cases, so the harness
  cannot distinguish the two arms. The residual gap is invisible to the benchmark and
  is established only by source reasoning, not by an executed differential.

**Gold comparison.** The official gold patch fixes the reported `Literal[True]` case
(which is all `test_parse_annotation_Literal` asserts); there is no gold artifact in
this non-curated run to diff against, so whether gold also covers signed/unparseable
values cannot be checked here — the claim of FVK's extra coverage is grounded in the
FVK-vs-baseline delta and the FVK findings, not in a gold comparison.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is narrow — only two value shapes
  (`ast.UnaryOp` signed numbers and unparseable `repr()` values) inside a recognized
  `Literal[...]` head, the rest of literal handling being correct in baseline. But the
  symptom is a **wrong, user-visible missing-reference warning** on valid
  documentation, not a cosmetic difference, which is why this rates above Low. It is
  not High because it does not affect ordinary type annotations or a broad class of
  inputs; the affected scope is confined to literal-value rendering.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-annotation.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/mini-python-annotation.k),
  [`python-annotation-spec.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/python-annotation-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/PROOF.md#L3),
  [finding F-006](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L81)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not a machine-checked proof**.
- **Attribution caveats.** The residual gap is established by source reasoning only;
  there is **no executed test** that fails on baseline and passes on FVK for the
  signed/fallback cases, because the suite is hidden and was not run. The FVK arm also
  leaves one case open by its own admission — arbitrary `Literal` aliases such as
  `L[True]` are not resolved at this parser layer
  ([finding F-005](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L65)) —
  so the fix is more complete than baseline but not claimed exhaustive. The V1→V2
  ordering can be timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md#L12`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/prompts/fvk.md#L12) |
| Baseline blanket-xref root cause | [`reports/baseline_notes.md#L7`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/baseline_notes.md#L7) |
| Baseline value-kind enumeration | [`reports/baseline_notes.md#L26`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/baseline_notes.md#L26) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/solutions/solution_baseline.patch) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/solutions/solution_fvk.patch) |
| Intent I4 (literal-value grammar) | [`fvk/SPEC.md#L38`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/SPEC.md#L38) |
| Evidence (unparseable repr) F-003 | [`fvk/FINDINGS.md#L35`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L35) |
| Finding F-002 (signed UnaryOp) | [`fvk/FINDINGS.md#L20`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L20) |
| Obligation PO-004 | [`fvk/PROOF_OBLIGATIONS.md#L65`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/PROOF_OBLIGATIONS.md#L65) |
| Obligation PO-005 | [`fvk/PROOF_OBLIGATIONS.md#L87`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/PROOF_OBLIGATIONS.md#L87) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L10`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/ITERATION_GUIDANCE.md#L10) |
| Decision trace | [`reports/fvk_notes.md#L10`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/reports/fvk_notes.md#L10) |
| Open case F-005 (aliases) | [`fvk/FINDINGS.md#L65`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L65) |
| Proof honesty boundary F-006 | [`fvk/FINDINGS.md#L81`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/FINDINGS.md#L81) |
| Constructed K core | [`fvk/mini-python-annotation.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/mini-python-annotation.k), [`fvk/python-annotation-spec.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/python-annotation-spec.k) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/fvk/PROOF.md#L3) |
| Official eval (both resolved) | [`eval/baseline.report.json`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/eval/fvk.report.json) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified043-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9602/transcripts/fvk.jsonl.gz) |
</content>
</invoke>
