# Iteration Guidance

Constructed, not machine-checked.

## Decision

V1 stands unchanged after FVK audit.

## Why no further source edit is justified

- F-001 is discharged by PO-1 and PO-3: qualified `py:method :property:` index
  entries now omit callable parentheses.
- F-003 is discharged by PO-1 through PO-7: the audit found no remaining
  in-scope branch where `property in self.options` can produce method-shaped
  index text.
- PO-4 through PO-7 show the fix is narrow: non-property callable entries,
  module-name display, index append behavior, and object registration are
  preserved.

## Follow-up tests to add or update outside this benchmark

Do not edit tests in this task. A normal project follow-up should update the
SUSPECT public expectation identified in F-002 and add focused cases for:

- `.. py:method:: Foo.bar` with `:property:`;
- a nested class `py:method` with `:property:`;
- an unqualified property-option method with and without a module;
- `:property:` combined with `:classmethod:` or `:staticmethod:` to guard PO-3;
- non-property `py:method`, `py:classmethod`, and `py:staticmethod` to guard
  PO-4 frame behavior.

## Machine-check follow-up

When an execution environment exists, run:

```sh
kompile fvk/mini-python-domain.k --backend haskell
kast --backend haskell fvk/python-domain-index-spec.k
kprove fvk/python-domain-index-spec.k
```

Until `kprove` returns `#Top`, the proof remains constructed rather than
machine-checked and test-removal recommendations remain conditional.
