# FVK Notes

## Decisions and Traceability

V1's semantic fix stands: cyclic list input is no longer rejected just because elements repeat across cycles. This is justified by F-1 and proof obligations PO-1 through PO-4.

I made one source-code refinement in V2: the duplicate check is now written as `if not is_cycle and has_dups(temp):`. This is behaviorally equivalent to V1 for the issue, but it directly encodes PO-2 by making the repeated-elements error an array-form-only branch.

I added a doc example for `Permutation([[0, 1], [0, 1]])`. This documents the concrete issue obligation PO-4 and prevents the constructor documentation from continuing to imply that list-of-lists cycles must be globally disjoint.

I kept array-form duplicate rejection unchanged. F-3 and PO-5 require `Permutation([1, 1, 0])`-style input to remain invalid because array form is still a one-to-one image list.

I kept per-cycle validation unchanged. F-4 and PO-7 require invalid individual cycles, such as a single cycle with repeated elements, to continue flowing through `Cycle(*ci)` validation.

I did not modify public tests. F-2 marks the legacy `Permutation([[1], [1, 2]])` raises expectation as SUSPECT under FVK because it conflicts with the issue's explicit non-disjoint-cycle requirement, but the task forbids test edits.

## Verification Status

The FVK proof package is constructed, not machine-checked. F-5 and PO-8 record the environment limitation and the emitted commands needed for a future K run.
