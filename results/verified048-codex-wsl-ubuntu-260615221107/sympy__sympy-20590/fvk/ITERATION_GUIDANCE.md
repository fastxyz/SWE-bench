# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not make additional source edits. The audit localized the regression to the
unslotted printing mixin and confirmed V1 changes the correct class:
`Printable`, the actual target behind the `DefaultPrinting` compatibility
alias.

Justification:

- F-001 and F-002 identify the original regression and show V1 addresses it.
- F-004 records that the rest of the modeled `Symbol` inheritance path already
  declares slots.
- PO-003 through PO-005 discharge the necessary source and proof obligations.
- PO-008 supports the minimality of the one-line source change.

## Follow-Up Tests To Add Or Keep

Recommended tests to add in the normal project workflow, without editing tests
in this benchmark:

- `Symbol('s').__dict__` raises `AttributeError`.
- `Basic` or a representative slotted subclass does not gain `__dict__` through
  `Printable`.
- A subclass of `DefaultPrinting` that omits `__slots__` still has an instance
  dictionary, if that compatibility point is considered public API.

Keep tests for printing output, LaTeX/Jupyter representation hooks, pickling,
and import compatibility; the proof does not subsume those behaviors.

## Future Code Guidance

Any future mixin intended for use above slotted core classes should explicitly
declare `__slots__ = ()` unless it intentionally stores instance state. This is
the general rule surfaced by F-001 and PO-004, but no broader source sweep is
justified for this task because the public issue identifies the printing mixin
path specifically.

## Verification Guidance

The proof is constructed only. A future environment with K available should run:

```sh
cd fvk
kompile mini-python-slots.k --backend haskell
kast --backend haskell symbol-slots-spec.k
kprove symbol-slots-spec.k
```

Until those commands return `#Top`, do not claim machine-checked verification
and do not delete tests on proof-redundancy grounds.
