# FVK Notes

## Decision Summary

The V1 code behavior stands. The FVK audit found that V1 satisfies the functional obligations for explicit `private-members` selection, but it also found that the public autodoc documentation still described `private-members` as only a flag. V2 therefore adds a documentation update in `repo/doc/usage/extensions/autodoc.rst`.

## Code Decision: Keep V1 Behavior

I kept the V1 source-code behavior in `repo/sphinx/ext/autodoc/__init__.py` unchanged during the FVK pass.

Trace:

- `fvk/PROOF_OBLIGATIONS.md` PO-1 through PO-3 require `private-members` to use list-capable parsing for module and class documenters. V1 already does this by registering `private-members` with `members_option`.
- PO-4 through PO-6 require explicit private names to merge like explicit member requests while preserving `members is ALL`. V1 already does this through `merge_private_members_option()` and `merge_members_option()`.
- PO-7 and PO-8 require selected-private filtering to distinguish finite lists from bare all-private selection. V1 already does this through `has_member_name(self.options.private_members, membername)`.
- PO-9 through PO-11 require existing skip/documentation behavior to remain intact. V1 preserved branch order for mocked objects, `exclude-members`, explicit members, and source-documented attributes.
- `fvk/FINDINGS.md` F-001 is marked fixed by V1/V2, and the proof-derived findings section identifies no remaining blocking code bug.

## Documentation Change

Changed `repo/doc/usage/extensions/autodoc.rst`.

Trace:

- `fvk/FINDINGS.md` F-002 records the V1 documentation mismatch: public docs still called `private-members` a flag option and did not mention explicit list arguments.
- `fvk/PROOF_OBLIGATIONS.md` PO-12 requires the docs to describe list arguments for `private-members`.
- `fvk/SPEC.md` I10 treats public docs as part of the user-facing contract.

Change made:

- Reworded the private-members bullet to call it an option rather than only a flag option.
- Added that it can take an explicit list of private member names.
- Added `'private-members': '_private'` to the `autodoc_default_options` example.

## Compatibility Decision

No public API or override repair was needed.

Trace:

- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no changed method signatures, no new virtual dispatch arguments, and no public subclass/override break.
- `fvk/PROOF_OBLIGATIONS.md` PO-13 is discharged for documented option values.

## Verification Status

The proof is constructed, not machine-checked.

Trace:

- `fvk/FINDINGS.md` F-003 records that K commands were not run because this task forbids execution.
- `fvk/PROOF.md` lists the exact `kompile`, `kast`, and `kprove` commands to run later.
- No tests were run and no test files were modified.
