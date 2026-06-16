# Spec Audit

Status: adequacy comparison between `INTENT_SPEC.md` and `FORMAL_SPEC_ENGLISH.md`.

## C-1

Formal English: omitted `element_id` returns a no-ID JSON script tag.

Intent coverage: `INT-1`, `INT-2`, `INT-3`, `INT-5`.

Verdict: pass.

## C-2

Formal English: `element_id=None` returns the no-ID JSON script tag.

Intent coverage: `INT-1`, `INT-2`; default-domain convention that Python optional parameters often use `None` as the absent value.

Verdict: pass.

## C-3

Formal English: non-`None` `element_id` returns the existing escaped ID-bearing JSON script tag.

Intent coverage: `INT-3`, `INT-4`, `INT-5`, `INT-6`.

Verdict: pass.

## C-4

Formal English: template filter delegates to the utility helper.

Intent coverage: `INT-1`, `INT-2`, `INT-4`, `INT-5`.

Verdict: pass.

## Static Argument Validation

Formal English: the template filter accepts zero or one explicit filter arguments after V1.

Intent coverage: `INT-1`.

Verdict: pass.

## AMB-1

Formal English: explicit empty string is not assigned an intent-derived required output.

Intent coverage: none.

Verdict: ambiguous, non-blocking. This case is recorded in `F-03` and is not used to justify V1's correctness for the omitted-argument path.
