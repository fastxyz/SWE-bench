# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found no source-level problem that requires a V2 code edit.

## Why No Code Change Is Needed

- PO-001 and PO-002 require normal yields to expose fresh, stable dictionary snapshots. V1 uses `ms.copy()` at the normal iterative yield sites.
- PO-003 requires the same behavior for `size=True`. V1 uses `ms.copy()` for the tuple's dictionary component.
- PO-004 requires value-sequence preservation. `dict.copy()` preserves key-value bindings and does not mutate the generator's internal algorithm state.
- PO-006 requires public compatibility. V1 preserves the function signature, dictionary return type, and `(M, P)` shape.
- PO-007 requires removing the old caveat that documented the bug as expected behavior. V1 removed it and added direct-list examples.

## Remaining Boundaries

- The constructed proof was not machine-checked. Keep all existing tests until `kprove` is actually run and returns `#Top`.
- The FVK model does not prove the full integer-partition enumeration algorithm. That would require a separate inductive proof over `keys`, `room`, and `ms`.
- Termination and performance bounds were not proved. The issue explicitly accepts the likely cost of copying before yield, but this pass does not quantify it.

## Suggested Next Tests

Do not edit tests in this task. For a future public test update, add identity-sensitive checks for `list(partitions(...))`, `size=True`, and caller mutation isolation.
