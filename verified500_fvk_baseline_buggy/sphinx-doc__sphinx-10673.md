# sphinx-doc__sphinx-10673

## Summary

**Severity:** Medium — once generated pages (`genindex`, `modindex`, `search`)
are accepted into a toctree, the baseline leaves one downstream collector,
`assign_section_numbers`, free to treat a generated label as an assignable
source doctree, which can surface on any numbered documentation build that uses
the new feature.

Baseline and FVK both pass the official SWE-bench evaluation for issue #10673
with **different** patches. The baseline guards generated entries only in
figure-number traversal; FVK's audit found that **section-number traversal lost
the same guard**, and added the missing skip. The defect is not exotic — it sits
on a normal numbered build — but it requires a specific collision (a numbered
toctree plus a generated label) to misbehave, which is why it reads as Medium
rather than High.

| Arm | `tests/test_environment_toctree.py::test_toctree_index` | Resolved |
|---|---|---|
| baseline | [PASS](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/eval/baseline.report.json) | yes |
| **fvk** | [PASS](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/eval/fvk.report.json) | yes |

The official `FAIL_TO_PASS` test exercises parsing/resolution only, so both arms
clear it; the section-numbering gap is outside its reach.

## 1. The issue and the real defect

**GitHub issue [sphinx-doc/sphinx#10673](https://github.com/sphinx-doc/sphinx/issues/10673)** —
putting the generated pages `genindex`, `modindex`, or `search` directly in a
toctree raises *"toctree contains reference to nonexisting document"* warnings,
even though those pages are real targets reachable via `:ref:`
([`prompts/baseline.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/prompts/baseline.md#L25)).

The toctree directive treats every non-URL entry as a **source document name**:
parsing warns when the name is absent from `env.found_docs`, and resolution
looks it up in `env.tocs`. The three generated HTML pages are not source
documents, so a toctree referencing them was rejected before the HTML builder
could link to the generated output
([`reports/baseline_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/baseline_notes.md#L4)).
The user-facing observable that is wrong: a legitimate `genindex`/`modindex`/`search`
toctree entry emits a spurious warning instead of producing a link.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/solutions/solution_baseline.patch)
added a `get_toctree_generated_target` helper, taught the parser to accept the
three labels (without adding them to `includefiles`), and taught the resolver to
render them as internal links through the standard domain. It then patched the
numbering collector — but only the **figure-numbering** path:

> *"`repo/sphinx/environment/collectors/toctree.py`: skipped generated-page
> toctree entries during figure-number traversal so `numfig` does not try to
> load non-source doctrees for these generated pages."*
> — [`reports/baseline_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/baseline_notes.md#L26)

That choice was reasonable: figure numbering is where the obvious doctree load
happens, and baseline correctly reasoned that generated pages "are not source
documents and should not affect rebuild dependencies or document relations"
([`reports/baseline_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/baseline_notes.md#L42)).
But the **same collector class** has a second traversal —
`assign_section_numbers` — whose depth-0 entries loop only skips URLs and
`self`. Baseline left that loop unguarded. The exact unmet obligation: *every*
downstream source-document consumer must frame generated entries out, not just
the figure-numbering one. Baseline discharged the symmetry for figures and
stopped one collector short.

## 3. How FVK formally captured the gap

FVK started from intent, not from the symptom. The intent spec generalizes the
issue past parsing into **all downstream consumers**:

> *"Downstream toctree consumers must not treat generated-page entries as source
> doctrees for section numbering, figure numbering, rebuild dependencies, or
> relation construction."*
> — [`fvk/INTENT_SPEC.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/INTENT_SPEC.md#L16)

The evidence ledger pins that intent to a concrete code fact found by source
audit — that the numbering collectors load doctrees per entry — **not** to the
reported test:

> **E6 (source code):** *Numbering collectors iterate `toctreenode['entries']`
> and load `env.tocs` / doctrees for source documents → generated entries must
> be skipped where consumers assume source doctrees.* (*"V1 gap fixed in V2;
> encoded in PO-4."*)
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)

Which is discharged into a formal obligation that names **both** traversals
explicitly:

> **PO-4 — generated entries are not source doctrees in downstream consumers.**
> *Generated entries must be skipped by both section-number and figure-number
> traversal. Neither traversal may require `env.tocs[ref]` or
> `env.get_doctree(ref)` for generated entries.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/PROOF_OBLIGATIONS.md#L33)

This is the crux of FVK's value here: the missing guard was located by
**enumerating every consumer that the invariant binds**, not by observing a
failing build. The issue says only "accept these three pages"; FVK lifts that
into an invariant over the full set of source-document consumers, and the audit
(E6) shows `assign_section_numbers` is a second consumer that PO-4 obliges and
V1 left uncovered.

## 4. From formal output to the fix

The audit recorded the exact step where the formalism changed the patch.

- The completeness audit against PO-4 raised a finding naming the asymmetry:

  > **F1: V1 skipped generated entries only in figure numbering.** *Classification:
  > code bug in V1, fixed in V2. `assign_figure_numbers` had an explicit
  > `get_toctree_generated_target` guard, but `assign_section_numbers` still only
  > skipped URLs and `self`. … V2 adds the generated-target guard to
  > `assign_section_numbers`.*
  > — [`fvk/FINDINGS.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/FINDINGS.md#L5)

- The iteration guidance turned the finding into an instruction for V2:

  > *"Revise the V1 collector handling. Justification: F1 and PO-4. Change: add
  > the generated-target skip to `assign_section_numbers`, matching the V1
  > figure-number skip."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/ITERATION_GUIDANCE.md#L16)

- The decision log records the resulting code change and its provenance:

  > *"Changed `repo/sphinx/environment/collectors/toctree.py` so
  > `assign_section_numbers` explicitly skips generated entries. Trace: F1; PO-4.
  > … Figure numbering already had this guard in V1; section numbering now
  > follows the same invariant and avoids treating a generated label as an
  > assignable source doc."*
  > — [`reports/fvk_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/fvk_notes.md#L27)

The causal chain is fully on the record:

```
INTENT_SPEC #5  ->  E6 (code audit: numbering collectors load doctrees per entry)
                ->  PO-4 (obligation: BOTH traversals skip generated entries)
                ->  F1   (audit: V1 guards figure numbering only)
                ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch hunk
```

The [V2 patch](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/solutions/solution_fvk.patch)
adds the second guard at the `assign_section_numbers` depth-0 entries loop —
the hunk the baseline patch does not contain:

```python
for (_title, ref) in toctreenode['entries']:
    if (url_re.match(ref) or ref == 'self' or
            get_toctree_generated_target(env, ref)):
        # don't mess with those
        continue
```

It also minimally reworks the helper (dropping the redundant `else: return None`
after the early `return`, per
[`reports/fvk_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/fvk_notes.md#L22)),
which the notes flag as behavior-preserving. The `V1 -> V2` transition was
driven by **the formal finding F1/PO-4, not by a new failing test** — the run
had no execution environment and the official `test_toctree_index` passes on
both arms regardless.

## 5. Verification

This case is **non-curated** (analysis=no): there is no gold patch, no
`enhanced_tests/_proof` harness report, and no curated RED/GREEN regression for
the residual defect. Verification is therefore **source-and-artifact reviewed,
not executed**.

What was inspected:

- **Both patches, byte-compared.** The baseline `collectors/toctree.py` hunk
  touches only the figure-numbering loop (`for _title, subdocname in
  subnode['entries']`); the fvk patch adds an additional hunk at the
  `assign_section_numbers` depth-0 loop with the
  `get_toctree_generated_target(env, ref)` guard. The baseline patch contains no
  such hunk — confirmed by inspection of both
  [baseline](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/solutions/solution_baseline.patch)
  and
  [fvk](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/solutions/solution_fvk.patch)
  diffs.
- **Official two-arm evaluation.** Both arms resolve `test_toctree_index` and
  all `PASS_TO_PASS` cases
  ([baseline](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/eval/baseline.report.json),
  [fvk](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/eval/fvk.report.json)).
  This shows the section-numbering gap is **invisible to the official test** —
  it is exactly the kind of residual the FVK audit is meant to catch — but it
  does **not** independently demonstrate the gap's runtime effect; no harness
  was run against a numbered-toctree-plus-generated-label scenario.
- **The proof obligation and its English paraphrase.** PO-4 names both
  traversals; the finding F1 describes the concrete misbehavior (a generated
  `modindex` colliding with a real source doc named `modindex` could take the
  `ref in assigned` branch and warn as a duplicate source document). This is the
  reasoned defect; it is not reproduced on a live build in this run.

No fabricated harness verdicts are claimed.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is the rubric driver. Unlike a Low
  case, the defect lives on a normal feature path — any numbered build that
  adopts the new generated-page toctree entries traverses
  `assign_section_numbers`. But it requires a specific collision (a generated
  label coinciding with section-numbered traversal, e.g. a real source doc
  sharing the `modindex` name) to actually misbehave, so it is not the
  broad-blast-radius profile of a High. Medium reflects "real path, conditional
  trigger."
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-toctree.k`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/mini-toctree.k),
  [`toctree-generated-pages-spec.k`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/toctree-generated-pages-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not a machine-checked proof**.
- **Attribution.** The defect and its fix are documented across
  `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `PROOF_OBLIGATIONS.md`,
  `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`, and the patch delta
  corroborates the F1/PO-4 trace. What is **observed** is the patch difference
  and the two-arm eval; what is **reconstructed** is the runtime consequence of
  the missing guard (the duplicate-source-document warning), which is reasoned
  from F1, not demonstrated on a live build in this run.
- **Old-doc correction.** A previous version of this report stated FVK "updates
  `assign_section_numbers()` to explicitly skip generated entries" — accurate —
  but did not link the obligation/finding chain or note that the official test
  cannot see the gap. Those are now stated. No fix/finding/PO claim from the old
  doc was contradicted by the artifacts; the prior split-file PO labels (F1/PO-4,
  F2/PO-1..3) match the run.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro, observable | [`prompts/baseline.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/prompts/baseline.md#L25) |
| Root cause (source-doc assumption) | [`reports/baseline_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/baseline_notes.md#L4) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/solutions/solution_baseline.patch) |
| Baseline guards figure numbering only | [`reports/baseline_notes.md#L26`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/baseline_notes.md#L26) |
| Baseline rationale (not source docs) | [`reports/baseline_notes.md#L42`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/baseline_notes.md#L42) |
| Intent: downstream consumers | [`fvk/INTENT_SPEC.md#L16`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/INTENT_SPEC.md#L16) |
| Evidence E6 (numbering collectors load doctrees) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L10`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Obligation PO-4 (both traversals) | [`fvk/PROOF_OBLIGATIONS.md#L33`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/PROOF_OBLIGATIONS.md#L33) |
| Finding F1 (section numbering uncovered) | [`fvk/FINDINGS.md#L5`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/FINDINGS.md#L5) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L16`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/ITERATION_GUIDANCE.md#L16) |
| Decision trace (collector change) | [`reports/fvk_notes.md#L27`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/fvk_notes.md#L27) |
| Helper cleanup (redundant else) | [`reports/fvk_notes.md#L22`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/reports/fvk_notes.md#L22) |
| FVK patch (section-numbering guard hunk) | [`solutions/solution_fvk.patch`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/solutions/solution_fvk.patch) |
| Constructed K core | [`fvk/mini-toctree.k`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/mini-toctree.k), [`fvk/toctree-generated-pages-spec.k`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/toctree-generated-pages-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/fvk/PROOF.md#L3) |
| Official eval verdicts (both arms) | [`eval/baseline.report.json`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-10673/eval/fvk.report.json) |
