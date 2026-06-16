# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the one-line source change is the
minimal intent-aligned fix: remove automatic object-reference generation from
Python variable field labels while preserving variable type links and explicit
roles.

## Why No Further Source Change Is Recommended

- A resolver-only change would not satisfy the same-module case described in
  the issue.
- Changing variable fields to `attr` links would still treat the field label as
  an implicit reference and could still resolve to unrelated class attributes.
- Removing the variable field `rolename` matches both the bug report and public
  docs: variable fields are descriptions; `vartype` is the documented linkable
  part.
- Public APIs and explicit-role behavior are unchanged.

## Future Work if Execution Is Available

When tests or tooling are allowed, run focused Sphinx doctree/HTML tests for the
cases listed in `PROOF.md`. Separately, a full K verification would run:

```sh
cd fvk
kompile mini-sphinx-fields.k --backend haskell
kast --backend haskell sphinx-fields-spec.k
kprove sphinx-fields-spec.k
```

Do not remove existing tests based on this constructed proof alone.
