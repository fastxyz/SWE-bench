# FVK Spec

Status: constructed, not machine-checked. No tests, Python, Ruff, `kompile`, or `kprove` were run.

## Intent-Only Spec

The public issue requires SIM201 and SIM202 fixes to be unsafe by default because Python `__eq__` and `__ne__` can return arbitrary objects. The same issue preserves a safe-fix exception when both operands are known to be types whose equality and inequality comparisons return `bool`.

The intended observable for this audit is the fix applicability attached to the existing SIM201 and SIM202 replacement edits:

- `Safe` exactly when both operands are recognized as bool-comparison-safe by public/static evidence available to Ruff.
- `Unsafe` otherwise, including unknown names, unknown calls, ambiguous bindings, and the reported `np.array(...)` bindings.
- Diagnostic detection, replacement text, dunder-method suppression, and exception-check suppression are frame conditions and must remain unchanged from the pre-FVK V1 patch.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | prompt issue | "SIM201 and SIM202 fixes should be marked unsafe" | The default applicability for these rules is unsafe. |
| E-002 | prompt issue | "`__eq__` and `__ne__` may return any type, not just `bool`" | Unknown/user/third-party operands cannot receive a default safe fix. |
| E-003 | prompt issue | "fixes are still safe when the operands are of types whose `__eq__` and `__ne__` are known to return `bool`" | A safe fix is permitted when both operands are known bool-comparison operands. |
| E-004 | prompt example | `a = np.array([0])`, `b = np.array([1])` changes behavior after `--fix` | A name bound to `np.array(...)` is not safe-fix evidence. |
| E-005 | source comments/rule names | SIM201/SIM202 are readability rewrites only | Lint emission and replacement text should remain unchanged; only applicability changes. |
| E-006 | implementation evidence | `typing::find_binding_value` can expose assignment initializers | If a binding has an initializer, its runtime expression is stronger evidence than an annotation-only helper result. |

## Formal Model

The mini K model is intentionally small and property-complete for this issue. It abstracts Ruff operand analysis to `Evidence` values:

- `directKnown`: direct expression type inference says the expression is a simple built-in type with bool-returning comparison.
- `builtinKnown`: the expression is a known built-in constructor call returning such a type.
- `semanticKnown`: existing Ruff semantic helpers know the binding is a built-in numeric/container value without a contradicting initializer.
- `bindingValueKnown`: a name binding has an initializer that itself is known safe.
- `unknownName`, `unknownCall`, `ambiguousBinding`: Ruff cannot prove bool-returning equality/inequality.

The formal contract is in `fvk/sim20-fix-spec.k`, using the semantics in `fvk/mini-fix-applicability.k`:

```text
fixApplicability(rule, left, right) = safe   iff known(left) and known(right)
fixApplicability(rule, left, right) = unsafe otherwise
```

## Adequacy Audit

The English meaning of the K claims matches the intent:

- The safe claim encodes E-003 and is not derived from V1 behavior.
- The unsafe claim encodes E-001 and E-002.
- The NumPy claim encodes E-004 directly.
- The initializer-precedence claim encodes FVK finding F-003 and proof obligation PO-004; it prevents an annotation from hiding an unknown initializer.

No public API signature, diagnostic message, or replacement text changed. No public tests were modified.
