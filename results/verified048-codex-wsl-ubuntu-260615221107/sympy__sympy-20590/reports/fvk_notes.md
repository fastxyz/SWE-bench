# FVK Notes

## Decisions

V1 source code stands unchanged. `fvk/FINDINGS.md` F-001 and F-002 identify the
regressed behavior as an inherited instance dictionary on `Symbol`, and
`fvk/PROOF_OBLIGATIONS.md` PO-003 and PO-004 show the correct source target is
`Printable`, not a separate `DefaultPrinting` class. V1 already adds
`__slots__ = ()` to `Printable`.

No additional `Symbol`-specific edit was made. F-004 and PO-005 show the other
classes on the modeled `Symbol` inheritance path already define slots, so a
special case in `Symbol` would be redundant and less targeted.

No broader removal or refactor of `__slots__` was made. PO-008 records that the
minimal repair is to restore empty slots on the parent mixin that introduced the
dictionary; removing slots from core classes would contradict the intent in
F-001.

No compatibility shim was added. F-003 and PO-006 show subclasses that omit
`__slots__` still receive their own dictionaries under the Python layout rule,
so the public compatibility concern does not require another source change.

The FVK package includes `fvk/mini-python-slots.k` and
`fvk/symbol-slots-spec.k` in addition to the five requested Markdown artifacts.
This follows PO-002 and PO-009: the proof needs a property-complete formal core,
but this environment only permits constructing and documenting it, not running
K.

No tests, Python imports, or K commands were run. This is required by PO-009 and
recorded as F-005. The commands appear in `fvk/PROOF.md` and
`fvk/ITERATION_GUIDANCE.md` as future verification steps only.

## Outcome

The FVK audit confirms V1 as the final source fix. The formalized claim is that
`hasInstanceDict(Symbol)` is false after `Printable` receives empty slots, while
an unslotted subclass of the printing mixin still has its own dictionary. Those
claims match the public issue intent and justify leaving the source unchanged.
