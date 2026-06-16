# Formal Spec English

Status: paraphrase of the K claims; constructed, not machine-checked.

## Claim `META-PUBLIC-VARIABLE`

For a member whose name starts with `_`, whose source attribute documentation is present and contains `public` metadata, and where no earlier skip branch applies, all-members filtering keeps the member and marks it as an attribute.

## Claim `META-PRIVATE-VARIABLE`

For a member whose name does not start with `_`, whose source attribute documentation is present and contains `private` metadata, and where no earlier skip branch applies, all-members filtering skips the member when `:private-members:` does not admit it.

## Claim `ATTR-VISIBILITY-PRECEDENCE`

For a member whose runtime docstring metadata says `private` but whose source attribute documentation metadata says `public`, all-members filtering keeps the member and marks it as an attribute. This models attribute comments as the effective documentation source for variable documentation.

## Claim `DOCSTRING-PUBLIC-FRAME`

For a member with no visibility marker in its source attribute documentation, existing runtime-docstring `public` metadata still makes a private-looking member public, and the documented-attribute branch keeps it as an attribute.

## Frame Side Conditions

The formal claims assume the normal issue path: the member is not mocked, not excluded, not special, and not force-skipped by `__all__` filtering; no user event handler overrides the result. These are not weakened expectations of the issue but inherited earlier branches and extension hooks outside the reported setup.
