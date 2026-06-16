# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decisions

1. Kept the V1 placement of the fix in `object_description()`.
   - Trace: `fvk/FINDINGS.md` F-01 identifies the root cause as the
     `stringify_signature()` -> `object_description()` path.
   - Obligations: PO-02 requires named enum member formatting, and PO-03
     requires signature propagation through the existing callsite.
   - Reason: centralizing the branch in `object_description()` fixes the
     signature default path without changing autodoc documenter APIs.

2. Revised the V1 enum branch for `enum.Flag` and nameless enum values.
   - Trace: F-02 shows V1 would format a flag combination as
     `Perm.READ|WRITE` and a nameless enum value as `Perm.None`.
   - Obligations: PO-05 requires qualifying flag components and forbids
     inventing `Class.None`.
   - Change: `repo/sphinx/util/inspect.py` now checks `enum_name is not None`,
     qualifies each pipe-separated flag component, and otherwise falls through
     to the existing repr path.

3. Kept non-enum formatting unchanged.
   - Trace: F-03 records the frame condition for non-enum defaults.
   - Obligations: PO-04 requires preserving dict, set, frozenset, generic repr,
     memory-address stripping, and newline replacement behavior.
   - Reason: the source edit only adds/adjusts an enum branch before the
     existing branches; it does not alter those paths.

4. Did not add special handling for custom enum `__repr__`.
   - Trace: F-04 marks this as ambiguous public intent.
   - Obligations: PO-01 and PO-02 are anchored to the issue's expected
     `EnumClass.Member` output; PO-06 guards public compatibility but does not
     require preserving custom enum repr.
   - Reason: honoring custom enum repr would weaken the public requirement that
     enum defaults render as member references.

5. Did not broaden the patch to list or tuple defaults containing enum values.
   - Trace: F-05 records this as a residual scope note.
   - Obligations: PO-04 frames existing non-enum container behavior; PO-07
     prevents overstating proof coverage.
   - Reason: the reported and proven behavior is a direct enum default in a
     function signature. A broader recursive container change would affect a
     larger formatting surface without direct public evidence in this issue.

6. Added FVK artifacts, adequacy files, and supporting K files under `fvk/`.
   - Trace: FVK methodology requires an intent ledger, findings, proof
     obligations, proof, iteration guidance, and a formal core.
   - Obligations: PO-01 covers intent adequacy; PO-07 covers honesty about not
     running the proof.
   - Reason: the artifacts justify the V2 source refinement and label the proof
     as constructed, not machine-checked.

## Summary

The V2 source change is limited to `repo/sphinx/util/inspect.py`. It preserves
V1's fix for named enum members and tightens the new enum branch so it does not
emit invalid member-reference text for flag combinations or nameless enum
values.
