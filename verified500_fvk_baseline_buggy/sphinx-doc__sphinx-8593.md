# sphinx-doc__sphinx-8593

## Summary

**Severity:** Low — baseline lets a runtime docstring's `:meta private:` marker
override an explicit `#: :meta public:` variable comment, but only on the narrow
conflict where the two metadata sources disagree, so the practical blast radius
is small.

Baseline and FVK both passed the official SWE-bench evaluation for issue #8593,
with **different** patches. Baseline's V1 *merged* attribute-comment metadata
into the runtime-docstring metadata dictionary, which preserves the rule that
`private` wins when both markers are present — so a variable's explicit
`#: :meta public:` could still be overridden by a `:meta private:` marker on the
assigned object's runtime docstring. The FVK patch (V2) makes the attribute
comment the **effective** metadata source when it carries a visibility marker.
FVK located this residual gap by **formalizing "the attribute comment is the
documentation source for a documented variable" as a precedence obligation** and
auditing whether V1 discharged it — not by running a new test.

| Arm | Attribute-comment visibility precedence (`#: :meta public:` vs runtime `:meta private:`) | Resolved |
|---|---|---|
| baseline | merges the two metadata dicts; runtime `private` can still win | no |
| gold (human oracle) | not separately observable from this run | — |
| **fvk** | attribute-comment marker becomes the effective source | **yes** |

## 1. The issue and the real defect

