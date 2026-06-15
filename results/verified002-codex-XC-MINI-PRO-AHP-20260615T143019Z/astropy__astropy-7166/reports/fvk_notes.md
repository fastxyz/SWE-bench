# FVK Notes

## Decisions

- Kept V1's core fix because `fvk/FINDINGS.md` F-02 and
  `fvk/PROOF_OBLIGATIONS.md` PO-01 through PO-06 show that data-descriptor
  eligibility, static descriptor lookup, MRO precedence, explicit-doc framing,
  and public API compatibility match the issue intent.
- Revised V1 with one guarded-assignment change because F-01 and PO-07 show a
  V1 compatibility risk: after using `inspect.isdatadescriptor`, a descriptor
  with a read-only `__doc__` could abort class creation. V2 catches
  `AttributeError` and `TypeError` and leaves that descriptor unchanged.
- Made no test changes. F-05 and PO-10 record that this audit is constructed,
  not machine-checked, and the task forbids modifying tests.

## Files Changed

- `repo/astropy/utils/misc.py`
  - Added `try/except (AttributeError, TypeError)` around inherited docstring
    assignment in `InheritDocstrings.__init__`.
  - This change is traced to F-01 and PO-07.

## Files Added

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-inherit-docstrings.k`
- `fvk/inherit-docstrings-spec.k`
- `reports/fvk_notes.md`

## Residual Assumptions

- The proof models only the observable behavior under audit: docstring
  inheritance for functions and data descriptors during metaclass initialization.
- The proof is constructed only; no tests or K tooling were run.
