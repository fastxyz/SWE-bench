# Formal Spec, Paraphrased

Status: English paraphrase of the constructed K claims in `str-printer-spec.k`.

1. For any numerator text `N` and any denominator reciprocal whose base shape is a compound `Pow` base, `printMul` must produce `N/(T)` where `T` is the already-rendered base text. In the concrete nested reciprocal case, `printMul(a, reciprocal(1/b))` produces `a/(1/b)`.
2. For any numerator text `N` and any denominator reciprocal whose base shape is a compound `Mul` base, `printMul` must produce `N/(T)`. In the existing issue 14160 shape, the denominator `y*y` remains grouped as `x/(y*y)`.
3. For a simple atomic denominator base, `printMul` leaves the denominator unwrapped, so a simple quotient remains `x/y`.
4. The formal model abstracts the rest of SymPy's expression printer away and preserves only the observable axis under verification: whether the denominator text is wrapped in explicit parentheses.
5. There are no loop circularities or termination claims for this target; the modeled code path is a finite branch decision.
