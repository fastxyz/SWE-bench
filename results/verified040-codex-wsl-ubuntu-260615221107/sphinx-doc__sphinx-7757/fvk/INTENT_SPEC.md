# Intent Spec

Status: constructed for audit; not machine-checked.

## Scope

This FVK pass audits the V1 fix for the changed behavior surface:

- `sphinx.util.inspect.signature_from_str()`
- `sphinx.domains.python._parse_arglist()` as the public renderer that consumes
  the resulting `inspect.Signature`

The rest of Sphinx is outside this repair-focused FVK scope.

## Intent-Only Obligations

I1. A manually documented Python signature using positional-only syntax must
preserve and display default values for positional-only parameters.

Evidence: `benchmark/PROBLEM.md` says "The default value for positional only
argument has vanished" and gives `.. py:function:: foo(a, b=0, /, c=1)` with
expected behavior "The default value is shown."

I2. The `/` positional-only separator must remain a separator, not a parameter
that absorbs or hides neighboring defaults.

Evidence: the issue example includes `/` only to mark positional-only arguments;
the expected behavior mentions the default value, not a changed separator.

I3. Existing non-positional-only default handling must be preserved.

Evidence: `signature_from_str()` already documents a general "Create a Signature
object from string" contract, and existing visible tests under
`repo/tests/test_util_inspect.py` assert defaults for ordinary and keyword-only
parameters.

I4. The intended input domain is Python signatures accepted by the parser used by
`signature_from_str()`. Invalid signatures may continue to raise parser errors.

Evidence: the helper is implemented by parsing `def func<signature>: pass`, and
visible tests assert invalid empty input raises `SyntaxError`.

I5. The source-level public API must remain compatible: no signature change for
`signature_from_str()` or `_parse_arglist()`.

Evidence: the issue requests a rendering fix, not a new API; visible callsites
import and call `signature_from_str(signature)` and `_parse_arglist(arglist)`.
