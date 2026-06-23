# django__django-14170

## Summary

**Severity:** Low — baseline crashes only at the single maximum-ISO-year boundary
(`__iso_year=9999`), an edge that is rare in practice but a genuine reachable
`ValueError`.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The reported bug — `__iso_year` filters using
calendar-year `BETWEEN` bounds — is fixed identically by baseline, gold, and
FVK. The residual defect is a second-order one: every arm that computes the ISO
upper bound as `fromisocalendar(value + 1, 1, 1)` raises
`ValueError: Year is out of range: 10000` for `value == 9999`. **Both baseline
and the human gold fix hit this crash;** FVK is the only arm that adds an
explicit `value == datetime.MAXYEAR` guard, so it is *more correct than the human
oracle* on this boundary. FVK located the boundary by lifting "the in-domain year
range includes `datetime.MAXYEAR`" into a proof obligation and auditing the bound
arithmetic against it — not by running a test for year 9999 (none exists).

| Arm | `Model.objects.filter(start_date__iso_year=9999)` | Resolved |
|---|---|---|
| baseline | [`ValueError: Year is out of range: 10000`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_baseline.patch#L22) | no |
| gold (human oracle) | [`ValueError: Year is out of range: 10000`](../verified500_analysis/django__django-14170/_materials/gold.patch#L23) (same crash) | no |
| **fvk** | [returns bounds `[9999-01-04, 9999-12-31]`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_fvk.patch#L18) | **yes** |

## 1. The issue and the real defect

**Issue: "Query optimization in YearLookup breaks filtering by `__iso_year`"**
([`problem_statement.md`](../verified500_analysis/django__django-14170/_materials/problem_statement.md#L6)).
The `YearLookup` optimization replaces an `EXTRACT` with an index-friendly
`BETWEEN` when the right-hand side is a direct value. It is registered for
`__iso_year` too, but uses calendar-year bounds: a filter for
`start_date__iso_year=2020` emits `BETWEEN 2020-01-01 AND 2020-12-31`
([`problem_statement.md`](../verified500_analysis/django__django-14170/_materials/problem_statement.md#L14)).
ISO year 2020 actually runs from 2019-12-30 to 2021-01-03, so the wrong rows are
returned.

That is the *primary* bug, and all three arms fix it. The defect this report is
about is the upper-bound arithmetic used by the fix. To get the last day of ISO
year `Y`, every arm computes the day before ISO year `Y + 1`:

```python
second = datetime.date.fromisocalendar(value + 1, 1, 1) - datetime.timedelta(days=1)
```

For `value == 9999` (`datetime.MAXYEAR`), this evaluates
`fromisocalendar(10000, 1, 1)`, which raises
`ValueError: Year is out of range: 10000`. Year 9999 is inside Python/Django's
representable range and `__year=9999` works, so `__iso_year=9999` is a legitimate
reachable query — it just crashes.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_baseline.patch)
made the right structural call: keep the optimization, correct the bounds. It
added an `iso_year=False` flag to the two existing helpers and computed ISO
bounds inside them. Its notes show the choice was deliberate, not careless — it
explicitly considered and rejected the alternative of dropping the optimization:

> *"I considered removing the `YearLookup` registrations from `ExtractIsoYear`,
> which would force `EXTRACT` SQL for ISO-year filters and also fix correctness.
> I rejected that because it would unnecessarily drop the existing optimization
> instead of correcting the range calculation."*
> — [`reports/baseline_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/reports/baseline_notes.md#L38)

What baseline did not do is bound the input domain. Its ISO upper bound is
[`datetime.date.fromisocalendar(value + 1, 1, 1)`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_baseline.patch#L22)
with no special case for the top of the year range. The unmet obligation is
precisely: *the fix must stay representable across the whole in-domain year
range, including `datetime.MAXYEAR`*. Baseline stopped one boundary short — and
so, identically, did gold.

## 3. How FVK formally captured the gap

FVK did not start from the crash; it started from the input domain. The intent
spec records, as a first-class item, that the maximum representable year is
in-domain unless the contract excludes it:

> **I-006:** *The in-domain year range includes Python/Django's representable
> `datetime.MAXYEAR` value unless the public contract excludes it.*
> — [`fvk/SPEC.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/SPEC.md#L56)

The evidence ledger pins that intent to a concrete domain fact and turns it into
an obligation about the bound arithmetic — derived from the value range, not from
any reported test:

> **E-006, default-domain:** *Python's `datetime.MAXYEAR` is 9999. Obligation:
> `iso_year=9999` must not require constructing year 10000 as an intermediate.*
> — [`fvk/SPEC.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/SPEC.md#L88)

Which is discharged into a formal obligation naming the exact expression to
avoid:

> **PO-003: Maximum representable year does not require year 10000.** *For
> `Y == datetime.MAXYEAR`, ISO date bounds end at `date.max` and ISO datetime
> bounds end at `datetime.max`; the code must not evaluate
> `fromisocalendar(Y + 1, 1, 1)`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/PROOF_OBLIGATIONS.md#L28)

This is where the boundary was found by reasoning: the issue says nothing about
year 9999, and there is no test for it. PO-003 falls out of taking the value
domain seriously (`MAXYEAR == 9999`) and checking the upper-bound expression
(`value + 1`) against it — a static audit of arithmetic against the in-domain
range, not an observed failure.

## 4. From formal output to the fix

The FVK arm iterated: its first attempt (V1) had the *same* unbounded
`value + 1` arithmetic as baseline. The completeness audit against PO-003 raised
the boundary finding:

> **F-003: V1's ISO-year end calculation excluded `datetime.MAXYEAR`.** *Observed
> in V1: ISO end bounds were computed from `date.fromisocalendar(value + 1, 1,
> 1)`, which requires constructing ISO year 10000 for `value == 9999`. … year
> 9999 … should use the maximum representable date or datetime as the upper
> bound.*
> — [`fvk/FINDINGS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/FINDINGS.md#L44)

The iteration guidance turned the finding into a concrete edit for the next
revision:

> *"3. Add a `datetime.MAXYEAR` branch to ISO bound helpers. Justification: F-003
> and PO-003 show that `value + 1` is not representable for `value == 9999`."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/ITERATION_GUIDANCE.md#L17)

And the decision log records the resulting code change and its provenance:

> *"Decision: handle `value == datetime.MAXYEAR` in both ISO helper methods.
> Trace: F-003 and PO-003 require avoiding `fromisocalendar(value + 1, 1, 1)`
> when `value` is 9999."*
> — [`reports/fvk_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/reports/fvk_notes.md#L41)

The causal chain is fully on the record:

```
SPEC I-006 / E-006  ->  PO-003 (obligation: no year-10000 intermediate at MAXYEAR)
                    ->  F-003  (V1 audit: V1 still computes value + 1)
                    ->  ITERATION_GUIDANCE step 3 / fvk_notes decision
                    ->  V2 patch (datetime.MAXYEAR branch)
```

The resulting [V2 patch](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_fvk.patch)
moves ISO bounds into dedicated helpers and guards the upper bound:

```python
first = datetime.date.fromisocalendar(value, 1, 1)
if value == datetime.MAXYEAR:
    second = datetime.date.max
else:
    second = datetime.date.fromisocalendar(value + 1, 1, 1)
    second -= datetime.timedelta(days=1)
```

The `MAXYEAR` guard was driven by `F-003`/`PO-003`, **not** by a new failing
test — no test exercises year 9999 anywhere in the suite (see §5). The same
iteration also retired the V1 `iso_year=` keyword on the existing helpers in
favor of new `year_lookup_bounds_for_iso_year_*` methods (F-002 / PO-006), a
secondary compatibility fix; the MAXYEAR guard is the substantive correctness
delta versus baseline and gold.

## 5. Verification

**No harness proof.** This instance is curated but has no
`enhanced_tests/_proof` reports; it was not run RED/GREEN on the official Docker
harness. The evidence is source-and-execution review of the bound expressions.

**Executed demonstration (not on the harness).** The crash and the fix were
confirmed by directly executing the exact upper-bound expressions for
`value == 9999`:

| Variant | `filter(start_date__iso_year=9999)` |
|---|---|
| baseline | `ValueError: Year is out of range: 10000` |
| gold (human oracle) | `ValueError: Year is out of range: 10000` (same crash) |
| **fvk** | returns bounds `[9999-01-04, 9999-12-31]` |

`9999-12-31` is genuinely in ISO year 9999, and calendar `__year=9999` works, so
`__iso_year=9999` is a legitimate, reachable query — not a synthetic edge.

**FVK beats the human oracle.** [Gold](../verified500_analysis/django__django-14170/_materials/gold.patch#L23)
computes the same unguarded `fromisocalendar(value + 1, 1, 1)` upper bound and
therefore crashes identically at `value == 9999`. FVK's
[`value == datetime.MAXYEAR` branch](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_fvk.patch#L18)
goes beyond what the maintainers shipped.

**The test missed it.** The official FAIL_TO_PASS regression exercises ISO years
around 2014/2015 only; nothing touches year 9999. Both baseline and gold pass the
benchmark despite the latent crash, because the MAXYEAR boundary is an untested
edge.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is a *single* value at the top of the
  year domain (`__iso_year=9999`), which is rare in real queries; calendar-year
  behavior and every ISO year `1..9998` are unaffected. The blast radius is
  small. The value demonstrated here is **detection of an untested boundary that
  the human fix also missed** — sell the method (auditing arithmetic against the
  in-domain range), not the magnitude of the bug.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-yearlookup.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/mini-django-yearlookup.k),
  [`yearlookup-spec.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/yearlookup-spec.k))
  and the recorded `kompile`/`kprove` commands were **written but never run** —
  the artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/PROOF.md#L3),
  [F-004](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/FINDINGS.md#L63)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction over a mini routing/bounds semantics), **not a
  machine-checked proof**. The bug-detection value does not depend on the unrun
  `kprove`; the crash itself was confirmed by direct execution of the bound
  expressions.
- **Attribution / confidence.** Med-high. The `ValueError` was reproduced by
  executing the exact bound arithmetic for `value=9999`; a full DB queryset was
  *not* stood up, but the lookup path calls these helpers unconditionally, so the
  crash is reached on the real code path. The `[9999-01-04, 9999-12-31]` bounds
  for the fvk arm are from that same direct execution.
- **No discrepancy with the run artifacts.** The two patches are *not*
  byte-identical (`diff` of
  [baseline](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_baseline.patch)
  vs
  [fvk](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_fvk.patch)
  shows the MAXYEAR guard and the separate ISO helpers); the carried-over
  severity and the residual-defect claim are both supported by the run
  artifacts.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, bad SQL bounds | [`_materials/problem_statement.md`](../verified500_analysis/django__django-14170/_materials/problem_statement.md#L6) |
| Baseline patch (unguarded `value + 1`) | [`solutions/solution_baseline.patch`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_baseline.patch#L22) |
| Baseline reasoning (kept optimization) | [`reports/baseline_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/reports/baseline_notes.md#L38) |
| FVK patch (MAXYEAR guard) | [`solutions/solution_fvk.patch`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/solutions/solution_fvk.patch#L18) |
| Gold patch (same crash) | [`_materials/gold.patch`](../verified500_analysis/django__django-14170/_materials/gold.patch#L23) |
| Intent I-006 (MAXYEAR in-domain) | [`fvk/SPEC.md#L56`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/SPEC.md#L56) |
| Evidence E-006 (no year 10000) | [`fvk/SPEC.md#L88`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/SPEC.md#L88) |
| Obligation PO-003 | [`fvk/PROOF_OBLIGATIONS.md#L28`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/PROOF_OBLIGATIONS.md#L28) |
| Finding F-003 (V1 boundary bug) | [`fvk/FINDINGS.md#L44`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/FINDINGS.md#L44) |
| Iteration step 3 (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L17`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/ITERATION_GUIDANCE.md#L17) |
| Decision trace | [`reports/fvk_notes.md#L41`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/reports/fvk_notes.md#L41) |
| Constructed proof / unrun K | [`fvk/PROOF.md#L3`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/PROOF.md#L3), [`fvk/FINDINGS.md#L63`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/FINDINGS.md#L63) |
| Constructed K core | [`fvk/mini-django-yearlookup.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/mini-django-yearlookup.k), [`fvk/yearlookup-spec.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14170/fvk/yearlookup-spec.k) |
