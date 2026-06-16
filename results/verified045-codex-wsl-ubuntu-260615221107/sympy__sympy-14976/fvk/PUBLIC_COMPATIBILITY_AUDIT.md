# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Surface

The V1 source change adds an override method:

```text
MpmathPrinter._print_Rational(self, e)
```

It does not change a public function signature, class constructor signature, return type protocol, or callsite argument list.

## Callsite and Override Audit

| Symbol / Path | Compatibility Result | Reason |
| --- | --- | --- |
| `lambdify(..., modules='mpmath')` default printer construction | PASS | Still constructs `MpmathPrinter` with the same settings; the new method is reached by normal printer dispatch for `Rational`. |
| `MpmathPrinter._print_Float` | PASS | Unchanged; `_print_Rational` reuses the same `_module_format('mpmath.mpf')` convention. |
| Other subclasses of `PythonCodePrinter` | PASS | Method added only to `MpmathPrinter`; no base-class signature changed. |
| Custom user printer passed to `lambdify(..., printer=...)` | PASS | Custom printer bypass behavior is unchanged. |
| Non-mpmath modules (`numpy`, `scipy`, `math`, `sympy`, `tensorflow`, `numexpr`) | PASS | Printer selection and rational printing remain unchanged for those backends. |

No unhandled public callsite or subclass override was found in the audited source path.
