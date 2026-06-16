# FVK Notes

## Summary

The FVK audit did not confirm V1 unchanged. V1 fixed the exact `abc.ABC`
repro, but the full type-comment import obligation exposed two related gaps:
fully qualified `typing.*[...]` annotations could still drop nested type names,
and dotted imports could still fail to match the keys `_check_imports` compares.

## Source decisions

`repo/pylint/checkers/variables.py`

1. Kept V1's `astroid.Attribute` handling for the direct repro.
   - Trace: `fvk/FINDINGS.md` F1.
   - Obligations: PO1 and PO3 in `fvk/PROOF_OBLIGATIONS.md`.
   - Reason: `abc.ABC` must record `abc` so `_check_imports` suppresses W0611
     for `import abc`.

2. Added `_qualified_names_from_attribute`.
   - Trace: `fvk/FINDINGS.md` F3.
   - Obligation: PO4.
   - Reason: `_fix_dot_imports` can compare a dotted import key such as
     `xml.etree`, so the annotation collector must record dotted prefixes, not
     only root names.

3. Extended the `astroid.Attribute` branch to store dotted prefixes as well as
   existing `Name` nodes.
   - Trace: F1 and F3.
   - Obligations: PO1 and PO4.
   - Reason: this preserves the exact `abc.ABC` fix and covers dotted chains
     such as `xml.etree.ElementTree`.

4. Removed the early `return` from the `typing.*` subscript special case.
   - Trace: `fvk/FINDINGS.md` F2.
   - Obligations: PO2 and PO4.
   - Reason: `typing.Optional[abc.ABC]` still uses `abc` in a type comment;
     collecting `typing` must not prevent collection of nested type names.

5. Added dotted-prefix collection for `astroid.Attribute` nodes nested inside a
   subscript.
   - Trace: F2 and F3.
   - Obligations: PO2 and PO4.
   - Reason: subscript annotations must collect names from both the value and
     the argument annotations.

6. Left `_check_imports` unchanged.
   - Trace: F4 and F5.
   - Obligations: PO3 and PO5.
   - Reason: the existing predicate already encodes the desired suppression
     rule, `imported_name in _type_annotation_names or as_name in
     _type_annotation_names`; the bug was insufficient collection, not the
     downstream decision.

7. Did not modify tests and did not run tests, Python, or K tooling.
   - Trace: F5.
   - Obligations: all proof obligations remain constructed, not
     machine-checked.
   - Reason: the task forbids execution and test edits.

## Artifacts

The required FVK artifacts are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional K artifacts were written to make the FVK run more than a prose audit:

- `fvk/mini-pylint-variables.k`
- `fvk/type-annotation-import-spec.k`
