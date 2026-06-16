# Intent Spec

Constructed from public evidence only.

1. `mathematica_code` must emit valid Mathematica function-call syntax for a
   SymPy `Max` expression that remains unevaluated. The issue gives
   `mathematica_code(Max(x, 2))` and says the expected form is `Max[...]`, while
   the observed `Max(...)` is invalid Mathematica code.

2. The same obligation applies to the homogeneous `Min` sibling. The public hint
   explicitly identifies both Mathematica `Max` and `Min` as missing from the
   relevant function handling discussion.

3. Existing Mathematica printer behavior for ordinary function calls remains in
   scope as a frame condition: public tests expect calls such as `f[x, y, z]`,
   `Sin[x]`, and `Conjugate[x]`.

4. The intent does not require preserving the source-code argument order from
   `Max(x, 2)`. SymPy constructs and canonicalizes the expression before the
   printer receives it; the issue's observed output already shows canonical
   order as `Max(2, x)`. The printer obligation is therefore over `expr.args`.

5. Whitespace after commas is not the defect. Existing Mathematica printer tests
   use `", "` between arguments, so the specified output shape is square brackets
   around the printer's normal comma-separated argument rendering.

6. Python's built-in lowercase `max` is outside the repair domain. The public
   hint clarifies that lowercase `max` tries to compare arguments directly and is
   not the SymPy unevaluated `Max` expression.
