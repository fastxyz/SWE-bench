# FVK Findings: django__django-14559

Status: constructed, not machine-checked. Findings are based only on allowed
public inputs and source inspection. No tests, Python, or K tooling were run.

## F-1: Original implementation discarded available row counts

Input class: any valid successful `bulk_update()` call whose internal batched
`update()` calls return integer row counts.

Observed before the fix: the method called `update()` in a loop and discarded
each return value, so the public API returned `None`.

Expected from intent: return the number of rows matched, computed as the sum of
the batched `update()` return values.

Status: fixed by the V1 behavioral change and preserved by V2. Covered by
PO-1 and PO-4.

## F-2: Empty input must still return an integer

Input class: valid `fields` with `objs` empty.

Observed before the fix: after validation, the method returned `None`.

Expected from intent: `0`, because zero update calls match zero rows and the
new successful return type is an integer.

Status: fixed by returning `0` after validation. Covered by PO-2.

## F-3: V1 wording used "rows updated" where the issue says "rows matched"

Input class: public API documentation and source-level reader interpretation.

Observed in V1: the new docstring said "number of rows updated" and the
accumulator was named `rows_updated`.

Expected from intent: the issue defines the value as "rows matched", following
`update()`'s return semantics. "Updated" can be read as changed rows, which is a
different statistic on some databases.

Status: fixed in V2 by changing the docstring to "rows matched" and renaming
the local accumulator to `rows_matched`. Covered by PO-1.

## F-4: Duplicate primary keys across batches are not deduplicated

Input class: `objs` contains duplicate primary keys split across separate
batches.

Observed with the accepted algorithm: each batch performs a separate
`update()`, so the same database row can contribute to more than one batch
row-count return value.

Expected from public issue evidence: this ticket asks for the sum of the
batched `update()` return values. The public discussion explicitly notes the
duplicate concern and the later stated approach says not to handle duplicates
for this issue.

Status: accepted behavior for this fix, not a V2 code bug. Covered by PO-4 and
documented as a residual semantic choice.

## F-5: Future-proof named tuple return was considered and rejected

Input class: successful `bulk_update()` return value shape.

Observed alternative: a named tuple could carry `rows_matched` and future
statistics.

Expected from public issue evidence: "bulk_update returning int" and preserving
`update()`'s integer convention for the non-returning case.

Status: rejected. V2 keeps the plain integer return. Covered by PO-1 and PO-6.

## F-6: Existing validation behavior remains a frame condition

Input class: invalid `batch_size`, empty `fields`, objects without primary keys,
non-concrete fields, many-to-many fields, and primary key fields.

Observed before and after the fix: existing guards raise before any successful
row-count return.

Expected from intent: this issue changes the successful return value only.

Status: unchanged. Covered by PO-5.

## F-7: Proof and test-removal recommendations are not machine-checked

Input class: the FVK proof package itself.

Observed in this environment: no K tooling, Python execution, or test execution
is allowed.

Expected from FVK honesty rules: proof claims must be labeled "constructed, not
machine-checked", and tests must not be removed.

Status: satisfied. Covered by PO-7.

## Open Findings

No open production-code findings remain for the public issue after the V2
terminology cleanup. Residual risk is limited to the constructed, non-executed
nature of the proof and to the intentional duplicate-across-batches semantics in
F-4.
