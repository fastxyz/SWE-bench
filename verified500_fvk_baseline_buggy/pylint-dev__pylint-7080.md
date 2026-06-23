# pylint-dev__pylint-7080

## Summary

**Severity:** High — baseline's own `ignore-paths` fix could `continue` past a
whole package subtree when the resolved `__init__.py` matched an ignore rule,
silently dropping submodules the user still expected to be linted; the trigger
is any package argument with a directory-anchored ignore pattern, so the blast
radius is broad and the omission is invisible in the output.

Baseline and FVK both passed the official SWE-bench evaluation for issue #7080
with **different** patches. Baseline correctly added mixed-separator path
normalization, but it guarded an ignored resolved file with a `continue` that
also pruned the package-traversal loop — so when a package resolved to an
ignored `__init__.py`, none of its non-ignored siblings were ever considered.
FVK located this by **formalizing "ignored files must not be emitted" as an
invariant separate from "stop walking this package"** and auditing the V1
control flow against it — not by running a new test.

| Arm | package with ignored `__init__.py` + non-ignored `sub.py` | Resolved |
|---|---|---|
| baseline | submodules skipped (over-prune) | no |
| **fvk** | `__init__.py` suppressed, `sub.py` still filtered & linted | **yes** |

## 1. The issue and the real defect

