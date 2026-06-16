# Constructed Proof

Status: constructed, not machine-checked.

## Summary

The proof covers `_check_readonly_fields_item()` and the indexed label passed by
`_check_readonly_fields()`. It proves partial correctness of the audited
observable: if an invalid `readonly_fields` entry reaches the invalid branch,
the returned `admin.E035` message contains both the indexed label and the
invalid field value, while valid branches still return no errors.

## Formal core

Semantics: `fvk/mini-admin-checks.k`.

Claims: `fvk/readonly-fields-spec.k`.

Exact commands to machine-check later, not run in this session:

```sh
cd fvk
kompile mini-admin-checks.k --backend haskell
kast --backend haskell readonly-fields-spec.k
kprove readonly-fields-spec.k
```

Expected machine-check result after a successful future run: `#Top`.

## Proof sketch

PO-01 follows from the invalid-branch semantic rule:

`checkReadonlyFieldsItem(ADMIN, MODEL, FIELD, LABEL, false, false, false, false)`
rewrites to
`oneError("admin.E035", readonlyE035(LABEL, FIELD, ADMIN, MODEL))`.

The second component of `readonlyE035` is the offending field value, so an
old-style message representation without that component cannot satisfy the
claim. This is the discriminator between the bug and the fixed behavior.

PO-02 follows by one symbolic step through `checkReadonlyFieldsAt(...)`, which
rewrites the caller state to `checkReadonlyFieldsItem(..., readonlyLabel(INDEX),
...)`. Applying PO-01 to that state yields
`readonlyE035(readonlyLabel(INDEX), FIELD, ADMIN, MODEL)`.

PO-03 follows by case analysis over the four success branches. If `ISCALLABLE`
is true, the first success rule returns `noErrors`. If it is false and
`HASADMIN` is true, the second success rule returns `noErrors`. If the first two
are false and `HASMODEL` is true, the third success rule returns `noErrors`. If
the first three are false and `HASFIELD` is true, the fourth success rule
returns `noErrors`.

PO-04 is discharged by source audit rather than a separate K field: the source
still constructs `checks.Error(..., obj=obj.__class__, id="admin.E035")`.

PO-05 is discharged by the V2 edit to `docs/ref/checks.txt`.

PO-06 is discharged by adequacy audit: the legacy public test expectations
conflict with the issue and are marked SUSPECT, so they do not define the
postcondition.

## Loops and termination

The changed function has no loop, so no circularity claim is required.
Termination is not separately proved; the source branch structure is finite for
the modeled in-domain paths.

## Test guidance

No tests were removed or edited. If test edits were allowed, the legacy public
tests for `admin.E035` should be updated to expect the invalid field value. Any
new test that asserts the invalid-branch message includes the field value is
subsumed by PO-01 only after the K commands above are machine-checked.

## Residual risk

The proof is constructed, not machine-checked. It relies on the adequacy of the
mini semantics for this narrow message-formatting behavior and on the source
audit for Django's concrete `checks.Error` construction.
