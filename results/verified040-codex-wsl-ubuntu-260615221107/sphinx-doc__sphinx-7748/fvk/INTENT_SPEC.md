# Intent Specification

This file records public intent before accepting candidate behavior.

1. `autodoc_docstring_signature` should support SWIG-style overloaded methods
   whose docstrings begin with one signature line per overload.
2. It should pick up all of those leading overload signatures, not just the
   first.
3. It should preserve the overload order from the docstring.
4. It should remove the consumed signature lines from the emitted docstring
   content.
5. Existing single-signature behavior remains valid.
6. Existing validity checks remain valid: only lines parsed as signatures for
   the documented object are extracted.
7. Signatures outside the leading block are not part of the public request and
   should remain docstring content.
8. Explicit directive signatures should continue to override docstring-derived
   signatures.
9. Attribute/property strip-only documenters should continue stripping signature
   text without adding an emitted function signature.

Observed candidate behavior was checked only after this intent list was fixed.