**Issue pylint-dev/pylint#7080** — *`--recursive=y` ignores `ignore-paths`*: a
recursive run such as `pylint --recursive=y src/` with
`ignore-paths = ["^src/gen/.*$"]` still lints generated files under `src/gen`
([`prompts/fvk.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/prompts/fvk.md#L2)).
The root cause is in `pylint/lint/expand_modules.py`: recursive discovery hands
module expansion a candidate path with **mixed separators** (e.g.
`src/gen\about.py`) that matches neither the all-Posix nor the all-Windows
alternative the configured regex generates, so the ignore rule never fires
([`fvk/FINDINGS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/FINDINGS.md#L6)).
The user-facing observable is wrong lint output for files the configuration said
to ignore.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/solutions/solution_baseline.patch)
fixed the reported separator bug well: it added
`_is_in_ignore_list_re_with_normalized_path`, which keeps raw regex matching and
falls back to a normalized Posix-style path, and routed `ignore-paths` through
it. That part is correct and FVK kept it verbatim.

Baseline went one step further than the reported case and **introduced a second
edit** to also filter ignored *resolved* files. Its notes record the choice:

> *"Added a check after resolving a module or package to its real file path, so
> ignored package `__init__.py` files are skipped before a module description is
> emitted."*
> — [`reports/baseline_notes.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/reports/baseline_notes.md#L25)

The intent was right, but the implementation conflated two distinct actions. Its
patch used a bare `continue`:

```python
filepath = os.path.normpath(filepath)
if os.path.exists(filepath) and _is_ignored_file(...):
    continue
```

That `continue` exits the entire loop iteration — including the package
traversal branch further down. So for a package argument whose `__init__.py`
matches an ignore rule, **every submodule is skipped wholesale**, not filtered
independently. Baseline satisfied "do not emit the ignored file" but violated the
unstated obligation "keep walking the package so non-ignored children are still
checked."

## 3. How FVK formally captured the gap

FVK started from the implementation contract of `expand_modules`, not from the
symptom. The decisive intent item separates emission from traversal:

> **I-005.** *Obligation: ignored paths must not be emitted as module
> descriptions, because those descriptions are the inputs to `_check_file`.*
> — [`fvk/SPEC.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/SPEC.md#L42)

The formal model in the same spec makes the two clauses explicit and pins down
exactly what V1 got wrong:

> *Package traversal is not stopped merely because the resolved package
> `__init__.py` is ignored; submodules are traversed and filtered independently.
> Every submodule path is passed through the same `_is_ignored_file` predicate
> before it is emitted.*
> — [`fvk/SPEC.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/SPEC.md#L77)

That intent is discharged into a formal obligation that the V1 `continue`
provably fails:

> **PO-005 — Ignored package `__init__.py` does not suppress independent
> submodule filtering.** *When a resolved package `__init__.py` is ignored,
> `expand_modules` still enters the package traversal branch if `has_init` is
> true, and each `subfilepath` is filtered independently with `_is_ignored_file`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF_OBLIGATIONS.md#L66)

This is the crux of FVK's value here: the defect was located by **reasoning over
the control flow against a two-part invariant**, not by observing a failing test.
The issue only asked for ignored files to be skipped; FVK lifted that into "skip
the emission, but never the traversal" and the audit showed baseline's `continue`
collapses the two.

## 4. From formal output to the fix

The audit raised an explicit finding against the V1 control flow:

> **F-002: V1 over-skipped package trees when only resolved `__init__.py` was
> ignored.** *V1 used `continue` … That skipped the expansion loop entirely, so
> `pkg/sub.py` was not considered even though it did not match the ignore rule …
> Classification: code bug introduced by V1 and found during FVK audit.*
> — [`fvk/FINDINGS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/FINDINGS.md#L26)

The iteration guidance turned the finding into the concrete edit:

> *"The V2 code now stores the resolved-file ignore decision in `is_ignored`,
> guards only the direct result append with `not is_ignored`, and still traverses
> submodules. This discharges PO-004 and PO-005."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/ITERATION_GUIDANCE.md#L12)

The decision log records the same provenance:

> *"Replace the V1 post-resolution `continue` with an `is_ignored` boolean that
> only suppresses the direct module description append. Reason: FVK Finding F-002
> showed that V1 over-skipped package trees … PO-004 and PO-005 require the
> ignored resolved file not to be emitted while package submodules are still
> traversed and filtered independently."*
> — [`reports/fvk_notes.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/reports/fvk_notes.md#L9)

The causal chain is fully on the record:

```
SPEC I-005 / formal model  ->  PO-005 (traversal must survive an ignored __init__.py)
                           ->  F-002  (V1 audit: `continue` prunes the whole package)
                           ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [FVK patch](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/solutions/solution_fvk.patch)
replaces the `continue` with a boolean that gates only the emission, leaving the
traversal branch intact:

```python
filepath = os.path.normpath(filepath)
is_ignored = os.path.exists(filepath) and _is_ignored_file(...)
...
if not is_namespace and not is_ignored:
    result.append({"path": filepath, ...})
```

The `diff` of the two patches confirms this is the only behavioral delta between
the arms: baseline's `continue` (two added lines) becomes fvk's `is_ignored`
boolean plus the `and not is_ignored` guard on the append; the mixed-separator
helper is byte-identical in both. The `V1 -> V2` transition was driven by `F-002`
/ `PO-005`, **not** by a new failing test — the task forbids running or adding
tests
([`prompts/fvk.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/prompts/fvk.md#L26)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This run is non-curated and has
no harness proof: no SWE-bench Docker rerun, no enhanced regression test, and the
FVK execution environment is explicitly absent
([`prompts/fvk.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/prompts/fvk.md#L26)).
Verification rests on inspection of two things:

- **The patch delta.** `diff solution_baseline.patch solution_fvk.patch` shows
  exactly one behavioral change — baseline's `continue` past an ignored resolved
  file becomes fvk's `is_ignored` flag guarding only the result append. The
  package-traversal branch (`if has_init or is_namespace or is_directory`) is
  unchanged and is no longer short-circuited, so non-ignored submodules of an
  ignored package now reach `_is_ignored_file` individually.
- **The constructed proof.** PO-005 is discharged by source inspection: V2 "no
  longer `continue`s on `is_ignored`," the `has_init` test is computed after the
  guarded append, and the submodule loop still calls `_is_ignored_file` per child
  ([`fvk/PROOF_OBLIGATIONS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF_OBLIGATIONS.md#L74),
  [`fvk/PROOF.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF.md#L39)).

The worked symbolic case is a package `pkg/` with `pkg/__init__.py` and
`pkg/sub.py` and an ignore pattern matching only `pkg/__init__.py`: under
baseline, `pkg/sub.py` is dropped; under fvk, `pkg/__init__.py` is suppressed and
`pkg/sub.py` is filtered independently and linted
([`fvk/ITERATION_GUIDANCE.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/ITERATION_GUIDANCE.md#L26)).
No gold patch is available for this instance (non-curated), so no gold/upstream
comparison is shown.

## 6. Boundaries & honesty

- **Severity: High.** The trigger is broad: any package argument whose
  `__init__.py` matches a directory-anchored `ignore-paths` pattern (e.g.
  `^src/gen/.*$`) causes baseline to silently omit every other file in that
  package from linting. The omission is invisible — the run is green with no
  warning that a subtree was skipped — which is what makes a checker silently
  under-checking dangerous rather than merely cosmetic.
- **Scope caveat (artifact vs. prior doc).** The earlier version of this report
  framed the residual defect as "mixed path separators." The artifacts and the
  patch `diff` correct that: the mixed-separator fix
  (`_is_in_ignore_list_re_with_normalized_path`) is present **identically in both
  arms**, so it is not the baseline-vs-fvk delta. The genuine residual defect is
  the package over-prune from F-002 / PO-005, and §1–§5 are written around that.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-pylint-ignore.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/mini-pylint-ignore.k),
  [`pylint-ignore-paths-spec.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/pylint-ignore-paths-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the
  FVK artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF.md#L3),
  [finding F-004](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/FINDINGS.md#L62)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by source inspection), **not a machine-checked proof**.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the full ordering can be
  reconstructed from the raw model trace
  ([`transcripts/fvk.jsonl.gz`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/transcripts/fvk.jsonl.gz))
  if a reviewer wants the timeline. Because there is no harness rerun, the
  behavioral claim in §5 is reasoned from the diff and the constructed proof, not
  observed in execution.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/prompts/fvk.md#L2) |
| Separator root cause | [`fvk/FINDINGS.md#L6`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/FINDINGS.md#L6) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/solutions/solution_baseline.patch) |
| Baseline reasoning (`continue` edit) | [`reports/baseline_notes.md#L25`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/reports/baseline_notes.md#L25) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/solutions/solution_fvk.patch) |
| Intent I-005 | [`fvk/SPEC.md#L42`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/SPEC.md#L42) |
| Formal model (emit vs traverse) | [`fvk/SPEC.md#L77`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/SPEC.md#L77) |
| Obligation PO-005 | [`fvk/PROOF_OBLIGATIONS.md#L66`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF_OBLIGATIONS.md#L66) |
| Finding F-002 | [`fvk/FINDINGS.md#L26`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/FINDINGS.md#L26) |
| Honesty note F-004 | [`fvk/FINDINGS.md#L62`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/FINDINGS.md#L62) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L12`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/ITERATION_GUIDANCE.md#L12) |
| Decision trace | [`reports/fvk_notes.md#L9`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/reports/fvk_notes.md#L9) |
| PO-005 discharge by inspection | [`fvk/PROOF.md#L39`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF.md#L39) |
| Constructed K core | [`fvk/mini-pylint-ignore.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/mini-pylint-ignore.k), [`fvk/pylint-ignore-paths-spec.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/pylint-ignore-paths-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/fvk/PROOF.md#L3) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-7080/transcripts/fvk.jsonl.gz) |
