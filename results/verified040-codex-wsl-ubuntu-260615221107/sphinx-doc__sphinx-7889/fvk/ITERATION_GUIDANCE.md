# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found the issue-reported bug, modeled the
pre-V1 failure mechanism, and discharged the V1 obligations needed to remove it.
No additional production-code edit is justified by the current public evidence.

## Trace to Findings and Obligations

- F1 is resolved by PO1, PO2, PO4, and PO5: non-string generic keys are
  normalized before `_make_subclass` concatenates display names or calls
  `type()`.
- F2 is resolved by PO3: string-name behavior and dotted display names are
  preserved.
- F3 is resolved by PO1 and PO6: the helper only trusts `__name__` when it is
  actually a string, then falls back to `repr()`.
- F4 is resolved by PO7: no public callsite, override, arity, or return-shape
  incompatibility was found.

## Suggested Follow-Up Tests

Do not modify tests in this benchmark task. In a normal development pass, add
focused tests for:

- `_MockObject().SomeClass[TypeVar("T")]` does not raise and returns a mock
  object.
- `_MockObject().SomeClass[int]` does not raise.
- Existing dotted string-name repr assertions continue to pass.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics abstracts away full Python object behavior and focuses on
  the relevant TypeError mechanism.
- Custom generic parameters with intentionally broken `__repr__` remain outside
  the public issue's domain.
