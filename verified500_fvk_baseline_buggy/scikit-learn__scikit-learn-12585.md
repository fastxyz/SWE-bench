# scikit-learn__scikit-learn-12585

## Summary

**Severity:** Medium — after the baseline fix a valid estimator configuration can
still crash during routine parameter introspection, because one public
parameter-expansion path keeps treating an estimator *class* as an estimator
*instance*; the trigger (class-valued parameters) is real but narrow, so the
blast radius is contained rather than pervasive.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The baseline patch repaired the two entry points it
reasoned about — `clone()` and `BaseEstimator.get_params()` — but left a **third
public path with the same protocol confusion**: `_BaseComposition._get_params()`,
which backs `get_params(deep=True)` on `Pipeline`, `FeatureUnion`, and
`VotingClassifier`. FVK located that residual path not by running a test but by
**lifting the issue into an invariant over every parameter-introspection surface
and auditing each one**.

| Arm | Composition class-valued `get_params(deep=True)` path guarded? | Resolved |
|---|---|---|
| baseline | [no — loose `hasattr` check survives](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_baseline.patch) | partial |
| **fvk** | [**yes — class exclusion added**](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_fvk.patch#L29) | **yes** |

(No curated gold patch file ships with this non-curated instance; the gold
comparison below is narrative only.)

## 1. The issue and the real defect

The reported issue is that `clone()` fails when an estimator instance carries a
parameter whose **value is an estimator class** rather than an instance — e.g.
`clone(StandardScaler(with_mean=StandardScaler))` raises instead of returning No
error
([`prompts/fvk.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/prompts/fvk.md#L5)).

The root cause is a protocol confusion: scikit-learn decides whether an object is
"estimator-like" by checking only `hasattr(estimator, 'get_params')`. An
estimator **class** exposes `get_params` too — but as an *unbound* method on the
class, not a bound method on an instance. When such a class is used as a
parameter value, the code calls `EstimatorClass.get_params(deep=False)` with no
`self` and raises a missing-`self` `TypeError`
([`reports/baseline_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/baseline_notes.md#L4)).
The public hint in the issue is load-bearing: the discriminator **cannot** be
`isinstance(obj, BaseEstimator)`, because non-`BaseEstimator` objects that expose
`get_params` (Gaussian-process kernels) must keep working
([`fvk/SPEC.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L47)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_baseline.patch)
added the right discriminator — `not isinstance(estimator, six.class_types)` —
in `clone()`, and then, crucially, recognized that the **same loose check existed
in a second place** and fixed it too:

> *"The same loose check existed in `BaseEstimator.get_params(deep=True)`, so a
> class-valued parameter could also fail during normal deep parameter
> introspection even after `clone` itself was fixed."*
> — [`reports/baseline_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/baseline_notes.md#L12)

This is not a careless fix. Baseline used `six.class_types` to match repository
style, deliberately rejected the over-tight `BaseEstimator` check to preserve
kernel support, and explicitly reasoned about whether `clone()` alone was enough:

> *"I considered changing only `clone`, but rejected that because
> `get_params(deep=True)` and callers such as `set_params` would still trip on
> class-valued parameters."*
> — [`reports/baseline_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/baseline_notes.md#L38)

That reasoning is **right as far as it reaches**: baseline found the
`BaseEstimator.get_params` twin. But the audit stopped at the two paths it
happened to inspect. The **composition** parameter manager
`_BaseComposition._get_params()` — a third public path with the identical
`hasattr(estimator, 'get_params')` test, reached through `Pipeline`,
`FeatureUnion`, and `VotingClassifier` — was never enumerated, and so was left
unrepaired. That is the exact obligation baseline left unmet.

## 3. How FVK formally captured the gap

FVK started from intent, not from the symptom. The decisive intent items
generalize the issue from "fix `clone`" to "preserve the class-vs-instance
distinction wherever a parameter is introspected":

> **I2.** *A class value that exposes `get_params` through its estimator class
> must not be treated as an estimator instance. The implementation must not call
> unbound `Class.get_params(...)` while cloning or expanding that value.*
> — [`fvk/SPEC.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L23)

> **I4.** *`get_params(deep=True)` should expand nested estimator instances, but
> should leave estimator classes as ordinary parameter values.*
> — [`fvk/SPEC.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L30)

The evidence ledger pins that intent to a concrete code fact discovered by
**source audit of the public API surface** — not to the reported test:

> **E6 (composition public API):** *`Pipeline.get_params`, `FeatureUnion.get_params`,
> and `VotingClassifier.get_params` delegate to `_BaseComposition._get_params`* →
> *Named estimator expansion must use the same class-vs-instance distinction.*
> — [`fvk/SPEC.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L49)

That fact is discharged into a formal obligation that the composition path must
satisfy the same class exclusion as the two paths baseline already fixed:

> **PO-4 — Composition deep parameter expansion with class-valued named entry.**
> *For any `_BaseComposition` named entry `(name, C)` where `C` is a class,
> `_get_params(..., deep=True)` includes `name -> C` and does not call
> `C.get_params(deep=True)`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF_OBLIGATIONS.md#L53)

This is the crux of FVK's value here: **the third path was located by reasoning
over the API surface, not by a test failure.** The issue only mentions `clone`;
the spec lifts it to "every contributor to parameter introspection must agree on
the class-vs-instance discriminator," and the ledger's E6 audit names
`_BaseComposition._get_params` as a third such contributor that baseline's
two-path fix bypassed.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formal audit changed the patch. The V1 fix entering this arm *was* baseline's
two-path patch; the completeness audit against the spec raised one finding:

> **F-002 — V1 audit gap: composition deep parameter expansion.** *`_BaseComposition._get_params`
> still checked only `hasattr(estimator, 'get_params')`. A class-valued named
> entry could therefore call an unbound `EstimatorClass.get_params(deep=True)`.*
> — [`fvk/FINDINGS.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/FINDINGS.md#L21)

The iteration guidance turned the finding into an instruction for the source
edit, while explicitly keeping the two paths baseline already fixed:

> *"Add the same class exclusion to `repo/sklearn/utils/metaestimators.py::_BaseComposition._get_params`.
> This resolves F-002 and discharges PO-4 across public composition `get_params`
> paths."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/ITERATION_GUIDANCE.md#L13)

The decision log records the resulting change and traces its provenance:

> *"The FVK audit found one V1 gap and I changed source for it: `_BaseComposition._get_params`
> still used the loose `hasattr(estimator, 'get_params')` check. F-002 describes
> the concrete failure mode … and PO-4 requires the same
> `not isinstance(..., six.class_types)` guard there. I applied that edit."*
> — [`reports/fvk_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/fvk_notes.md#L10)

The causal chain is fully on the record:

```
SPEC I2 / I4  ->  E6 (API audit: composition delegates to _BaseComposition._get_params)
              ->  F-002 (V1 audit: composition path still erases the class distinction)
              ->  PO-4  (obligation: composition entry must keep class as ordinary value)
              ->  ITERATION_GUIDANCE / fvk_notes  ->  fvk patch hunk
```

The resulting [fvk patch](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_fvk.patch#L29)
keeps both of baseline's `sklearn/base.py` hunks and adds the missing guard to
the composition manager:

```python
-            if hasattr(estimator, 'get_params'):
+            if (hasattr(estimator, 'get_params') and
+                    not isinstance(estimator, six.class_types)):
```

The `baseline -> fvk` increment was driven by the formal finding **F-002 / PO-4**,
**not** by a new failing test — the task ran with no execution environment and no
tests were added or run
([`fvk/FINDINGS.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/FINDINGS.md#L49)).

## 5. Verification

**No machine execution.** This is a non-curated instance with no harness proof
reports and no executed demonstration table; the FVK task explicitly forbade
running tests, Python, or K tooling, so nothing in this arm was executed
([`prompts/fvk.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/prompts/fvk.md#L26)).
Verification here is **source-and-artifact review, not execution.**

What was inspected and confirmed by review:

- The patch delta is real: `diff` of the two solution files shows the fvk patch
  is baseline's patch **plus** one additional hunk against
  `sklearn/utils/metaestimators.py`, adding `not isinstance(estimator, six.class_types)`
  to `_BaseComposition._get_params`
  ([`solution_fvk.patch`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_fvk.patch#L29)).
- The added guard matches, character for character, the discriminator baseline
  used in its two hunks (`not isinstance(..., six.class_types)`), so the three
  public paths now agree on the class-vs-instance test.
- The compatibility frame was reviewed: regular estimator instances and
  non-`BaseEstimator` `get_params` objects (kernels) still satisfy the non-class
  predicate, so their nested parameters still expand — the change only diverts
  *classes* to the ordinary-value path
  ([`fvk/PROOF_OBLIGATIONS.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF_OBLIGATIONS.md#L70)).

**Gold comparison (narrative).** No curated gold patch file ships with this
instance, so a file-level diff is not possible. The baseline arm — which already
passed the official evaluation — is the relevant comparator: it fixed two of the
three paths, and the official hidden test suite did not exercise the composition
path, so the residual `_BaseComposition._get_params` defect survived evaluation
undetected. FVK closed it on the strength of the API audit alone.

## 6. Boundaries & honesty

- **Severity: Medium.** A valid estimator configuration can crash during routine
  parameter introspection (`get_params(deep=True)` on a `Pipeline` /
  `FeatureUnion` / `VotingClassifier` carrying a class-valued named estimator),
  which is a genuine correctness defect rather than cosmetics — hence not Low.
  But the **trigger breadth is narrow**: it fires only on class-valued parameters
  inside a composition, an uncommon configuration, so it is not High. The value
  demonstrated is **completeness of the audit** — finding the third path the
  reported test never touched — not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-sklearn-clone.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/mini-sklearn-clone.k),
  [`clone-params-spec.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/clone-params-spec.k))
  and the `kompile` / `kast` / `kprove` commands were **written but never run** —
  the FVK artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  PO-1…PO-5 discharged by construction over a mini semantics), **not a
  machine-checked proof**. The residual-risk note is honest that this is a
  partial-correctness argument that does not cover the full Python object model
  ([`fvk/PROOF.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF.md#L70)).
- **Attribution.** Both arms passed the official evaluation, so the
  `baseline -> fvk` increment is **not** attributable to a passing/failing harness
  verdict — it is the extra composition-path hunk, located by the FVK API audit.
  The "third path" claim is observed (it is a literal diff hunk); the *causal*
  link from PO-4 to that hunk is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md` rather than independently re-derived
  here. Whether the residual defect would ever surface in practice depends on a
  user passing an estimator class as a composition member — plausible but
  uncommon.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro, no-exec constraint | [`prompts/fvk.md#L5`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/prompts/fvk.md#L5) |
| Root cause (unbound `get_params` on class) | [`reports/baseline_notes.md#L4`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/baseline_notes.md#L4) |
| Baseline found the `get_params` twin | [`reports/baseline_notes.md#L12`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/baseline_notes.md#L12) |
| Baseline considered/rejected clone-only | [`reports/baseline_notes.md#L38`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/baseline_notes.md#L38) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_baseline.patch) |
| FVK patch (composition hunk) | [`solutions/solution_fvk.patch#L29`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/solutions/solution_fvk.patch#L29) |
| Intent I2 | [`fvk/SPEC.md#L23`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L23) |
| Intent I4 | [`fvk/SPEC.md#L30`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L30) |
| Kernel-support constraint (E4) | [`fvk/SPEC.md#L47`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L47) |
| Evidence E6 (composition API audit) | [`fvk/SPEC.md#L49`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/SPEC.md#L49) |
| Obligation PO-4 | [`fvk/PROOF_OBLIGATIONS.md#L53`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF_OBLIGATIONS.md#L53) |
| Compatibility frame PO-5 | [`fvk/PROOF_OBLIGATIONS.md#L70`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF_OBLIGATIONS.md#L70) |
| Finding F-002 | [`fvk/FINDINGS.md#L21`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/FINDINGS.md#L21) |
| No-test/no-exec caveat F-004 | [`fvk/FINDINGS.md#L49`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/FINDINGS.md#L49) |
| Iteration instruction (add composition guard) | [`fvk/ITERATION_GUIDANCE.md#L13`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace (applied the edit) | [`reports/fvk_notes.md#L10`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/reports/fvk_notes.md#L10) |
| Proof status: not machine-checked | [`fvk/PROOF.md#L3`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF.md#L3) |
| Residual-risk note | [`fvk/PROOF.md#L70`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/PROOF.md#L70) |
| Constructed K core | [`fvk/mini-sklearn-clone.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/mini-sklearn-clone.k), [`fvk/clone-params-spec.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-12585/fvk/clone-params-spec.k) |
