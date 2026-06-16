# Proof Obligations

Status: constructed, not machine-checked.

## O1 - Comma-Separated Parameter Names Are Not Inline Types

For any typed field argument whose first whitespace-delimited token ends with a comma, transformation must not apply the `:param type name:` shorthand. The parameter key must remain the original comma-separated argument text.

Evidence: E1, E2, E4.

Formal claim: C1 in `fvk/docfield-transformer-spec.k`.

## O2 - Explicit Type Fields Attach by Exact Key

For `:param x1, x2:` paired with `:type x1, x2: array_like, optional`, the transformed parameter key and explicit type key must both be `x1, x2`, so the rendered parameter entry includes `array_like, optional`.

Evidence: E2, E3, E4.

Formal claim: C2 in `fvk/docfield-transformer-spec.k`.

## O3 - Single-Word Inline Typed Syntax Is Preserved

For documented forms such as `:param str sender:`, transformation must still rewrite the parameter key to `sender` and record `str` as its type.

Evidence: E5.

Formal claim: C3 in `fvk/docfield-transformer-spec.k`.

## O4 - Napoleon Formatting Is a Frame Condition

Napoleon's parsed field output for the issue case should remain the grouped docutils pair `:param x1, x2:` and `:type x1, x2:`. Fixing the renderer should not require duplicating the description into separate parameter entries.

Evidence: E4 and source lines in `repo/sphinx/ext/napoleon/docstring.py`.

Formal claim: C4 plus the compatibility audit in `fvk/SPEC.md`.

## O5 - Honesty Gate

Because no execution is allowed, the proof must be reported as constructed, not machine-checked, and tests must not be modified or recommended for removal without a future `kprove` run.

Evidence: task constraints and FVK verify guidance.

Formal status: documented in `fvk/PROOF.md`.
