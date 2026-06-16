# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent and static source reasoning only.

## F1 - V1 Did Not Preserve the Grouped Output Form

Input: NumPy parameter field `x1, x2 : array_like, optional`.

Observed in V1: Napoleon would emit separate docutils fields for `x1` and `x2`, each with the same description and type.

Expected: The prompt's expected output shows the grouped name `x1, x2` together with `array_like, optional`.

Classification: code bug in V1 relative to full intent.

Resolution: V2 removes the Napoleon splitting hook and preserves Napoleon's grouped `:param x1, x2:` / `:type x1, x2:` output.

Related obligations: O1, O2, O4.

## F2 - Root Cause Was the Inline Typed-Field Shorthand Overmatching

Input: docutils parameter field argument `x1, x2`.

Observed pre-fix mechanism: `DocFieldTransformer.transform()` supports `:param type name:` by splitting field arguments on whitespace. For `x1, x2`, that branch reads `argtype = "x1,"` and `argname = "x2"`, then stores a synthetic type for `x2`. The explicit type field remains keyed by `x1, x2`, so it cannot attach to the rewritten parameter key.

Expected: `x1, x2` is a comma-separated parameter-name list. It should remain the parameter key so the explicit `:type x1, x2:` entry can match.

Classification: code bug.

Resolution: V2 adds `if not argtype.endswith(','):` before applying the inline shorthand rewrite.

Related obligations: O1, O2.

## F3 - Documented Inline Typed Parameters Must Remain Supported

Input: reStructuredText field `:param str sender:`.

Observed risk: A broad fix that disables the inline shorthand whenever a field argument contains whitespace would break documented Sphinx behavior.

Expected: The first token `str` does not end with a comma, so the shorthand remains active and records type `str` for parameter `sender`.

Classification: compatibility obligation.

Resolution: V2 only blocks comma-terminated first tokens and leaves `:param str sender:` unchanged.

Related obligations: O3.

## F4 - Verification Capability and Execution Boundary

Input: final V2 patch.

Observed: This workspace forbids running tests, Python, or K tooling.

Expected: Artifacts must state the proof is constructed, not machine-checked, and list the commands for later checking.

Classification: proof capability gap, not a code bug.

Resolution: `PROOF.md` lists the commands and keeps test-removal recommendations conditional on machine-checking.

Related obligations: O5.
