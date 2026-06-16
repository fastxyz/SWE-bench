# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Source decision

V1 stands unchanged. The FVK audit found no source-level problem requiring a V2 edit.

## Why no further code edit is justified

* F1 and PO1 show the root defect was the missing alias map in the recording path.
  V1 supplies that map.
* F1 and PO2 show both parameter and return annotations are handled by the existing
  post-signature recording logic once the signature is alias-aware.
* F2 and PO3 show the merge path preserves the corrected strings and does not need a
  second alias resolver.
* F3 and PO5 show no compatibility issue was introduced.

## Future verification

In an environment where execution is allowed, run the commands recorded in `PROOF.md`
and the relevant Sphinx autodoc tests. Until then, treat this as a constructed proof
and keep all tests.

## Future test to add outside this task

Add a regression covering a postponed alias with
`autodoc_typehints = 'description'` and `autodoc_type_aliases`, asserting that both
parameter and return type fields display the configured alias target.