**GitHub issue [sphinx-doc/sphinx#8593](https://github.com/sphinx-doc/sphinx/issues/8593)** —
a module variable annotated with a `:meta public:` marker in its source comment is
not shown by autodoc. The task continues from a V1 fix and asks the agent to audit
and improve it
([`prompts/fvk.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/prompts/fvk.md#L5)).

The intended behavior: a variable such as `_foo = None  #: :meta public:` should
appear under `.. automodule:: example` with `:members:`, because `:meta public:`
overrides the leading-underscore private-name default
([`fvk/INTENT_SPEC.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L7)).
Source attribute comments (`#:` comments) are the **documentation source** for a
documented variable, so visibility metadata in that comment must participate in
the same visibility decision as runtime-docstring metadata
([`fvk/INTENT_SPEC.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L14)).

The original `Documenter.filter_members()` extracted `:meta public:` /
`:meta private:` only from the runtime docstring (`doc`); a bare module variable
usually has no runtime docstring, so `_foo` fell back to the underscore rule and
was skipped
([`reports/baseline_notes.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/reports/baseline_notes.md#L5)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/solutions/solution_baseline.patch)
looks up the member's source attribute comment and **merges** its extracted
metadata into the runtime-docstring metadata dictionary:

```python
metadata = extract_metadata(doc)
if attr_doc is not None:
    metadata.update(extract_metadata('\n'.join(attr_doc)))
```

This is the obvious fix and it resolves the reported case. Baseline was not
careless about the merge — it *consciously* chose union semantics and recorded why:

> *"I merged attribute-comment metadata into the same metadata dictionary used for
> runtime docstrings. This preserves the existing behavior that `private` wins
> when both `private` and `public` markers are present."*
> — [`reports/baseline_notes.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/reports/baseline_notes.md#L17)

That choice is reasonable for the reported example, but it leaves one obligation
unmet: when the variable's explicit attribute comment says `public` **and** the
assigned object's runtime docstring says `private`, the merge keeps both markers,
the `if 'private' in metadata` check fires first, and the variable is skipped —
the opposite of what the variable's own documentation requested.

## 3. How FVK formally captured the gap

FVK did not start from a failing input; it started from an intent item that
elevates the issue into a precedence rule over the documentation source:

> **Intent 3:** *"Source attribute comments (`#:` comments attached to
> assignments) are the documentation source for documented variables. Therefore
> visibility metadata in that attribute documentation must participate in the same
> visibility decision as metadata in runtime docstrings."*
> — [`fvk/INTENT_SPEC.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L14)

The evidence ledger pins that intent to a concrete code fact found by source
audit — `add_content()` already treats the attribute comment as *the* effective
documentation for the variable, suppressing the runtime docstring:

> **E6 (source):** *`Documenter.add_content()` prefers `attr_docs` for attribute
> documentation and suppresses the runtime docstring for that object* → *"Attribute
> comments are the effective documentation source for variables and should supply
> visibility metadata for variables. Drives Finding F-2 and obligation PO-3."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12)

That fact is discharged into a formal obligation that V1's merge cannot satisfy:

> **PO-3 — Attribute-comment visibility takes precedence for documented
> variables.** *When `attr_doc` contains a visibility marker, that marker is the
> effective visibility metadata for the documented variable, even if the assigned
> runtime object has conflicting docstring metadata. V1 status: failed.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PROOF_OBLIGATIONS.md#L17)

This is the crux of FVK's value here: the residual gap was located by
**reasoning**, not observation. The issue only asked for `_foo` to show; FVK lifts
that into a precedence invariant (the attribute comment is the documentation
source), and the source audit (E6) shows V1's `metadata.update(...)` union
silently violates it whenever the two sources conflict.

## 4. From formal output to the fix

The audit produced exactly one actionable finding, and the artifacts record the
step where the formalism changed the patch.

- The completeness audit against PO-3 raised the finding:

  > **F-2: V1 did not give attribute-comment visibility precedence over conflicting
  > runtime docstring metadata.** *Classification: code bug in V1, fixed in V2 …
  > V1 merged both markers, the existing `private` check won, and the variable was
  > skipped; expected the explicit variable attribute documentation to make it
  > public.*
  > — [`fvk/FINDINGS.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/FINDINGS.md#L13)

- The iteration guidance turned the finding into an instruction for V2:

  > *"V1 needed one improvement: attribute-comment visibility metadata must take
  > precedence over conflicting runtime-docstring visibility metadata when
  > documenting variables. V2 implements that change."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code change and traces it back:

  > *"Changed `…/autodoc/__init__.py` so attribute-comment visibility metadata
  > becomes the effective metadata source when it contains `:meta public:` or
  > `:meta private:`. This addresses F-2 and discharges PO-3. V1 merged attribute
  > metadata with runtime-docstring metadata; the FVK audit showed that could still
  > let an unrelated runtime `private` marker win over explicit variable
  > documentation."*
  > — [`reports/fvk_notes.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/reports/fvk_notes.md#L5)

The causal chain is on the record:

```
INTENT 3  ->  E6 (code audit: add_content treats attr comment as the doc source)
          ->  PO-3 (obligation: attr-comment visibility takes precedence)
          ->  F-2  (V1 audit: union lets runtime `private` override `public`)
          ->  ITERATION_GUIDANCE  ->  fvk_notes decision  ->  V2 patch
```

The resulting [V2 patch](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/solutions/solution_fvk.patch)
replaces V1's `metadata.update(...)` merge with a precedence branch:

```python
if attr_doc is not None:
    attr_metadata = extract_metadata('\n'.join(attr_doc))
    if 'private' in attr_metadata or 'public' in attr_metadata:
        metadata = attr_metadata
    else:
        metadata.update(attr_metadata)
```

When the attribute comment carries a visibility marker it becomes the effective
metadata source; otherwise runtime-docstring metadata is preserved unchanged. The
`V1 -> V2` transition was driven by `F-2`/`PO-3`, **not** by a new failing test —
the task supplied no test results for V1 and forbade running any
([`prompts/fvk.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/prompts/fvk.md#L23)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This run carries no harness
RED/GREEN proof for the residual defect, and the existing doc had no executed
demonstration table. The conflict case (`#: :meta public:` vs runtime
`:meta private:`) was located and resolved by source inspection plus a constructed
proof; it was not run on the SWE-bench harness, and no execution environment
existed during the FVK pass
([`fvk/PROOF.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PROOF.md#L3)).

What was inspected:

- The two patches — V1's `metadata.update(...)` merge vs V2's precedence branch in
  `Documenter.filter_members()`
  ([baseline](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/solutions/solution_baseline.patch),
  [fvk](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/solutions/solution_fvk.patch)).
- The constructed proof sketch for claim `ATTR-VISIBILITY-PRECEDENCE`, which shows
  V1 unioned the two metadata dictionaries so the later `private` check could still
  see the runtime marker, while V2 selects the attribute metadata
  ([`fvk/PROOF.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PROOF.md#L39)).
- The compatibility audit confirming no public signature, directive option, event,
  or storage format changed
  ([`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L7)).

**Harness note.** Both arms passed the official evaluation, and the recorded
`FAIL_TO_PASS` / `PASS_TO_PASS` test sets are *identical* for baseline and FVK
([baseline](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/eval/baseline.report.json),
[fvk](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/eval/fvk.report.json)).
The official suite does **not** distinguish V1's merge from V2's precedence —
the residual conflict case is outside its coverage. That is why FVK's value here
is detection, not a harness delta.

**Gold comparison.** The gold (human oracle) patch is not materialized for this
non-curated instance, so a line-level comparison is not available. What can be
said from the artifacts: the residual gap V2 closes (precedence on conflicting
metadata sources) is a refinement of the basic fix that both V1 and the official
evaluation already accept, so it goes beyond what the reported case strictly
required.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger is narrow: it requires a variable whose explicit
  `#: :meta public:` (or `:meta private:`) attribute comment **conflicts** with
  visibility metadata on the *assigned object's* runtime docstring. Variables with
  a bare value and no runtime metadata — the common case, including the reported
  `_foo = None` — are handled identically by V1 and V2. The value demonstrated
  here is detection power on a corner of the precedence rule, not impact magnitude
  ([`fvk/INTENT_SPEC.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L22)).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-autodoc.k`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/mini-autodoc.k),
  [`autodoc-filter-spec.k`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/autodoc-filter-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  FVK artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PROOF.md#L3),
  [finding F-3](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/FINDINGS.md#L21)).
  We therefore claim **proof-structured reasoning** (a formal spec with PO-3
  discharged by construction), **not a machine-checked proof**.
- **Attribution caveats.** The residual defect and its fix were not independently
  verified on the harness — both arms produce the same official verdict (§5), so
  the precedence improvement is supported by source inspection and the constructed
  proof, not by an observed RED→GREEN. The full `V1 -> V2` ordering is documented
  across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`, and can be
  timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task framing | [`prompts/fvk.md`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/prompts/fvk.md#L5) |
| Intended behavior (variable `:meta public:`) | [`fvk/INTENT_SPEC.md#L7`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L7) |
| Intent 3 (attr comment is the doc source) | [`fvk/INTENT_SPEC.md#L14`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L14) |
| V1 behavior to audit | [`fvk/INTENT_SPEC.md#L22`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/INTENT_SPEC.md#L22) |
| Root cause (runtime-docstring-only extraction) | [`reports/baseline_notes.md#L5`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/reports/baseline_notes.md#L5) |
| Baseline merge rationale | [`reports/baseline_notes.md#L17`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/reports/baseline_notes.md#L17) |
| Baseline patch (V1 merge) | [`solutions/solution_baseline.patch`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/solutions/solution_baseline.patch) |
| FVK patch (V2 precedence) | [`solutions/solution_fvk.patch`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/solutions/solution_fvk.patch) |
| Evidence E6 (add_content uses attr_docs) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L12`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12) |
| Obligation PO-3 (V1 failed) | [`fvk/PROOF_OBLIGATIONS.md#L17`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PROOF_OBLIGATIONS.md#L17) |
| Finding F-2 (residual bug) | [`fvk/FINDINGS.md#L13`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/FINDINGS.md#L13) |
| Honesty finding F-3 (no machine check) | [`fvk/FINDINGS.md#L21`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/FINDINGS.md#L21) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L5`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/reports/fvk_notes.md#L5) |
| Constructed proof (precedence claim) | [`fvk/PROOF.md#L39`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PROOF.md#L39) |
| Constructed K core | [`fvk/mini-autodoc.k`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/mini-autodoc.k), [`fvk/autodoc-filter-spec.k`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/autodoc-filter-spec.k) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L7`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L7) |
| Official eval verdicts (both resolved) | [`eval/baseline.report.json`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/eval/fvk.report.json) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified041-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-8593/transcripts/fvk.jsonl.gz) |
