# sphinx-doc__sphinx-9229

## Summary

**Severity:** Low — baseline reads class-alias source comments from a new analyzer
but never records that source file as a rebuild dependency, so incremental builds
can leave alias documentation stale; the trigger is narrow (documented class
aliases routed through `doc_as_attr`, edited after the first build), so the blast
radius is small.

Baseline and FVK both pass the official SWE-bench evaluation for issue #9229 with
**different** patches. The FVK patch adds one line —
`self.directive.record_dependencies.add(analyzer.srcname)` — that the baseline
patch omitted, restoring Sphinx's dependency-tracking invariant for the new
source-comment read. FVK located the gap by **formalizing "any source file used
for autodoc content must be a recorded rebuild dependency" as a frame condition
and auditing the new code path against it** — not by running a rebuild test.

| Arm | `record_dependencies` records `analyzer.srcname` for class-alias comments | Resolved |
|---|---|---|
| baseline | no (source read, dependency not recorded) | no |
| gold (human oracle) | n/a — different implementation path (variable comments) | n/a |
| **fvk** | yes ([`solution_fvk.patch` L15](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_fvk.patch#L15)) | **yes** |

## 1. The issue and the real defect

The reported issue concerns type/class aliases documented by next-line source
comments: for documented aliases, autodoc should render the user-written source
comment instead of the generated fallback text `alias of ...`. The reduced
example covers the `Dict[...]`, `Union[...]`, and `Callable[...]` family
([`prompts/fvk.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/prompts/fvk.md#L7),
intent restated in
[`fvk/INTENT_SPEC.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/INTENT_SPEC.md#L5)).

On Python 3.6-style typing, some of these aliases (`Dict[...]`, `Callable[...]`)
are selected by `ClassDocumenter` and handled as class aliases through
`doc_as_attr`, which returned no docstring and replaced the content with
`alias of ...`
([`reports/baseline_notes.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/reports/baseline_notes.md#L11)).
That inconsistency is the user-facing symptom the issue names.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_baseline.patch)
taught `ClassDocumenter` aliases to look up docstring-comments in the aliasing
module, adding a new `get_docstring_comment()` that loads a `ModuleAnalyzer` for
`self.modname` and returns the comment from `attr_docs`:

```python
def get_docstring_comment(self) -> Optional[List[str]]:
    try:
        analyzer = ModuleAnalyzer.for_module(self.modname)
        analyzer.analyze()
        key = ('.'.join(self.objpath[:-1]), self.objpath[-1])
        if key in analyzer.attr_docs:
            return list(analyzer.attr_docs[key])
    except PycodeError:
        pass
    return None
```

— [`solution_baseline.patch` L9–L19](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_baseline.patch#L9)

This rendered the correct content and passed the official class-alias doccomment
test. Baseline's reasoning is on the record and sound as far as it goes: it
deliberately kept the existing documenter selection and only changed whether
fallback text is emitted, treating the next-line literal as explicit attribute
documentation
([`reports/baseline_notes.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/reports/baseline_notes.md#L33)).

But it stopped one step short. The new method **reads a source file** —
`analyzer.srcname` — to produce rendered content, yet never adds that file to
`self.directive.record_dependencies`. Every other autodoc analyzer read records
its source so incremental rebuilds invalidate stale output. Baseline introduced a
source-read path that bypasses that invariant.

## 3. How FVK formally captured the gap

FVK did not chase the rendering symptom; it generalized the issue into a frame
condition over the *whole* content path and then audited the new code against it.

The intent spec lifts the issue beyond "render the comment" to include the
rebuild-dependency obligation:

> *"If autodoc reads source comments from a module to generate output, that source
> must remain part of the recorded dependency set used by Sphinx rebuild logic."*
> — [`fvk/SPEC.md` (intent item 5)](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/SPEC.md#L14)

The evidence ledger pins that intent to a concrete code fact found by source
audit — Sphinx already records analyzer sources, so the new lookup must too:

> **E6 (code):** *`Documenter.generate()` records analyzer sources as dependencies
> when it uses them.* → *The new class-alias source-comment analyzer lookup should
> also record its source.*
> — [`fvk/SPEC.md` (E6)](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/SPEC.md#L26)

Which is discharged into a focused proof obligation naming the exact missing call:

> **PO5 — Dependency Tracking.** *When `ClassDocumenter.get_docstring_comment()`
> uses `ModuleAnalyzer` for the aliasing module and finds source content, it must
> add `analyzer.srcname` to `directive.record_dependencies`.*
> — [`fvk/PROOF_OBLIGATIONS.md` (PO5)](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/PROOF_OBLIGATIONS.md#L49)

This is the crux of FVK's value here: the defect was located by **reasoning about
an invariant**, not by observing a failed rebuild. The issue only asks for correct
rendered content; FVK derives the additional obligation that any newly-read source
must stay in the dependency graph, and the audit (E6) shows baseline's new lookup
violates it.

## 4. From formal output to the fix

The FVK arm started from the applied V1 (baseline) fix and audited it. The
completeness audit raised a finding tied directly to PO4/PO5:

> **F1: V1 Missed Dependency Recording For Class-Alias Source Comments.** *V1 made
> `ClassDocumenter.get_docstring_comment()` read `ModuleAnalyzer.for_module(self.modname)`
> … That analyzer source was not added to `directive.record_dependencies`. …
> Resolution: V2 records `analyzer.srcname` before returning class-alias source
> comments. Proof obligation: PO4 and PO5.*
> — [`fvk/FINDINGS.md` (F1)](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/FINDINGS.md#L6)

The iteration guidance turned the finding into the concrete edit:

> *"V2 keeps the V1 content behavior and adds
> `self.directive.record_dependencies.add(analyzer.srcname)` when a class-alias
> docstring-comment is found."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/ITERATION_GUIDANCE.md#L9)

And the decision log records the change and its provenance:

> *"Decision: update `ClassDocumenter.get_docstring_comment()` so that when it
> finds a source docstring-comment … it also records `analyzer.srcname` in
> `self.directive.record_dependencies`. … the new source read should preserve that
> frame condition."*
> — [`reports/fvk_notes.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/reports/fvk_notes.md#L11)

The causal chain is fully on the record:

```
SPEC item 5  ->  E6 (code audit: generate() records analyzer sources)
             ->  PO5 (obligation: get_docstring_comment must record srcname)
             ->  F1  (V1 audit: class-alias path skipped the recording)
             ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_fvk.patch#L9)
inserts exactly one line into the new method:

```python
if key in analyzer.attr_docs:
    self.directive.record_dependencies.add(analyzer.srcname)
    return list(analyzer.attr_docs[key])
```

— [`solution_fvk.patch` L14–L16](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_fvk.patch#L14)

The `V1 -> V2` transition was driven by the formal finding `F1`/`PO5`, **not** by
a new failing test: the task forbade execution and no rebuild-invalidation test
exists in the suite (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run has no harness
proof reports and no executed demonstration. The conclusion rests on inspecting:

- the two patches against each other. `diff solution_baseline.patch solution_fvk.patch`
  shows the FVK arm's only behavioral delta is the added
  `self.directive.record_dependencies.add(analyzer.srcname)` line
  ([`solution_fvk.patch` L15](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_fvk.patch#L15));
  the remaining diff is hunk-offset shifts. The baseline method returns
  `list(analyzer.attr_docs[key])` with no preceding `record_dependencies` call
  ([`solution_baseline.patch` L14–L15](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_baseline.patch#L14)).
- the FVK proof obligation PO5 and finding F1, which name the exact missing call
  and tie it to the existing Sphinx dependency-recording invariant (E6).

The failure shape is a documented class/type alias whose aliasing source file is
edited after the first build: because baseline never recorded `analyzer.srcname`,
the incremental rebuild can miss the change and keep rendering the stale comment.
FVK records the dependency at the moment it consumes `attr_docs`, so the
source-comment read is visible to the rebuild graph.

The official `FAIL_TO_PASS` test (`test_class_alias_having_doccomment`) checks
only the *rendered content* for the doccomment path; it does not exercise
incremental-rebuild invalidation or inspect `record_dependencies`, which is why
both arms pass the official evaluation while only FVK preserves the dependency
invariant.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow: it requires a documented
  class/type alias routed through `ClassDocumenter.doc_as_attr`, whose aliasing
  source file is edited *between* builds, under an incremental rebuild. The
  rendered output is correct on the first build; only later staleness is at risk.
  The value demonstrated is **detection of a missed invariant by reasoning**, not
  impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-autodoc-alias.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/mini-autodoc-alias.k),
  [`autodoc-alias-spec.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/autodoc-alias-spec.k))
  and the `kompile`/`kprove` commands were written but never run — the artifacts
  state this explicitly
  ([`fvk/PROOF.md`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/PROOF.md#L1),
  [finding F4](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/FINDINGS.md#L49)).
  We therefore claim **proof-structured reasoning** (a formal spec with
  obligations discharged by construction), **not a machine-checked proof**. The
  bug-detection value is independent of the unrun `kprove`.
- **Attribution / gold comparison.** This is **not** a gold-equality case. The
  official gold patch takes a different implementation path (through variable
  comments / `get_variable_comment()`) and does not directly confirm the one-line
  FVK change; the human-fix flag in the run notes is "no". The case is retained
  because the FVK defect is **specific to baseline's chosen implementation**: once
  baseline reads class-alias comments through a new analyzer lookup, it must record
  that analyzer source — a baseline-specific correctness fix in Sphinx's
  rebuild-dependency model, not a general re-derivation of the human fix.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, alias family | [`prompts/fvk.md#L7`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/prompts/fvk.md#L7), [`fvk/INTENT_SPEC.md#L5`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/INTENT_SPEC.md#L5) |
| `doc_as_attr` is the inconsistent route | [`reports/baseline_notes.md#L11`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/reports/baseline_notes.md#L11) |
| Baseline patch (no dependency recording) | [`solution_baseline.patch#L9`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_baseline.patch#L9) |
| Baseline reasoning | [`reports/baseline_notes.md#L33`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/reports/baseline_notes.md#L33) |
| FVK patch (adds `record_dependencies`) | [`solution_fvk.patch#L14`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/solutions/solution_fvk.patch#L14) |
| Intent item 5 (dependency frame condition) | [`fvk/SPEC.md#L14`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/SPEC.md#L14) |
| Evidence E6 | [`fvk/SPEC.md#L26`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/SPEC.md#L26) |
| Obligation PO5 | [`fvk/PROOF_OBLIGATIONS.md#L49`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/PROOF_OBLIGATIONS.md#L49) |
| Finding F1 | [`fvk/FINDINGS.md#L6`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/FINDINGS.md#L6) |
| Honesty note F4 | [`fvk/FINDINGS.md#L49`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/FINDINGS.md#L49) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L9`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/ITERATION_GUIDANCE.md#L9) |
| Decision trace | [`reports/fvk_notes.md#L11`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/reports/fvk_notes.md#L11) |
| Constructed K core | [`fvk/mini-autodoc-alias.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/mini-autodoc-alias.k), [`fvk/autodoc-alias-spec.k`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/autodoc-alias-spec.k) |
| Proof status (constructed, not run) | [`fvk/PROOF.md#L1`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/fvk/PROOF.md#L1) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified042-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-9229/transcripts/fvk.jsonl.gz) |
