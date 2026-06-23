# django__django-12774

## Summary

**Severity:** Medium — baseline can still reject a valid `in_bulk()` lookup
backed by a single-field `UniqueConstraint` when the field is a relation and the
caller (or the constraint) uses the field's `attname` spelling rather than its
`name`, so a legitimate ORM query raises `ValueError`.

Both arms passed the official SWE-bench evaluation with **different** patches.
Baseline accepts a non-`pk` field when its `name` appears among single-field
total-unique-constraint identifiers; FVK found that Django metadata treats both a
relation field's `name` and its `attname` as valid local identifiers, so
comparing only one spelling can still reject a globally unique field requested
through the other. The defect is a wrongly-rejected legitimate query, not silent
data corruption — hence Medium.

| Arm | `in_bulk()` on a relation field unique via the `attname` spelling | Resolved |
|---|---|---|
| baseline | rejects with `ValueError` (only `field.name` compared) | no |
| gold (human oracle) | resolved the reported `slug` case | — |
| **fvk** | accepts (`unique_fields ∩ {field.name, field.attname}`) | **yes** |

## 1. The issue and the real defect

The task is the standard Django ticket *"Allow QuerySet.in_bulk() for fields with
total UniqueConstraints"* — if a field is unique via a `UniqueConstraint` rather
than `unique=True`, `in_bulk()` on that field wrongly fails
([`prompts/fvk.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/prompts/fvk.md#L2)).
The original guard accepted only `pk` or a field flagged `unique=True`:

```python
if field_name != 'pk' and not self.model._meta.get_field(field_name).unique:
    raise ValueError("in_bulk()'s field_name must be a unique field but %r isn't." % field_name)
```

A field made globally unique by a single-field total `UniqueConstraint` was
rejected even though every key still identifies one row. The user-facing
observable that is wrong: a legitimate `in_bulk(field_name=...)` call raises
`ValueError` instead of returning the id→object dictionary.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/solutions/solution_baseline.patch)
resolves the field once and accepts it when its `name` is among the single-field
total constraints:

```python
unique_fields = {
    constraint.fields[0]
    for constraint in opts.total_unique_constraints
    if len(constraint.fields) == 1
}
if not field.unique and field.name not in unique_fields:
    raise ValueError(...)
```

This is the right shape: it reuses `Options.total_unique_constraints` (which
already excludes conditional constraints) and filters composite constraints with
`len(constraint.fields) == 1`. Baseline's own notes show the choice was
deliberate — it consciously rejected composite and conditional constraints, and
even believed it had covered relation attnames:

> *"The code reuses `Options.total_unique_constraints` … and compares against the
> resolved field's `name` so relation attnames such as `author_id` can still map
> to constraints declared on `author`."*
> — [`reports/baseline_notes.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/reports/baseline_notes.md#L18)

That last belief is the gap: the baseline *code* only ever compares
`field.name`. It never computes `field.attname`, so a constraint (or lookup)
expressed through the attname spelling of a relation field is not matched. The
obligation it left unmet: **a one-field total constraint that names a field's
`attname` proves that same field unique** — and `in_bulk()` must honor it.

## 3. How FVK formally captured the gap

FVK started from intent, not from the symptom. The decisive intent item
generalizes the issue beyond the single `name` spelling:

> *"7. Valid field identifiers for relation fields may be represented by either a
> field name or an attname where Django metadata accepts both forms."*
> — [`fvk/INTENT_SPEC.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/INTENT_SPEC.md#L16)

The evidence ledger pins that intent to a concrete code fact found by source
audit — Django's own local-field validation indexes both spellings — **not** to
any reported test:

> *"E7: `Model._check_local_fields()` indexes both `field.name` and
> `field.attname`. Obligation: compare qualifying constraint identifiers against
> both forms."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PUBLIC_EVIDENCE_LEDGER.md#L27)

Which is discharged into a formal obligation that the validation predicate must
satisfy:

> **PO3: Field Identifier Normalization** — *"a one-field total constraint that
> uses either the resolved field's `name` or `attname` must be treated as
> proving that same field unique."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PROOF_OBLIGATIONS.md#L26)

This is the crux of FVK's value here: the gap was located by **reasoning over
the public field-identifier domain** (intent item 7 → code fact E7 → PO3), not by
observing a failing test. The same chain also pins the *boundary* of the fix —
composite constraints fail `len == 1` and conditional ones are absent from
`total_unique_constraints`, so they must stay rejected
([`fvk/INTENT_SPEC.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/INTENT_SPEC.md#L11)).

## 4. From formal output to the fix

The FVK arm audited its V1 fix (which compared only `field.name`, like baseline)
against the spec, and the audit raised the completeness finding:

> **F2: V1 attname completeness gap is resolved** — *"V1 compared only
> `field.name` … That accepted constraints declared as `author` but did not
> explicitly cover the identifier form `author_id`, even though Django local
> field validation indexes both names. … V2 status: fixed. The check now compares
> the one-field constraint identifier against `{field.name, field.attname}`."*
> — [`fvk/FINDINGS.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/FINDINGS.md#L22)

The finding links to PO3, and the iteration guidance turned it into the concrete
code instruction for V2:

> *"the uniqueness check now compares a qualifying one-field constraint
> identifier against both `field.name` and `field.attname`."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/ITERATION_GUIDANCE.md#L7)

The decision trace records the same provenance, tracing the change to F2/PO3 and
confirming the frame conditions (PO4/PO5) are untouched:

> *"Finding F2 and PO3 surfaced a completeness gap in V1 … the V2 source change
> compares constraint field identifiers against both `field.name` and
> `field.attname`."*
> — [`reports/fvk_notes.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/reports/fvk_notes.md#L7)

The causal chain is fully on the record:

```
INTENT item 7  ->  E7 (code audit: _check_local_fields indexes name AND attname)
               ->  PO3 (obligation: a one-field constraint on name OR attname qualifies)
               ->  F2  (V1 audit: V1 compared only field.name -> attname spelling rejected)
               ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [FVK patch](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/solutions/solution_fvk.patch)
differs from baseline by exactly the normalization step F2/PO3 demanded:

```python
field_names = {field.name, getattr(field, 'attname', field.name)}
if not field.unique and unique_fields.isdisjoint(field_names):
    raise ValueError(...)
```

Baseline's `field.name not in unique_fields` becomes
`unique_fields.isdisjoint({field.name, field.attname})`. The `V1 -> V2`
transition was driven by the **formal completeness audit (F2/PO3)**, not by a new
failing test — the FVK session ran no tests at all (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** No harness proof
bundle, gold patch, or curated analysis materials exist for this instance, and
the FVK session explicitly ran no tests, Python, `kompile`, or `kprove`
([`fvk/FINDINGS.md` F5](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/FINDINGS.md#L76)).
The evidence here is the reviewed artifact set, not an executed RED/GREEN table.

What was inspected:

- The two patches, diffed:
  [`solution_baseline.patch`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/solutions/solution_baseline.patch)
  vs
  [`solution_fvk.patch`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/solutions/solution_fvk.patch).
  Confirmed the sole behavioral delta is `field.name not in unique_fields` →
  `unique_fields.isdisjoint({field.name, field.attname})`.
- The intent → evidence → obligation → finding chain across
  [`INTENT_SPEC.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/INTENT_SPEC.md#L16),
  [`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PUBLIC_EVIDENCE_LEDGER.md#L27),
  [`PROOF_OBLIGATIONS.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PROOF_OBLIGATIONS.md#L26),
  and
  [`FINDINGS.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/FINDINGS.md#L22).
- The compatibility audit confirming signature, return-shape, and callsite
  behavior are unchanged
  ([`PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L7)).
- The constructed K core
  ([`mini-inbulk.k`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/mini-inbulk.k),
  [`in-bulk-spec.k`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/in-bulk-spec.k)),
  whose `singleTotalMatches(NAME, ATT, CS)` models exactly the name/attname
  disjunction, but which was **not** run.

**Gold comparison (prose only; no gold artifact for this instance).** The
official human fix resolved the reported `slug` case. FVK's patch is strictly
broader on the identifier axis: it accepts a single-field total constraint
expressed through either the `name` or the `attname` of a relation field, while
preserving every rejection (composite, conditional, truly non-unique). No gold
patch is available here to diff against, so this comparison is reasoned, not
measured.

## 6. Boundaries & honesty

- **Severity: Medium.** Per the rubric, a legitimate ORM query is **incorrectly
  rejected** — wrong behavior, not silent corruption. The trigger is narrow: it
  requires a **relation field** whose unique single-field constraint (or the
  caller's lookup) is expressed through the `attname` spelling rather than the
  `name`. Common cases (`unique=True` fields, `pk`, constraints named by
  `field.name`) work under baseline already, so the blast radius is a specific
  but realistic model definition. That bounds it to Medium, not High.
- **Proof status: constructed, not machine-checked.** Every FVK artifact is
  labeled *"Status: constructed, not machine-checked"*, and the `kompile`/`kprove`
  commands were recorded but never executed
  ([`fvk/PROOF.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PROOF.md#L3)).
  We claim **proof-structured reasoning** (a spec with obligations discharged by
  construction over a narrow validation model), **not** a verified proof. The
  bug-detection value rests on the source audit (E7 → PO3 → F2), not on the unrun
  K tooling.
- **Attribution caveats.** The `V1 -> V2` step is documented across `FINDINGS`,
  `ITERATION_GUIDANCE`, `PROOF`, and `fvk_notes`, so the formal-audit provenance
  is on the record rather than reconstructed. One honesty note: baseline's own
  notes *claimed* attname coverage
  ([`reports/baseline_notes.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/reports/baseline_notes.md#L18)),
  but the baseline patch never computes `attname` — so the residual defect is
  real in the shipped baseline code even though baseline believed it had handled
  the case. There is no executed test, gold patch, or harness verdict for this
  instance; the case is a source-reviewed formal-audit story, not an empirically
  confirmed RED→GREEN one.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/solutions/solution_baseline.patch) |
| Baseline attname belief | [`reports/baseline_notes.md`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/reports/baseline_notes.md#L18) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/solutions/solution_fvk.patch) |
| Intent item 7 (name/attname) | [`fvk/INTENT_SPEC.md#L16`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/INTENT_SPEC.md#L16) |
| Evidence E7 (`_check_local_fields`) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L27`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PUBLIC_EVIDENCE_LEDGER.md#L27) |
| Obligation PO3 | [`fvk/PROOF_OBLIGATIONS.md#L26`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PROOF_OBLIGATIONS.md#L26) |
| Finding F2 (attname gap) | [`fvk/FINDINGS.md#L22`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/FINDINGS.md#L22) |
| Iteration guidance (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L7`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/reports/fvk_notes.md#L7) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L7`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L7) |
| Honesty note (F5, no execution) | [`fvk/FINDINGS.md#L76`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/FINDINGS.md#L76) |
| Proof status / machine-check commands | [`fvk/PROOF.md#L3`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-inbulk.k`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/mini-inbulk.k), [`fvk/in-bulk-spec.k`](../results/verified009-codex-XC-MINI-PRO-AHP-20260615T210902Z/django__django-12774/fvk/in-bulk-spec.k) |
