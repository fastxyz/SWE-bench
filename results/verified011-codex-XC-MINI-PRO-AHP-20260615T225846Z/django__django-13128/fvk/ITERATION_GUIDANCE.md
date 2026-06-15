# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Keep V1 unchanged.

## Rationale

- F1 and PO1/PO2 identify the original defect and show V1 addresses it at the
  correct layer: output-field inference now recognizes same-type temporal
  subtraction before a parent expression resolves types.
- F2 and PO3 show no source edit is needed in SQL rendering; the existing
  `TemporalSubtraction` path already has the required duration semantics.
- F3 and PO4 show no broader arithmetic inference change is justified by the
  public issue. V1 preserves generic mixed-type errors outside same-type
  temporal subtraction.
- F4 and PO5 show no public compatibility issue requiring a follow-up patch.

## Future Tests To Add Outside This Benchmark

Do not edit tests here. In a normal Django development flow, add coverage for:

- `Experiment.objects.annotate(delta=F('end') - F('start'))` returning a
  duration without `ExpressionWrapper`.
- The exact reported nested expression:
  `F('end') - F('start') + Value(datetime.timedelta(), output_field=DurationField())`.
- Date and time variants matching the existing temporal SQL family.

## Commands For Future Machine Check

These commands are recorded but were not run:

```sh
(cd fvk && kompile mini-django-expressions.k --backend haskell)
(cd fvk && kast --backend haskell temporal-subtraction-spec.k)
(cd fvk && kprove temporal-subtraction-spec.k)
```
