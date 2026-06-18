# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

`LatexPrinter._print_Subs` in `repo/sympy/printing/latex.py`.

## Signature and dispatch

The method signature remains `def _print_Subs(self, subs)`. No public function
signature, return type category, or virtual dispatch protocol changes.

## Callers and overrides

The LaTeX printer dispatch still calls `_print_Subs` through the existing
printer mechanism. The audit found no new argument passed to an overridable
method and no changed helper signature.

Other printers, including `sympy/printing/pretty/pretty.py` and
`sympy/printing/str.py`, have separate `_print_Subs` implementations and are not
modified by V1.

## Behavioral compatibility

Intended behavior change:

- Low-precedence/additive `Subs` expressions now gain parentheses before the
  substitution bar.

Preserved behavior in the audited fragment:

- Multiplicative `Subs` expressions such as `Subs(x*y, ...)` remain unwrapped.
- The substitution assignment suffix is still generated from the same `old` and
  `new` pairs.

## Findings

No unhandled public callsite, override, producer-consumer mismatch, or API
compatibility blocker was found.
