# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 source change in `repo/sympy/core/evalf.py`: the
generic internal `evalf(x, prec, options)` fallback used when `x.func` has no
entry in `evalf_table`. The observable issue is reached through `evalf_mul`
when an unevaluable symbolic factor such as `Max(0, y)` appears before a
symbol in an unevaluated `Mul`.

No loops are involved in the changed code path. The proof is therefore a
branch/exception-safety proof over the fallback classifier, plus a call-path
argument for public `EvalfMixin.evalf`.

## Public Intent Ledger

INT-1

- Source: prompt.
- Evidence: "`Mul(Max(0, y), x, evaluate=False).evalf()`" raises
  "`UnboundLocalError: local variable 'reprec' referenced before assignment`".
- Obligation: the reported in-domain expression must not crash from an
  uninitialized local variable.
- Status: encoded by PO1, PO2, PO4, and K claims for `fallback(sym, zero)` and
  `fallback(zero, sym)`.

INT-2

- Source: prompt.
- Evidence: "`Mul(x, Max(0, y), evaluate=False).evalf()`" returns
  "`x*Max(0, y)`"; the reversed argument order is the crashing case.
- Obligation: unevaluable symbolic factors should be preserved symbolically,
  and this behavior must not depend on multiplication argument order.
- Status: encoded by PO4 and PO5.

INT-3

- Source: prompt.
- Evidence: "Based on the code, I think the elif clauses that define reprec
  and imprec should have an `else: raise NotImplementedError`."
- Obligation: a nonzero component that is not numeric should leave the internal
  numeric evalf path.
- Status: encoded by PO2 and PO6.

INT-4

- Source: prompt hint.
- Evidence: "Is the correct fix to set the prec to None or to raise
  NotImplementedError? I thought prec=None meant the number was an exact zero."
- Obligation: distinguish exact-zero sentinels from symbolic nonnumeric
  components; do not use `prec=None` to validate a symbolic value.
- Status: encoded by PO1, PO2, and PO6.

INT-5

- Source: code comment in `repo/sympy/core/evalf.py`.
- Evidence: "re and im are nonzero mpf value tuples representing approximate
  numbers, or None to denote exact zeros."
- Obligation: any successful internal evalf tuple must place only mpf tuples or
  `None` in the real/imaginary component slots.
- Status: encoded by PO1 and the successful K tuple claims.

INT-6

- Source: code in `EvalfMixin.evalf`.
- Evidence: `except NotImplementedError: # Fall back to the ordinary evalf`.
- Obligation: `NotImplementedError` is the supported signal for leaving the
  internal numeric path and preserving a symbolic expression through ordinary
  `_eval_evalf`.
- Status: encoded by PO4.

## Formal Model

The K model is intentionally abstract and property-complete for the changed
branch:

- `fvk/mini-evalf.k` models the fallback's component classifier.
- `zero` means an exact-zero component, internally represented as `None`.
- `num` means a numeric component converted to an mpf tuple.
- `sym` means a nonzero symbolic component such as the real part of
  `Max(0, y)`.
- A successful result is `tuple(re, im, rePrec, imPrec)`.
- A symbolic nonzero component produces `notImplemented`.

The model preserves the property under audit: whether the fallback constructs a
well-formed numeric tuple or exits through the already-supported symbolic
fallback signal. It deliberately abstracts away mpmath mantissa contents,
because the issue does not concern numerical rounding or arithmetic value.

## Contract

For all fallback inputs after the existing `re.has(re_)` / `im.has(im_)` guard:

1. If both real and imaginary components are exact zero or numeric, internal
   `evalf` returns a tuple whose component slots are mpf-valued or `None`.
2. If either nonzero component is symbolic/non-numeric, internal `evalf` raises
   `NotImplementedError`.
3. Public `EvalfMixin.evalf` treats `NotImplementedError` as a symbolic
   fallback signal and returns the ordinary `_eval_evalf` reconstruction when
   the reconstructed expression is still symbolic.
4. `evalf_mul` may propagate that signal from any argument; the public caller
   then uses the same ordinary fallback, making the reported `Mul` behavior
   independent of argument order.

## Adequacy Audit

The formal English above matches the public intent:

- It removes the exact crash reported in INT-1.
- It preserves the symbolic output form shown as correct in INT-2.
- It uses the `NotImplementedError` mechanism explicitly named by INT-3 and
  already consumed by public `evalf` per INT-6.
- It rejects the `prec=None` alternative for symbolic components because INT-5
  reserves `None` component values for exact zero.

No public API signature, return type, or virtual dispatch shape was changed.
Only an internal branch outcome changed from uninitialized-local failure to the
existing `NotImplementedError` fallback signal.
