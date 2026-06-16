# Public Evidence Ledger

INT-1

- Source: prompt.
- Evidence: `Mul(Max(0, y), x, evaluate=False).evalf()` raises
  `UnboundLocalError`.
- Obligation: remove the uninitialized-local failure for the reported
  in-domain expression.

INT-2

- Source: prompt.
- Evidence: `Mul(x, Max(0, y), evaluate=False).evalf()` returns
  `x*Max(0, y)`.
- Obligation: preserve symbolic factors rather than converting them to numeric
  zero or malformed evalf tuples.

INT-3

- Source: prompt.
- Evidence: the issue proposes `else: raise NotImplementedError`.
- Obligation: nonzero symbolic components should use the existing symbolic
  fallback signal.

INT-4

- Source: prompt hint.
- Evidence: the hint questions whether `prec=None` is correct and notes that
  value `None` appears to mean exact zero.
- Obligation: keep exact-zero representation separate from symbolic
  unevaluability.

INT-5

- Source: `repo/sympy/core/evalf.py` comment.
- Evidence: real/imaginary fields are mpf tuples or `None` for exact zero.
- Obligation: successful internal tuples must be well formed.

INT-6

- Source: `EvalfMixin.evalf`.
- Evidence: `except NotImplementedError` falls back to ordinary `_eval_evalf`.
- Obligation: `NotImplementedError` is a compatible internal signal.
