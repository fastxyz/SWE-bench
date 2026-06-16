# Iteration Guidance

Status: V1 stands; no additional source edit is justified by this FVK pass.

## Decision

Keep the V1 production patch in `repo/django/forms/models.py` unchanged.

Rationale:

- F-001 is resolved by PO-001 and PO-006: the parent alternate UUID is no longer
  cleared before validation/save.
- F-002 is resolved by PO-002 and PO-004: the hidden inline initial remains
  empty without mutating the parent.
- F-003 and PO-007 show no compatibility issue: callers without explicit
  `initial` retain the same constructor behavior.
- PO-003 preserves the established UUID primary-key behavior.

## Suggested Future Tests

Do not modify tests in this benchmark. In a normal development branch, add a
non-test-source-backed regression test that constructs an inline formset for
`ParentWithUUIDAlternateKey` and `ChildRelatedViaAK`, then asserts:

- constructing forms leaves `parent.uuid` unchanged;
- a bound formset with a non-empty child and empty hidden parent field validates;
- saving through the admin-style sequence preserves the parent's UUID and links
  the child to it.

Existing public tests already cover the empty initial part of the behavior but
not the parent-value preservation that triggered the issue.

## Machine-Checking Follow-Up

When an execution environment exists, the formal artifacts can be checked with:

```sh
kompile fvk/mini-inline-formset.k --backend haskell
kast --backend haskell fvk/inline-formset-spec.k
kprove fvk/inline-formset-spec.k
```

The Django test suite should also be run in an allowed environment. This FVK
pass did not run tests, Python, or K tooling.
