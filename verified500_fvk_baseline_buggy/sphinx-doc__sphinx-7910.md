# sphinx-doc__sphinx-7910

## Summary

**Severity:** Low — baseline's owner-resolution rewrite is correct for the
reported bug and every test, but it drops two compatibility witnesses
(`unwrap(cls)` for decorated *classes* and the old top-level `__globals__`
fallback); the only genuinely new behavior fires on a niche autodoc ownership
pattern, so the practical blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for issue #7910,
with **different** patches. The FVK arm kept baseline's module+qualname fix but
added an `unwrap(cls)` owner candidate so a member documented on a decorated
*class* (exposed via `__wrapped__`) is still recognized, and preserved the old
`obj.__globals__[cls_path]` lookup as a fallback for non-dotted top-level class
paths. FVK located both edges by **formalizing owner resolution as a set of
frame conditions and auditing each against the patch** — not by running tests;
the decisive `unwrap(cls)` edge is one the human gold fix never touches.

| Arm | [`SkipMemberTest::test_class_decorated_doc`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/tests.json#L3) | Resolved |
|---|---|---|
| baseline | resolved (official eval) | yes (reported case) |
| gold (human oracle) | resolved | yes (reported case) |
| **fvk** | resolved (official eval) | yes + decorated-class edge |

## 1. The issue and the real defect

**Issue: "Decorated `__init__` doesn't show up in docs."** With
`napoleon_include_init_with_doc = True`, a `functools.wraps`-decorated `__init__`
is not documented because Napoleon's owner resolution fails
([`problem_statement.md`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/problem_statement.md#L5)).

`sphinx.ext.napoleon._skip_member()` decides whether a private / special /
`__init__` member with a docstring belongs to the documented class before it
overrides autodoc's default skip. For a top-level class it resolved the owner
with `obj.__globals__[cls_path]`. The reporter pinned the exact failing line
([`problem_statement.md`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/problem_statement.md#L16)):

```python
cls = obj.__globals__[cls_path]
```

When `obj` is a wrapper produced by `functools.wraps()`, its `__globals__`
belongs to the **decorator's** defining module, not the class's. If the
decorator lives elsewhere, that dict lacks the class name, `cls_is_owner` stays
false, and the documented `__init__` is silently skipped.

## 2. Baseline's fix — and where it stopped

[Baseline](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/baseline.patch)
replaced the fragile `__globals__` branch entirely, resolving the owner from the
object's `__module__` plus its dotted `__qualname__` for **both** top-level and
nested classes — which works precisely because `functools.wraps()` preserves
`__module__` and `__qualname__`:

```python
mod = importlib.import_module(obj.__module__)
mod_path = cls_path.split('.')
cls = functools.reduce(getattr, mod_path, mod)
```

Baseline was not careless. Its notes show it *consciously rejected* both
compatibility witnesses FVK later restored:

> *"I considered unwrapping the callable via Sphinx's inspect helpers before
> using `__globals__`. That would address simple method decorators, but it would
> keep two separate owner-resolution paths … I also considered adding a fallback
> to the old `__globals__` lookup … retaining the wrapper-globals path would
> mainly preserve the brittle behavior that caused this issue."*
> — [`reports/baseline_notes.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/reports/baseline_notes.md#L37)

That reasoning is sound for the reported *method* case. But it leaves two
obligations unmet: a documented member owned by a decorated **class** whose
`__wrapped__` original holds the member (module+qualname resolves to the
*wrapper*, whose `__dict__` lacks the member), and a top-level class where module
import is unavailable but the old globals lookup would have worked.

## 3. How FVK formally captured the gap

FVK started from intent, not the symptom. The intent spec lifts the issue past
the single reported method to **every** owner-resolution path, and the public
hint about decorated classes becomes its own requirement:

> *"7. The public hint that class decoration has the same issue means a class
> wrapper using the standard `__wrapped__` convention should not hide ownership
> of a documented member from Napoleon."*
> — [`fvk/INTENT_SPEC.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/INTENT_SPEC.md#L21)

The evidence ledger pins that intent to the reporter's own out-of-band hint —
sourced as a public fact, **not** the reported test:

> *"I7 | prompt hint | 'I've found the same issue if you decorate the class as
> well.' | Standard class wrappers that expose `__wrapped__` should be checked as
> owner candidates. | Encoded in C2."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11)

Which is discharged into a formal obligation that baseline's single-`__dict__`
check cannot satisfy:

> *"PO4 | Decorated class: `unwrap(cls)` owner candidate can establish ownership.
> | I7 | C2 | Discharged by V2; V1 was incomplete."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF_OBLIGATIONS.md#L10)

The compatibility witness is captured the same way: I4/I8 in the ledger →

> *"PO5 | Top-level fallback: if module lookup fails, preserve old globals lookup
> for non-dotted class paths. | I4/I8 | C4 | Discharged by V2; V1 was
> compatibility-risky."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF_OBLIGATIONS.md#L11)

This is the crux: **the two extra edges were located by reasoning over a frame
of obligations, not by observation.** PO4 falls out of taking the reporter's
class-decoration hint as a first-class requirement; PO5 falls out of demanding
that the rewrite not regress any path the old code handled.

## 4. From formal output to the fix

This run uses the split FVK schema (`INTENT_SPEC.md` + `PUBLIC_EVIDENCE_LEDGER.md`
+ `FORMAL_SPEC_ENGLISH.md`) and **does** carry an `ITERATION_GUIDANCE.md`, so §4
is driven by FINDINGS → obligations → iteration guidance → patch, with
`fvk_notes.md` as the decision log.

- The completeness audit raised two findings against the V1 (= baseline-shaped)
  module+qualname-only fix:

  > *"F2: V1 did not explicitly discharge the public class-decorator hint … V1
  > checked only the wrapper's own `__dict__`. If the member is defined on the
  > wrapped original, ownership remains false … Status: addressed in V2 by
  > checking both the resolved class and `unwrap(cls)`."*
  > — [`fvk/FINDINGS.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/FINDINGS.md#L21)

  > *"F3: V1 dropped the old top-level globals fallback … module lookup failure
  > made ownership false … Status: addressed in V2 by falling back to
  > `obj.__globals__[cls_path]` only for top-level class paths after
  > module+qualname resolution fails."*
  > — [`fvk/FINDINGS.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/FINDINGS.md#L38)

- The iteration guidance turned the findings into concrete code instructions:

  > *"`_skip_member()` checks both the resolved class and `unwrap(cls)`. This
  > addresses F2 and discharges PO4."* … *"`_get_class_from_qualname()`
  > implements module+qualname owner lookup and the compatibility fallback … This
  > addresses F1 and F3 and discharges PO2, PO3, and PO5."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/ITERATION_GUIDANCE.md#L10)

- The decision log records the provenance of each V2 edge:

  > *"V2 imports `unwrap` and checks `unwrap(cls)` because F2 and PO4 identified
  > an undischarged public hint … V1 only checked the wrapper class's own
  > `__dict__`."*
  > — [`reports/fvk_notes.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/reports/fvk_notes.md#L16)

The causal chain is on the record:

```
INTENT_SPEC #7  ->  E-ledger I7 (reporter hint: classes too)
                ->  F2 / PO4  (V1 checks only wrapper __dict__; need unwrap(cls))
                ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch (unwrap(cls) candidate)
I4/I8           ->  F3 / PO5  (V1 dropped top-level globals fallback)
                ->  ITERATION_GUIDANCE  ->  V2 patch (_get_class_from_qualname fallback)
```

The resulting [FVK patch](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/solutions/solution_fvk.patch#L52)
checks both the resolved class and its unwrapped original:

```python
cls_candidates = [cls, unwrap(cls)]
cls_is_owner = any(candidate and hasattr(candidate, name) and
                   name in candidate.__dict__
                   for candidate in cls_candidates)
```

and routes the lookup through a helper that restores the globals fallback only
for non-dotted paths
([`solution_fvk.patch`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/solutions/solution_fvk.patch#L17)).
Both V1→V2 edges were driven by the **formal findings (F2/F3, PO4/PO5)**, not by
a new failing test — the suite's only new test
([`test_class_decorated_doc`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/tests.json#L3))
already passes on baseline.

## 5. Verification

**Evidence tier: source-and-artifact reviewed; not executed.** This is a curated
case (`_materials/` with gold patch and the upstream test) but **without** a
harness RED/GREEN proof set — there is no `enhanced_tests/_proof/` directory, and
the FVK arm itself records that nothing was run:

> *"The FVK proof artifacts are constructed, not machine-checked. No tests,
> Python, or K commands were run."*
> — [`reports/fvk_notes.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/reports/fvk_notes.md#L28)

What was inspected, and what it shows:

- **The two patches**, diffed directly: baseline replaces the `__globals__`
  branch with module+qualname only
  ([`solution_baseline.patch`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/solutions/solution_baseline.patch#L18));
  FVK keeps that but adds the `unwrap(cls)` candidate and the globals fallback
  helper
  ([`solution_fvk.patch`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/solutions/solution_fvk.patch#L46)).
  The delta is real, not a relabel.
- **The official test** `SkipMemberTest::test_class_decorated_doc` is the sole
  `FAIL_TO_PASS`
  ([`tests.json`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/tests.json#L3));
  it exercises the decorated-**method** path, which baseline already fixes. No
  test in the suite exercises FVK's decorated-**class** edge, so the new behavior
  is unobserved by the harness.

**Behavioral reasoning (not executed).** On the reported input and every test,
baseline and FVK behave identically; FVK differs only on a decorated class whose
`__wrapped__` original owns the member, and on a top-level case where module
import is unavailable but globals resolution works
([`ANALYSIS.md`](../verified500_analysis/sphinx-doc__sphinx-7910/ANALYSIS.md#L12)).

**Comparison to the human oracle.** Gold takes a **third** approach again —
`inspect.unwrap(obj).__globals__[cls_path]`, i.e. it unwraps the *method object*
and reads its globals
([`gold.patch`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/gold.patch#L17)).
Gold does **not** add FVK's `unwrap(cls)` class candidate. So FVK's decorated-class
edge goes beyond what the maintainers shipped — but, honestly, so does gold's
own mechanism diverge from FVK's, and the two are not equivalent on contrived
inputs (see §6).

## 6. Boundaries & honesty

- **Severity: Low.** Per the rubric the trigger breadth is narrow: the genuinely
  new FVK behavior fires only on **decorated classes** documented via the
  `__wrapped__` convention, a specialized autodoc ownership pattern. The reported
  bug — decorated *methods* — is already fully fixed by baseline and gold. The
  value demonstrated here is **completeness of the frame conditions** (catching
  obligations PO4/PO5 the baseline rewrite silently dropped), not impact
  magnitude.
- **Honest discount.** The curated analysis rates this *low value /
  `GOLD_MATCH: no`*
  ([`ANALYSIS.md`](../verified500_analysis/sphinx-doc__sphinx-7910/ANALYSIS.md#L3)).
  Of FVK's two extra paths, the `obj.__globals__` fallback is near-dead code that
  restores exactly the brittleness baseline deliberately removed; only the
  `unwrap(cls)` candidate adds new behavior, and it targets a niche the human
  oracle never bothered with. This report sells the **detection method**, not a
  high-impact bug.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-napoleon.k`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/mini-napoleon.k),
  [`napoleon-skip-member-spec.k`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/napoleon-skip-member-spec.k))
  and the `kompile` / `kast` / `kprove` commands were *written but never run* —
  the artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF.md#L3)).
  We claim **proof-structured reasoning** (a formal frame with obligations
  discharged by construction), **not** a machine-checked proof. PO10 (full Python
  import / descriptor / wrapper semantics) is left as an explicit integration
  boundary
  ([`fvk/PROOF_OBLIGATIONS.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF_OBLIGATIONS.md#L19)).
- **Attribution.** No harness verdict backs the extra edge; the correctness
  argument is reconstructed from the patch delta plus FINDINGS/PROOF_OBLIGATIONS,
  not observed. The V1→V2 iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the raw ordering can be timestamped
  from
  [`transcripts/fvk.jsonl.gz`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/transcripts/fvk.jsonl.gz)
  if a reviewer wants the trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, failing line | [`_materials/problem_statement.md`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/problem_statement.md#L16) |
| Baseline patch | [`solution_baseline.patch`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/solutions/solution_baseline.patch#L18) |
| Baseline reasoning (rejected witnesses) | [`reports/baseline_notes.md`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/reports/baseline_notes.md#L37) |
| FVK patch | [`solution_fvk.patch`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/solutions/solution_fvk.patch#L46) |
| Gold patch (different mechanism) | [`_materials/gold.patch`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/gold.patch#L17) |
| Intent item #7 (class decoration) | [`fvk/INTENT_SPEC.md#L21`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/INTENT_SPEC.md#L21) |
| Evidence I7 (reporter hint) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L11`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11) |
| Obligation PO4 (unwrap(cls)) | [`fvk/PROOF_OBLIGATIONS.md#L10`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF_OBLIGATIONS.md#L10) |
| Obligation PO5 (globals fallback) | [`fvk/PROOF_OBLIGATIONS.md#L11`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF_OBLIGATIONS.md#L11) |
| Finding F2 | [`fvk/FINDINGS.md#L21`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/FINDINGS.md#L21) |
| Finding F3 | [`fvk/FINDINGS.md#L38`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/FINDINGS.md#L38) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L10`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/ITERATION_GUIDANCE.md#L10) |
| Decision trace (unwrap(cls) provenance) | [`reports/fvk_notes.md#L16`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/reports/fvk_notes.md#L16) |
| Not-run / constructed proof status | [`fvk/PROOF.md#L3`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/PROOF.md#L3), [`reports/fvk_notes.md#L28`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/reports/fvk_notes.md#L28) |
| Constructed K core | [`fvk/mini-napoleon.k`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/mini-napoleon.k), [`fvk/napoleon-skip-member-spec.k`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/fvk/napoleon-skip-member-spec.k) |
| Low-value / GOLD_MATCH:no discount | [`ANALYSIS.md`](../verified500_analysis/sphinx-doc__sphinx-7910/ANALYSIS.md#L3) |
| Official test (FAIL_TO_PASS) | [`_materials/tests.json`](../verified500_analysis/sphinx-doc__sphinx-7910/_materials/tests.json#L3) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified040-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7910/transcripts/fvk.jsonl.gz) |
