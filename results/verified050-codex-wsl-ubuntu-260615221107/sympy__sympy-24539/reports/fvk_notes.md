# FVK Notes

The FVK audit confirms V1 should stand unchanged. Finding F-1 identifies the
real bug as the same-arity supplied-symbol tuple being overwritten before
`expr_from_dict`; proof obligations PO-2 and PO-4 show V1 fixes that by
preserving the caller's tuple and by relying on `expr_from_dict`'s positional
use of its `gens` argument.

I made no additional source edits. PO-1 confirms the no-symbol default remains
unchanged, PO-3 confirms wrong arity still raises `ValueError`, PO-5 confirms
`FracElement.as_expr` composes with the `PolyElement` fix without wrapper
changes, and PO-6 confirms the public signature and call convention are
unchanged.

Finding F-2 is a test coverage gap, not a source defect: the visible tests use
replacement symbols with the same names as the ring symbols, so they do not
distinguish the pre-fix bug. The task forbids modifying tests, so this remains
future guidance only. Finding F-3 notes the old wrong-arity message is imprecise
for too many symbols, but PO-3 intentionally specifies only the public intent
that wrong arity raises an error; changing the message would be unrelated API
polish.

No tests, Python commands, or K tooling were run. The K artifacts and proof are
constructed and include the commands that would be run later in an environment
with K installed.
