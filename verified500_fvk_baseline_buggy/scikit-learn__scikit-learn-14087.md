# scikit-learn__scikit-learn-14087

## Summary

**Severity:** Medium — baseline silently gives `LogisticRegressionCV` the wrong
public attribute shape when a non-elastic-net fit is handed an (ignored)
`l1_ratios` argument; it is configuration-specific and shape-corrupting rather
than a crash or silent data poisoning, which is why it is Medium and not High.

Baseline and FVK both passed the official SWE-bench evaluation for issue #14087,
with **different** patches. Baseline fixed the reported `IndexError` (the
`multi_class='auto'` no-refit path) but left the **final attribute-reshape guard
keyed to the raw constructor input** `self.l1_ratios is not None`, so a
non-elastic-net fit that was *passed* an `l1_ratios` argument could still get a
spurious l1-ratio axis bolted onto `coefs_paths_`, `scores_`, and `n_iter_`. FVK
located that second guard by **lifting the issue into an invariant over every
contributor to the fitted attribute shapes and auditing each guard against the
resolved penalty** — not by running more tests (the run had no execution
environment at all).

| Arm | Reshape guard for non-elastic-net `l1_ratios` | Resolved |
|---|---|---|
| baseline | guard on raw `self.l1_ratios is not None` → spurious l1 axis | no |
| gold (human oracle) | not file-linked in this non-curated run (see §5) | — |
| **fvk** | guard on resolved `self.penalty == 'elasticnet'` | **yes** |

## 1. The issue and the real defect

