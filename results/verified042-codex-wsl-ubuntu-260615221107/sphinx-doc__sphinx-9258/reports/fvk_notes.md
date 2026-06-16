# FVK Notes

## Decision summary

V1 stands unchanged.  The FVK audit found that the existing edit in
`repo/sphinx/domains/python.py` discharges the public pipe-union obligation and
does not create a source-level need for a V2 edit.

## Decisions traced to findings and obligations

Kept the V1 delimiter-regex edit:
`fvk/FINDINGS.md` F-1 identifies the original defect as treating
`bytes | str` as one target, and `fvk/PROOF_OBLIGATIONS.md` PO-1 requires the
pipe-separated expression to produce two type xrefs with literal pipe text.
The V1 regex alternative `\s*\|\s*` is the direct source change that discharges
that obligation.  PO-3 confirms type atoms still go through the existing
cross-reference construction path.

Made no extra field-specific source edits:
F-2 concludes there is no remaining source gap for the requested Python field
family.  PO-5 covers separate `:type:` parameter fields, PO-6 covers inline
`:param type name:` fields, and PO-7 covers `:vartype:` and `:rtype:` fields.
Those obligations all route through the same `PyXrefMixin.make_xrefs()` method
already changed by V1.

Made no `PyAttribute` edit:
F-3 records that attribute directive `:type:` options already use
`_parse_annotation()`.  PO-8 ties that decision to the existing `ast.BitOr`
handling in the Python annotation parser.  Variable and instance-variable field
lists remain covered by PO-7.

Did not move the change into generic docfield code:
F-4 says the compatibility frame holds.  PO-10 requires avoiding non-Python
domain behavior changes, and PO-4 requires preserving the existing delimiter
families.  Keeping the edit in `PyXrefMixin` satisfies those obligations with a
minimal Python-domain-only change.

Did not implement a full quote-aware type parser:
F-5 records the residual parser limitation and classifies it as outside this
issue.  The public intent requires delimiter-based linking for pipe unions, not
a replacement parser for all Python typing syntax inside field-list text.

Did not modify tests and did not run tests, Python, or K:
F-6 and PO-11 are the honesty gate.  The proof is constructed, not
machine-checked, and test removal is not justified.  This also follows the
benchmark instruction that no tests or code be run and no test files be edited.

Added FVK artifacts:
The five requested markdown artifacts are present under `fvk/`.  I also added
`fvk/mini-python-xrefs.k` and `fvk/python-xrefs-spec.k` because the FVK method
requires a formal core in addition to prose.  PO-11 and F-6 label those artifacts
as constructed only; the corresponding commands are recorded in `fvk/PROOF.md`
but were not executed.
