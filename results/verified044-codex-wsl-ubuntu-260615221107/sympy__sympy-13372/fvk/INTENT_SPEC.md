# Intent Spec

Status: intent-only; current implementation behavior is treated as observed
behavior to check, not as the specification.

1. The reported expression
   `Mul(Max(0, y), x, evaluate=False).evalf()` must not raise
   `UnboundLocalError`.
2. The symbolic output behavior shown for
   `Mul(x, Max(0, y), evaluate=False).evalf()` should also hold for the
   reversed argument order: the unevaluable symbolic factor is preserved.
3. Internal evalf result tuples must respect the documented contract in
   `evalf.py`: real and imaginary component slots are mpf tuples or `None` for
   exact zero.
4. A nonzero symbolic real or imaginary component is not a numeric evalf result
   and should leave the internal numeric path through the already-supported
   `NotImplementedError` mechanism.
5. No public API signature, public return shape for successful numeric evalf
   results, or `_eval_evalf` override protocol should change.
