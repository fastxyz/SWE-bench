# Formal Spec English

The K claim `fallback(sym, zero) => notImplemented` means: if the real
component is symbolic and nonzero while the imaginary component is exact zero,
the internal numeric fallback must exit through `NotImplementedError`.

The K claim `fallback(zero, sym) => notImplemented` means: if the imaginary
component is symbolic and nonzero while the real component is exact zero, the
internal numeric fallback must exit through `NotImplementedError`.

The K claims for `fallback(zero, zero)`, `fallback(num, zero)`,
`fallback(zero, num)`, and `fallback(num, num)` mean: exact-zero and numeric
components still produce successful evalf tuples, and those tuples contain only
mpf-valued components or exact-zero sentinels.

The code-level proof obligation for `evalf_mul` means: when a `Mul` argument is
not numerically evaluable, the internal `NotImplementedError` may propagate to
public `.evalf()`, where the ordinary symbolic fallback reconstructs the
expression. The same mechanism applies regardless of which factor is first.
