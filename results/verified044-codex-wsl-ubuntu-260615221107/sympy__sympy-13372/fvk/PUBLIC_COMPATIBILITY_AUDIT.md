# Public Compatibility Audit

Changed file: `repo/sympy/core/evalf.py`.

Changed symbol: internal function `evalf(x, prec, options)`.

Public signatures:

- `EvalfMixin.evalf(self, n=15, subs=None, maxn=100, chop=False, strict=False,
  quad=None, verbose=False)` is unchanged.
- `_eval_evalf(self, prec)` override signatures are unchanged.
- `evalf_mul(v, prec, options)` signature is unchanged.

Dispatch and call shape:

- No new keyword arguments are passed to public or virtual methods.
- No subclass override is required to accept a new call shape.
- The new branch raises `NotImplementedError`, which existing public
  `EvalfMixin.evalf` already catches.

Return shape:

- Successful internal numeric evalf tuples keep the same shape.
- Public symbolic fallback output remains an ordinary SymPy expression.

Conclusion: no compatibility blocker found.
