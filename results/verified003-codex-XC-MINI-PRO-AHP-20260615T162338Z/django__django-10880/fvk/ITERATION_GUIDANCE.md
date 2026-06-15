# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source fix:

```python
extra_context['distinct'] = 'DISTINCT ' if self.distinct else ''
```

## Rationale

F-1 and PO-1/PO-2 show that the reported `DISTINCTCASE` bug is fixed at the shared source of the token adjacency.

F-2 and PO-4/PO-5 show that both conditional aggregation paths are covered: native `FILTER` and fallback `CASE`.

F-3 and PO-3 show that non-distinct rendering remains unchanged.

F-4 and PO-6 show no public compatibility issue from the V1 change.

F-5 and PO-8 require honest labeling of the constructed proof, but they do not justify a source edit.

## Next Checks Outside This Task

In an environment with execution available, run the normal Django tests for aggregation SQL rendering and the K commands in `fvk/PROOF.md`.

Useful source-level test coverage, without modifying tests here:

- `Count(Case(When(...)), distinct=True)` renders `DISTINCT CASE`.
- `Count(Case(When(...)), distinct=False)` still renders `COUNT(CASE ...)`.
- `Count("field", distinct=True, filter=...)` renders correctly on both native `FILTER` and fallback `CASE` backends.

## No Further Code Change

Do not move the separator into `Aggregate.template`; that would alter the non-distinct template shape.

Do not special-case `Count` or `Case`; the defect is the shared distinct marker used by aggregate templates.
