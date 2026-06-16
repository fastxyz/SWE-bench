# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## V2 Decision

Keep the V1 source code unchanged. The FVK audit found the original bug as
F-001 and tied the V1 helper directly to PO-002, PO-003, and PO-004. It also
checked the main compatibility risk, genuine docinfo handling, as F-002 and
PO-005. No proof obligation requires a further source edit.

## Future Verification

If a K environment is available later, run the commands from `fvk/`:

```sh
kompile mini-rst-prolog.k --backend haskell
kast --backend haskell prepend-prolog-spec.k
kprove prepend-prolog-spec.k
```

Treat the proof as machine-verified only if `kprove` returns `#Top`.

## Future Tests

Do not remove existing tests based on this constructed proof. A useful future
test would build a `StringList` like:

```text
:mod:`mypackage2`
=================
```

then call `prepend_prolog()` with a non-empty prolog and assert that the two
title lines remain adjacent after insertion.

## Rejected Follow-Up Changes

Narrowing `docinfo_re` was considered but not applied. It would fix the issue by
making `:mod:`...`` fail the docinfo regex, but it would also change the
recognition of metadata-like field lines more broadly. The title-aware stop
condition is the smaller change justified by E1-E6.

Adding more blank lines around `rst_prolog` was also rejected. The defect is not
insufficient blank-line separation after the prolog; it is insertion at the wrong
position after a title line misclassified as docinfo.

