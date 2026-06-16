# Formal Spec English

Status: constructed, not machine-checked.

The K model abstracts `_constraint_names()` as the already-filtered candidate
list. For the production code, that list is filtered by columns, uniqueness,
`primary_key=False` for `unique_together` deletion, and explicit
constraint/index exclusions.

K-UT-DEFAULT-FIRST. If unique deletion has multiple candidates and the
generated `_uniq` name is the first candidate, the selection result is
`delete(generated_name)`.

K-UT-DEFAULT-SECOND. If unique deletion has multiple candidates and the
generated `_uniq` name is a later candidate, the selection result is
`delete(generated_name)`.

K-UT-SINGLE. If unique deletion has exactly one candidate, the selection result
is `delete(that_candidate)`.

K-UT-AMBIGUOUS. If unique deletion has multiple candidates and none is the
generated `_uniq` name, the selection result is `raise`.

K-NONUNIQUE-AMBIGUOUS. If the operation is not unique deletion and it has
multiple candidates, the selection result is `raise`; the `_uniq` preference is
not applied to non-unique composed index deletion.

K-NONE. If no candidate remains after filtering, the selection result is
`raise`.

Frame condition. The model does not change candidate filtering itself; it
models only the post-filter disambiguation step. The production proof obligation
for filtering is carried in `PROOF_OBLIGATIONS.md` O1/O2/O6.
