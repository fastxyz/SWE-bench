# Findings

Status: constructed, not machine-checked. Findings do not depend on hidden
tests or evaluator feedback.

## F-001: Reported bug localized and resolved by V1

Input:

- return annotation: `None` from `def __init__(...) -> None`;
- wrapped function return: `None`, as constructors return.

Pre-fix observed behavior:

- the wrapper treated the non-empty annotation as a unit target;
- it executed `return_.to(wrapped_signature.return_annotation)`;
- with `return_ is None`, this reached `AttributeError: 'NoneType' object has
  no attribute 'to'`.

Expected behavior from public intent:

- a `None` return annotation is a no-return type hint;
- the wrapper must not call `.to(...)` because of that annotation;
- the constructor path returns `None`.

V1 status:

- resolved by the branch condition checked in PO-RNONE and claims QI-NONE and
  QI-NONE-ANY.

## F-002: Unit return conversion must remain active for non-`None` annotations

Input:

- return annotation: a unit-like annotation such as `u.deg`;
- wrapped function return: a quantity.

Expected behavior from public docs/tests:

- the wrapper calls `.to(return_annotation)`;
- the returned quantity is converted to the annotated unit.

Audit result:

- V1 preserves this behavior because it skips conversion only when the
  annotation is empty or exactly `None`.
- The broader alternative "skip conversion whenever the actual return value is
  `None`" was rejected for this fix because it weakens the documented unit
  return-annotation contract without public intent evidence.

Linked obligations: PO-RUNIT, PO-ADEQUACY-FRAME.

## F-003: Stringified no-return annotations are ambiguous and out of scope

Input:

- return annotation: the string `"None"` rather than the object `None`.

Observed/expected:

- public evidence does not establish that this Astropy version supports
  stringified annotations; the reported environment is Python 3.6 and the
  reproducer uses runtime annotation objects.
- A broader string-annotation policy would also affect argument annotations such
  as `"u.V"`, not just return annotations.

Audit result:

- no V2 code change is justified by the public issue.
- recommended future question: should `quantity_input` support annotations
  stored as strings, and if so should it evaluate unit names, type names, or
  only special-case `"None"`?

## Proof-Derived Findings

No open proof-derived code bug remains in the specified domain. The proof does
surface one important adequacy condition: accepting V1 depends on preserving
unit-return conversion for non-`None` annotations (F-002), not merely avoiding
the constructor crash.

## Test Guidance

Do not modify tests in this task. Future public tests should cover:

- a decorated `__init__` with an argument unit annotation and `-> None`;
- an existing unit return annotation such as `-> u.deg`;
- the no-return-annotation branch returning the original value unchanged.
