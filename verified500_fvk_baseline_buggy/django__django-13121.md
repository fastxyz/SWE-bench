# django__django-13121

## Summary

**Severity:** Medium — on non-native-duration backends (SQLite/MySQL) a valid
duration expression that nests a temporal subtraction inside `+`/`-` still crashes
with a converter `TypeError`; the trigger is narrow (requires an explicit
`output_field=DurationField()`) but the failure is a hard error, not a wrong value.

Baseline correctly fixed the reported `DurationField + timedelta` case but left a
residual: `DurationField + (DateTimeField − DateTimeField)` is misclassified and
routed through backend interval/date formatting, which fails the `DurationField`
converter. FVK widened the duration-output classifier to recognize same-type
temporal subtraction as duration-producing, fixing a case that **both baseline and
the official gold patch get wrong**.

| Arm | `DurationField + (F('end') − F('start'))` with `output_field=DurationField()` (executed on SQLite) | Resolved |
|---|---|---|
| baseline | **`TypeError: unsupported type for timedelta microseconds component: str`** | no |
| gold (human oracle) | **`TypeError` (same bug)** | no |
| **fvk** | **`timedelta(days=1, microseconds=253000)`** | **yes** |

## 1. The issue and the real defect

**Issue — *"durations-only expressions doesn't work on SQLite and MySQL"*:**
`Experiment.objects.annotate(duration=F('estimated_time') + datetime.timedelta(1))`
raised `decimal.InvalidOperation` inside `convert_durationfield_value`
([`problem_statement.md`](../verified500_analysis/django__django-13121/_materials/problem_statement.md#L1)).

On backends without native duration columns, `DurationField` is stored as integer
microseconds. `CombinedExpression.as_sql()` routes any duration-containing
expression through `DurationExpression`, which formatted **every** duration operand
as a date/time *interval*. That is correct for `datetime + duration`, but wrong when
the whole expression is itself a duration: SQLite fed the operands to
`django_format_dtdelta(...)`, which returns a formatted timedelta *string*, and the
`DurationField` converter then choked
([`problem_statement.md`](../verified500_analysis/django__django-13121/_materials/problem_statement.md#L18)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/solutions/solution_baseline.patch)
added a `duration_only` fast-path: when the connector is `+`/`-` and **both**
operands' `output_field` is literally `DurationField`, it compiles operands as
stored microseconds and combines them with numeric `combine_expression()`. This
fixes the reported case and passes the hidden test. Baseline's design notes confirm
the choice was deliberate:

> *"Added detection for `+` and `-` expressions whose left and right operands both
> produce `DurationField` values. … Preserved the existing duration formatting path
> for mixed date/time and duration expressions."*
> — [`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/reports/baseline_notes.md#L23)

The operand test was the narrowest possible — literal `DurationField` output only:

```python
def has_duration_output(self, expression):
    ...
    return output.get_internal_type() == 'DurationField'
```
— [`solution_baseline.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/solutions/solution_baseline.patch#L27)

The unmet obligation: a **temporal subtraction** (`DateTimeField − DateTimeField`)
compiles to an integer-microsecond duration via `TemporalSubtraction`, but its
*inferred* `output_field` is `DateTimeField`, not `DurationField`. So an outer
`DurationField + (DateTime − DateTime)` fails baseline's classifier on the right
operand, drops out of the numeric branch, and goes back through interval formatting.

## 3. How FVK formally captured the gap

FVK started from an intent spec that scopes the duration-only family **beyond** the
literal `DurationField` shape — it explicitly enumerates temporal subtraction:

> *"The intended family is valid duration addition and subtraction … Duration-only
> `+` and `-` include operands whose output is a `DurationField` … and Django
> temporal subtraction expressions (`DateField - DateField`, `DateTimeField -
> DateTimeField`, `TimeField - TimeField`) that compile to durations."*
> — [`fvk/INTENT_SPEC.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/INTENT_SPEC.md#L15)

The evidence ledger pins that intent to a concrete code fact found by source audit
— `TemporalSubtraction`'s output field — **not** to the reported test:

> **E5: Temporal subtraction is a duration.** *Evidence:
> `TemporalSubtraction.output_field = fields.DurationField()` … Obligation: a
> temporal subtraction expression is duration-producing and is in scope when
> combined with another duration. Status: V1 gap recorded as F2.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/PUBLIC_EVIDENCE_LEDGER.md#L42)

Which is discharged into a formal obligation:

> **PO3: Temporal subtraction counts as duration output.** *Claim: Same-type
> temporal subtraction (`DateField - DateField`, `DateTimeField - DateTimeField`,
> `TimeField - TimeField`) is duration-producing for purposes of duration-only
> arithmetic. … V1 failed this obligation.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/PROOF_OBLIGATIONS.md#L27)

This is the crux: the residual defect was located by **reasoning**, not by a new
test. The intent spec lifts "a duration expression must produce a duration" into an
invariant over *every* duration-producing operand; the code audit (E5) shows
`TemporalSubtraction` is exactly such an operand that baseline's literal-only
classifier misses.

## 4. From formal output to the fix

The FVK arm shipped V2 after auditing its own V1 (which was byte-identical to
baseline) against the spec. The artifacts record the exact step where the formalism
changed the patch.

- The completeness audit raised a finding against V1:

  > **F2: V1 missed temporal subtraction as a duration-producing operand.** *Input:
  > `F('estimated_time') + (F('end') - F('start'))` … the right side's raw
  > `CombinedExpression.output_field` was not recognized as a duration even though
  > `CombinedExpression.as_sql()` later compiles same-type temporal subtraction
  > through `TemporalSubtraction`. … Resolution: `has_duration_output()` now treats
  > same-type … subtraction as duration output.*
  > — [`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/FINDINGS.md#L19)

- The iteration guidance turned the finding into an instruction for the next pass:

  > *"V1 should not stand unchanged. FVK finding F2 and proof obligation PO3 showed
  > that temporal subtraction is a duration-producing expression in Django, but V1
  > did not count it as duration output … V2 keeps the V1 numeric microsecond branch
  > and adds temporal subtraction classification in `has_duration_output()`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code change and its provenance:

  > *"Revised V1 to also classify same-type temporal subtraction as duration output.
  > This change is justified by F2 and PO3. Django's existing
  > `CombinedExpression.as_sql()` already compiles `DateField - DateField` … through
  > `TemporalSubtraction`, whose output field is `DurationField`. V1 missed that
  > duration-producing family when it looked only at the raw expression
  > `output_field`."*
  > — [`reports/fvk_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/reports/fvk_notes.md#L11)

The causal chain is fully on the record:

```
INTENT_SPEC item 3  ->  E5 (code audit: TemporalSubtraction.output_field = DurationField)
                    ->  F2 (V1 audit: classifier misses nested subtraction)
                    ->  PO3 (obligation: same-type temporal subtraction is duration output)
                    ->  ITERATION_GUIDANCE  ->  V2 patch
```

The resulting V2 widens `has_duration_output()` to recognize the temporal
subtraction `CombinedExpression`:

```python
if isinstance(expression, CombinedExpression) and expression.connector == self.SUB:
    ...
    return (
        lhs_output.get_internal_type() in {'DateField', 'DateTimeField', 'TimeField'} and
        lhs_output.get_internal_type() == rhs_output.get_internal_type()
    )
```
— [`solution_fvk.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/solutions/solution_fvk.patch#L29)

The `V1 → V2` transition was driven by the formal finding **F2/PO3**, not by a new
failing test — no test for the nested-subtraction shape exists anywhere in the suite
(see §5).

## 5. Verification

This case has **no harness proof** (no `enhanced_tests/_proof/` reports exist); the
evidence below was executed by the curator out-of-band, not on the SWE-bench harness.

**Behavioral demonstration (executed on in-memory SQLite).** All three variants were
run against the staged Django 3.2a repo (row: `estimated_time=253000µs`,
`end−start=1 day`), swapping `expressions.py` (+ gold's backend files) per variant.

Query:
`annotate(val=ExpressionWrapper(F('estimated_time') + (F('end') - F('start')), output_field=DurationField()))`

| variant | generated SQL (`val` column) | result |
|---|---|---|
| **baseline** | `django_format_dtdelta('+', estimated_time, django_timestamp_diff(end, start))` | **`TypeError: unsupported type for timedelta microseconds component: str`** |
| **gold** | `django_format_dtdelta('+', estimated_time, django_timestamp_diff(end, start))` | **`TypeError: … str`** (same bug) |
| **fvk** | `(estimated_time + django_timestamp_diff(end, start))` | **`timedelta(days=1, microseconds=253000)`** |

Mechanism: `django_format_dtdelta` computes `timedelta+timedelta` then
`return str(out)` → `"1 day, 0:00:00.253000"`; `convert_durationfield_value` then
runs `datetime.timedelta(0, 0, value)` on that string → `TypeError`. FVK skips
`django_format_dtdelta` and emits plain numeric microsecond addition. A second case
(`ExpressionWrapper((F('end') - F('start')) + timedelta(days=1), DurationField())`)
reproduced the same split: baseline/gold `TypeError`, fvk → `timedelta(days=2)`.

**No regressions.** For the direct shapes — `F('estimated_time') + timedelta` (the
FAIL_TO_PASS), `dur+dur`, `dur−timedelta`, mixed `datetime+dur` — baseline, fvk, and
gold produced identical SQL and identical correct results.

**FVK beat the human oracle.** Gold routes through `DurationExpression` only when the
operand types **differ**:

```python
'DurationField' in {lhs_type, rhs_type} and
lhs_type != rhs_type
```
— [`gold.patch`](../verified500_analysis/django__django-13121/_materials/gold.patch#L99)

For `DurationField + (DateTime − DateTime)`, `lhs_type='DurationField'` and
`rhs_type='DateTimeField'` → treated as *mixed* → interval path → the same
`django_format_dtdelta` string bug. So gold confirms FVK's direct-case fix but
**not** the nested-subtraction branch; on that case fvk is the only correct one.

**Why the suite missed it.** The sole FAIL_TO_PASS adds only the direct shape:

```python
def test_duration_expressions(self):
    for delta in self.deltas:
        qs = Experiment.objects.annotate(duration=F('estimated_time') + delta)
```
— [`gold_test.patch`](../verified500_analysis/django__django-13121/_materials/gold_test.patch#L22)

Every `delta` is a plain `timedelta` literal — only `DurationField + literal`. The
suite never nests a temporal subtraction inside a duration expression, which is
exactly why gold ships with the same latent bug.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is narrow: it requires nesting a
  same-type temporal subtraction inside a duration `+`/`-` **and** an explicit
  `output_field=DurationField()` wrapper (without it, output-field resolution raises
  `FieldError: Expression contains mixed types` first — verified identical across all
  three variants). But within that path the failure is a hard `TypeError` on valid,
  idiomatic ORM arithmetic (the gold test itself uses
  `ExpressionWrapper(F('completed') - F('assigned'), output_field=DurationField())`),
  not a silent wrong value — hence Medium, not Low.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-duration-expressions.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/mini-duration-expressions.k),
  [`duration-expression-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/duration-expression-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a formal spec with obligations
  discharged by construction), **not a machine-checked proof**. The bug-detection
  value does not depend on the unrun `kprove`; the fix's correctness is independently
  confirmed by the executed SQLite demonstration above.
- **Attribution caveats.** (1) The win is a completeness/edge improvement, not a fix
  to the reported bug — baseline already fixes that case. (2) FVK is *more* correct
  than gold here, so this branch was never maintainer-validated; no fvk regression vs
  gold was found, but it is strictly beyond the project-blessed fix. (3) The
  demonstration was run on SQLite only; MySQL uses `INTERVAL … MICROSECOND` on the
  same path, so the identical bug class is expected by inspection but not executed.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, converter crash | [`_materials/problem_statement.md`](../verified500_analysis/django__django-13121/_materials/problem_statement.md#L1) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/solutions/solution_baseline.patch#L27) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/reports/baseline_notes.md#L23) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/solutions/solution_fvk.patch#L29) |
| Gold patch (mixed-type routing) | [`_materials/gold.patch`](../verified500_analysis/django__django-13121/_materials/gold.patch#L99) |
| Gold test (direct shape only) | [`_materials/gold_test.patch`](../verified500_analysis/django__django-13121/_materials/gold_test.patch#L22) |
| Intent (temporal subtraction in scope) | [`fvk/INTENT_SPEC.md#L15`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/INTENT_SPEC.md#L15) |
| Evidence E5 | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L42`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/PUBLIC_EVIDENCE_LEDGER.md#L42) |
| Obligation PO3 | [`fvk/PROOF_OBLIGATIONS.md#L27`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/PROOF_OBLIGATIONS.md#L27) |
| Finding F2 | [`fvk/FINDINGS.md#L19`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/FINDINGS.md#L19) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L11`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/reports/fvk_notes.md#L11) |
| Proof status (K unrun) | [`fvk/PROOF.md#L3`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-duration-expressions.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/mini-duration-expressions.k), [`fvk/duration-expression-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/fvk/duration-expression-spec.k) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-13121/transcripts/fvk.jsonl.gz) |