**Issue scikit-learn#14087** — `LogisticRegressionCV(..., refit=False).fit(X, y)`
raises an `IndexError` on valid binary data with the default
`multi_class='auto'`, where the docstring says `auto` resolves to OvR for binary
problems or `solver='liblinear'`
([`prompts/fvk.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/prompts/fvk.md#L2)).

The root cause is that `LogisticRegressionCV.fit` resolves `multi_class='auto'`
to an effective strategy via `_check_multi_class`, but the `refit=False`
coefficient-selection block still branched on the *raw* constructor value
`self.multi_class`. For binary or liblinear fits the resolved strategy is OvR
while `self.multi_class` stays `'auto'`, so the no-refit path indexed an OvR 3D
coefficient path with the 4-index multinomial form and raised the reported
`IndexError`
([`reports/baseline_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/reports/baseline_notes.md#L4)):

```python
best_indices = np.argmax(scores, axis=1)
if self.multi_class == 'ovr':          # raw constructor value, still 'auto'
    w = np.mean([coefs_paths[i, best_indices[i], :] ...], axis=0)
else:
    w = np.mean([coefs_paths[:, i, best_indices[i], :] ...], axis=0)  # over-indexes
```

The same `fit` method carries a *family* of guards that all depend on whether
the active penalty is elastic-net; the reported `IndexError` is only the first
member of that family to surface.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/solutions/solution_baseline.patch)
made the obvious and correct repairs to the failing block: branch on the
**resolved** local `multi_class`, and only average a best `l1_ratio_` when the
active penalty is elastic-net (otherwise append `None`):

```python
-                if self.multi_class == 'ovr':
+                if multi_class == 'ovr':
...
-                best_indices_l1 = best_indices // len(self.Cs_)
-                self.l1_ratio_.append(np.mean(l1_ratios_[best_indices_l1]))
+                if self.penalty == 'elasticnet':
+                    best_indices_l1 = best_indices // len(self.Cs_)
+                    self.l1_ratio_.append(
+                        np.mean(np.asarray(l1_ratios_)[best_indices_l1]))
+                else:
+                    self.l1_ratio_.append(None)
```

Baseline was not careless. Its notes show it *consciously* reasoned that the
fitted estimator should follow the already-computed effective `multi_class`
throughout `fit`, and that non-elastic-net penalties should record `None` for
the absent mixing parameter
([`reports/baseline_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/reports/baseline_notes.md#L13)).
But it fixed the elastic-net guard in **one** of the two places that depend on
it. The exact obligation it left unmet: the *final* attribute-reshape block,
further down in `fit`, still keyed the l1-ratio-axis decision to whether the
constructor was **passed** an `l1_ratios` value, not to whether the **active
penalty** is actually elastic-net:

```python
self.l1_ratios_ = np.asarray(l1_ratios_)
if self.l1_ratios is not None:        # raw constructor input — left unchanged by baseline
    for cls, coefs_path in self.coefs_paths_.items():
        self.coefs_paths_[cls] = coefs_path.reshape(
            (len(folds), self.Cs_.size, self.l1_ratios_.size, -1))
```

Baseline stopped one guard short.

## 3. How FVK formally captured the gap

FVK started from a spec, not from the symptom. The decisive intent items
generalize the issue past the single failing path and pin down that **ignored**
`l1_ratios` must not change elastic-net-specific shapes:

> **Intent 3:** *Branching on coefficient-path shape must follow the effective
> multiclass strategy …*
> **Intent 5:** *Supplying `l1_ratios` with a non-elastic-net penalty is ignored
> after a warning and must not alter elastic-net-specific public attribute
> shapes.*
> — [`fvk/INTENT_SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/INTENT_SPEC.md#L12)

The evidence ledger pins that intent to concrete docstring facts found by source
audit — **not** to the reported test:

> **E-006:** *"`l1_ratios` … Only used if `penalty='elasticnet'`."* → non-elastic-net
> fits do not use l1 ratios.
> **E-008:** *l1-ratio dimension is documented only "If `penalty='elasticnet'`."*
> → shape expansion depends on active penalty.
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)

Which is discharged into a formal obligation over the attribute-shape guard
specifically:

> **O-005 — Elastic-Net Attribute Shape Dimension Is Controlled by Active
> Penalty.** *`coefs_paths_`, `scores_`, and `n_iter_` receive an l1-ratio axis
> exactly when the active penalty is elastic-net … V2 discharge: the final
> reshape guard is `if self.penalty == 'elasticnet'`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PROOF_OBLIGATIONS.md#L50)

This is the crux of FVK's value: **the second guard was located by reasoning,
not observation.** The issue is about one `IndexError`; FVK lifts the docstring
contract ("the l1-ratio dimension exists iff `penalty='elasticnet'`") into an
invariant over *every* shape-deciding guard in `fit`, and the audit finds the
final reshape guard is a second site that keys off the raw constructor input
rather than the active penalty.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** (baseline-equivalent) fixed the `multi_class` branch and the in-loop
  `l1_ratio_` guard, but left the final reshape guard alone. The completeness
  audit against O-005 raised a finding:

  > **F-002: V1 Left One Elastic-Net-Only Shape Guard Keyed to the Raw
  > Constructor Input.** *… the final attribute reshape still checked
  > `self.l1_ratios is not None`. That could add an l1-ratio axis to
  > `coefs_paths_`, `scores_`, and `n_iter_` despite the active penalty not being
  > elastic-net … V2 changes the final reshape guard to
  > `self.penalty == 'elasticnet'`.*
  > — [`fvk/FINDINGS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/FINDINGS.md#L20)

- The iteration guidance turned the finding into the one targeted edit for V2:

  > *V1 did not fully satisfy the elastic-net-only shape obligation O-005 … final
  > l1-ratio dimension reshape now checks `self.penalty == 'elasticnet'` instead
  > of `self.l1_ratios is not None`.*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/ITERATION_GUIDANCE.md#L5)

- The decision log records the change and its provenance:

  > **4. Added the V2 final reshape guard change.** *Finding: F-002. Proof
  > obligation: O-005 … V1 still used `self.l1_ratios is not None` … V2 now uses
  > `self.penalty == 'elasticnet'`, matching the active parameter semantics.*
  > — [`reports/fvk_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/reports/fvk_notes.md#L33)

The causal chain is fully on the record:

```
INTENT 3 / INTENT 5  ->  E-006 / E-008 (docstring: l1 axis iff penalty='elasticnet')
                     ->  O-005  (obligation: reshape guard must key on active penalty)
                     ->  F-002  (audit: V1 reshape guard still keys on raw self.l1_ratios)
                     ->  ITERATION_GUIDANCE / fvk_notes #4  ->  V2 reshape-guard hunk
```

The resulting V2 increment over baseline is exactly one hunk
([`solution_fvk.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/solutions/solution_fvk.patch#L29)):

```python
-        if self.l1_ratios is not None:
+        if self.penalty == 'elasticnet':
             for cls, coefs_path in self.coefs_paths_.items():
                 self.coefs_paths_[cls] = coefs_path.reshape(...)
```

The V1→V2 transition was driven by `F-002`/`O-005`, **not** by a new failing
test — the run was explicitly forbidden from running tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/prompts/fvk.md#L27)).

## 5. Verification

This is a **Tier 3** case: source and artifacts were reviewed, but **nothing was
executed**. The FVK prompt forbade running tests, Python, or `kompile`/`kprove`,
and there is no `_proof/` harness directory for this non-curated instance
([`prompts/fvk.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/prompts/fvk.md#L27)).

What *was* inspected, and is independently checkable from the diff:

- The FVK patch differs from baseline by exactly the one reshape-guard hunk above
  (`diff solution_baseline.patch solution_fvk.patch` yields only that change),
  so the residual-defect claim is grounded in the actual code delta, not
  narration.
- The constructed proof sketch for O-005 argues that ignored `l1_ratios` on a
  non-elastic-net fit cannot alter public attribute rank once the guard keys on
  `self.penalty`
  ([`fvk/PROOF.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PROOF.md#L68)).

**Gold comparison.** This is a non-curated run, so there is no gold patch file
checked in to diff against. The upstream fix for #14087 is the same family of
changes; the FVK arm's distinguishing claim is narrow and self-contained (one
guard moved from `self.l1_ratios` to `self.penalty`), and it is verifiable from
the patch delta regardless of the human oracle.

## 6. Boundaries & honesty

- **Severity: Medium.** The residual defect is a public attribute-shape
  corruption (`coefs_paths_`/`scores_`/`n_iter_` gaining a spurious l1-ratio
  axis), triggered only by a specific and somewhat unusual configuration: a
  **non-elastic-net** penalty that is nonetheless *passed* an `l1_ratios`
  argument under `refit=False`. It is more than cosmetic (downstream code reading
  those attributes sees the wrong rank) but it is configuration-specific and not
  a crash or silent numeric poisoning of fitted coefficients, so it sits at
  Medium, not High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`fvk/mini-logregcv.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/mini-logregcv.k),
  [`fvk/logregcv-refit-false-spec.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/logregcv-refit-false-spec.k))
  and the `kompile`/`kprove` commands were **written but never run** — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PROOF.md#L3),
  [finding F-004](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/FINDINGS.md#L49)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not a machine-checked proof**.
- **Attribution.** The V1→V2 iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`, and the residual-defect claim is
  corroborated by the patch delta — but because nothing was executed in this run,
  the RED→GREEN behavior of the reshape guard is **reasoned, not observed**. A
  reviewer wanting runtime confirmation must run the recommended tests in
  [`fvk/ITERATION_GUIDANCE.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/ITERATION_GUIDANCE.md#L15).

## Artifact map

| Claim | Source |
|---|---|
| Issue / repro (`IndexError`, no-refit auto-OvR) | [`prompts/fvk.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/prompts/fvk.md#L2) |
| No-execution constraint | [`prompts/fvk.md#L27`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/prompts/fvk.md#L27) |
| Root cause (raw `self.multi_class`) | [`reports/baseline_notes.md#L4`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/reports/baseline_notes.md#L4) |
| Baseline reasoning (effective multi_class, `None` l1) | [`reports/baseline_notes.md#L13`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/reports/baseline_notes.md#L13) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/solutions/solution_baseline.patch) |
| FVK patch (reshape-guard hunk) | [`solutions/solution_fvk.patch#L29`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/solutions/solution_fvk.patch#L29) |
| Intent 3 / Intent 5 | [`fvk/INTENT_SPEC.md#L12`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/INTENT_SPEC.md#L12) |
| Evidence E-006 / E-008 | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L10`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Obligation O-005 | [`fvk/PROOF_OBLIGATIONS.md#L50`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PROOF_OBLIGATIONS.md#L50) |
| Finding F-002 | [`fvk/FINDINGS.md#L20`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/FINDINGS.md#L20) |
| Honesty note F-004 | [`fvk/FINDINGS.md#L49`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/FINDINGS.md#L49) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L5`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/ITERATION_GUIDANCE.md#L5) |
| Decision trace #4 | [`reports/fvk_notes.md#L33`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/reports/fvk_notes.md#L33) |
| Constructed proof sketch (O-005) | [`fvk/PROOF.md#L68`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PROOF.md#L68) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-logregcv.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/mini-logregcv.k), [`fvk/logregcv-refit-false-spec.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/logregcv-refit-false-spec.k) |
| Recommended future tests | [`fvk/ITERATION_GUIDANCE.md#L15`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14087/fvk/ITERATION_GUIDANCE.md#L15) |
