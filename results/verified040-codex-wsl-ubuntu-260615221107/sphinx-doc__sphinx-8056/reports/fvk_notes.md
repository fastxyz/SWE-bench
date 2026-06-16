# FVK Notes

## Summary

The FVK audit revised V1. V1 fixed the missing type by splitting a grouped NumPy parameter field into separate `:param:` entries, but `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` O4 show that this changed the grouped output form named in the public issue. V2 removes the Napoleon splitting approach and fixes the actual misparse in `DocFieldTransformer.transform()`.

## Decisions

1. Removed the V1 Napoleon field-splitting change.
   - Trace: F1 says V1 would render separate `x1` and `x2` parameter entries instead of preserving the grouped `x1, x2` form.
   - Obligation: O4 treats Napoleon's grouped `:param x1, x2:` / `:type x1, x2:` output as a frame condition.
   - Result: `repo/sphinx/ext/napoleon/docstring.py` stands unchanged from the pre-V1 implementation.

2. Added a narrow guard in `repo/sphinx/util/docfields.py`.
   - Trace: F2 identifies the root cause: the inline `:param type name:` support split `x1, x2` into synthetic type `x1,` and name `x2`, preventing the explicit `:type x1, x2:` field from matching.
   - Obligations: O1 requires comma-separated names not to be treated as inline types; O2 requires exact key matching so `array_like, optional` attaches.
   - Change: the inline shorthand rewrite now runs only when `not argtype.endswith(',')`.

3. Preserved documented inline typed-field syntax.
   - Trace: F3 identifies `:param str sender:` as public documented behavior that must remain.
   - Obligation: O3 requires single-word inline types to keep working.
   - Result: the guard only blocks comma-terminated first tokens; `str` still enters the existing shorthand branch.

4. Did not run tests, Python, or K tools.
   - Trace: F4 records the execution boundary.
   - Obligation: O5 requires the proof to be labeled constructed, not machine-checked, and forbids test edits/removal in this phase.
   - Result: `fvk/PROOF.md` lists future `kompile`, `kast`, and `kprove` commands, but no commands were executed.

## Artifacts

The required FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal core referenced by those artifacts:

- `fvk/mini-docfields.k`
- `fvk/docfield-transformer-spec.k`
