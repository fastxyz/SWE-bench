# Formal Spec English

Status: constructed for audit; not machine-checked.

K claim `CLAIM-ALIGN-GENERAL` says:

For every valid parsed Python signature AST with positional-only arguments `P`,
ordinary positional arguments `A`, and positional defaults `D`, if `D` is no
longer than `P + A`, `signature_from_str()` pads `D` on the left with empty
defaults until it is exactly as long as `P + A`. It then assigns padded default
index `i` to positional-only argument `P[i]`, and padded default index
`len(P) + j` to ordinary positional argument `A[j]`.

K claim `CLAIM-ISSUE-EXAMPLE` says:

For the parsed form of `(a, b=0, /, c=1)`, with `P=[a,b]`, `A=[c]`, and
`D=[0,1]`, the padded defaults are `[empty,0,1]`. The returned parameter
sequence gives `a` no default, `b` default `0`, and `c` default `1`.

K claim `CLAIM-NO-POSONLY-REGRESSION` says:

When there are no positional-only arguments, the same padding algorithm produces
the existing ordinary positional behavior: defaults are aligned to the final
ordinary positional parameters.

Source-level rendering obligation `CLAIM-RENDERING` says:

The Python-domain renderer shows a default when the parameter default is not
`Parameter.empty`, and it inserts `/` based on parameter kind transitions.
Therefore the parameter sequence from `CLAIM-ISSUE-EXAMPLE` produces output
containing `b=0`, `/`, and `c=1` in the expected positions.

Frame condition `FRAME-OTHER-PARAMETER-FORMS` says:

The V1 change does not alter keyword-only defaults, varargs, kwargs,
annotations, return annotations, parser exceptions, or public function
signatures.
