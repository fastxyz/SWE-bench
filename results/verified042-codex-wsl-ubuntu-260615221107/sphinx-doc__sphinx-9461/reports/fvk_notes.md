# FVK Notes

## Source Change Made During FVK

Changed `repo/sphinx/ext/autodoc/importer.py` in the enum branch of
`get_object_members()`:

- Before: `value = safe_getattr(subject, name)`
- After: `value = get_class_member(subject, name, safe_getattr)`

Reason: `fvk/FINDINGS.md` F1 identified that V1 left this class-member
enumeration branch outside the helper invariant. `fvk/PROOF_OBLIGATIONS.md`
PO-4 requires all audited class-member retrieval paths to use
`get_class_member()`, including enum-specific paths. The edit is a narrow
consistency fix and does not change function signatures.

## V1 Decisions Kept

Kept the `get_class_member()` helper design from V1.

Reason: F2 and PO-1 show that the helper reads the raw class dictionary before
normal attribute access and returns the wrapped `property` for the exact
`classmethod(property(...))` shape. PO-2 shows non-wrapper members keep the
original attrgetter fallback, preserving ordinary properties, methods,
descriptors, and custom attrgetter behavior.

Kept the MRO-first, stop-at-first-definition behavior.

Reason: F3 and PO-3 show this preserves Python override precedence. A subclass
member with the same name is not replaced by an inherited class property.

Kept `PropertyDocumenter.import_object()` from V1.

Reason: F2 and PO-5 show classification alone is insufficient because
`PropertyDocumenter` imports the member again before rendering. Reapplying
`get_class_member()` after a successful class-parent import ensures docstring,
abstractness, and type extraction use the property object.

Kept existing `PropertyDocumenter` rendering behavior.

Reason: F4 and PO-6 show the existing property renderer already handles
property classification, getter docstrings, abstract properties, and return type
metadata once `self.object` is the wrapped property. Adding a new domain option
or directive type is not justified by the public issue.

Did not change autosummary module scanning.

Reason: F5 distinguishes autosummary generated class content from module-member
scanning. The issue concerns class members, and the class-content path calls
`sphinx.ext.autodoc.get_class_members()`, which is covered by PO-4. Changing
module scanning would broaden the patch without a public-intent obligation.

Did not add tests or run verification commands.

Reason: F6 records the task restriction: no tests, Python execution, or K
tooling may be run, and test files must not be modified. `fvk/PROOF.md` includes
the commands that should be run later in an environment that supports them.

## Artifact Trace

- `fvk/SPEC.md` defines the public intent ledger and contracts C1-C6.
- `fvk/FINDINGS.md` records the V1 audit result, the V2 source change, and the
  decisions to keep the remaining V1 structure.
- `fvk/PROOF_OBLIGATIONS.md` names PO-1 through PO-6 and sketches the formal
  claims.
- `fvk/PROOF.md` constructs the proof and records non-executed K commands.
- `fvk/ITERATION_GUIDANCE.md` summarizes the final recommendation: V2 is the
  V1 architecture plus the enum-branch consistency fix.

All proof claims remain constructed, not machine-checked.
