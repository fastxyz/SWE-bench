# FVK Spec: sympy__sympy-17139

Status: constructed, not machine-checked. Per task instructions, no tests,
Python, or K tooling were executed.

## Scope

The audited unit is `_TR56` in `repo/sympy/simplify/fu.py`, including its use
through `TR5`, `TR6`, `TR15`, `TR16`, and `TR22`. The specific reported symptom
is reached through `simplify(cos(x)**I)` -> `TR6` -> `_TR56`.

`bottom_up` traversal itself is treated as a trusted caller: the FVK model covers
the local decision made for one visited power expression. This preserves the
property under audit because the crash and the incorrect `pow=True` rewrites are
both produced by `_TR56._f` for a single `Pow` node.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | `benchmark/PROBLEM.md` | `simplify(cos(x)**I)` raises `TypeError: Invalid comparison of complex I` in `_TR56` at `rv.exp < 0`. | A trigonometric simplification pass must not order a complex exponent such as `I`; the expression should be left unchanged by this rule rather than crashing. | Encoded by PO-1 and K claim `NONINTEGER-UNCHANGED`. |
| INT-2 | `_TR56` docstring | "replace f**2 with h(g**2)" | The rewrite is an even-integer-power identity. Exponents outside the known integer domain are not valid inputs for this rewrite and must be left unchanged. | Encoded by PO-1 through PO-6. |
| INT-3 | `_TR56` docstring | `max` "controls size of exponent that can appear on f"; `sin(x)**10` with `max=4` is unchanged. | Known integer exponents greater than `max` are unchanged. | Encoded by PO-2. |
| INT-4 | `_TR56` docstring and inline comment | `pow=True` means powers "expressible as powers of 2"; example says `f**6` is unchanged and `f**8` is changed. | With `pow=True`, only concrete powers of two should be rewritten; other exponents, including odd perfect powers such as `9`, are unchanged. | Encoded by PO-6; V1 failed this. |
| INT-5 | public tests in `repo/sympy/simplify/tests/test_fu.py` | `_TR56` leaves `sin(x)**3`, `sin(x)**10`, and `sin(x)**6` with `pow=True` unchanged; rewrites `sin(x)**6` with `pow=False` and `sin(x)**8` with `pow=True`. | Existing documented examples must keep their behavior. | Encoded by PO-2 through PO-6. |
| IMPL-1 | `repo/sympy/ntheory/factor_.py` | `perfect_power` calls `as_int(n)` and documents `ValueError` for non-integer or non-positive `n`. | `_TR56` must not call `perfect_power` for non-concrete symbolic integer exponents when it cannot decide power-of-two status. | Encoded by PO-6; V1 failed this. |

## Contract

For one visited expression `rv`:

1. If `rv` is not a `Pow` whose base function is the target trig function `f`,
   `_TR56` leaves it unchanged.
2. If `rv.exp.is_integer is not True`, `_TR56` leaves it unchanged before any
   ordered comparison, parity check, or `perfect_power` call.
3. If the exponent is known negative, `_TR56` leaves it unchanged.
4. If the exponent is known greater than `max`, `_TR56` leaves it unchanged.
5. If the exponent is `2`, `_TR56` returns `h(g(arg)**2)`.
6. If the exponent is `4`, `_TR56` returns `h(g(arg)**2)**2`.
7. If `pow=False`, a known even integer exponent within `max` rewrites to
   `h(g(arg)**2)**(exp//2)`; a known odd integer exponent is unchanged.
8. If `pow=True`, only a concrete integer exponent that is a power of two
   rewrites to `h(g(arg)**2)**(exp//2)`. Concrete non-powers of two and
   non-concrete symbolic integer exponents are unchanged.

## Formal Artifacts

The formal core is in:

- `fvk/mini-sympy-fu.k`
- `fvk/tr56-spec.k`

The K model abstracts SymPy expressions to the exponent classification relevant
to `_TR56`: non-integer, symbolic integer, or concrete integer. This abstraction
distinguishes the passing and failing cases needed by the audit:

- non-integer/complex exponent `I` vs a concrete integer exponent;
- concrete `6`, `8`, and `9` under `pow=True`;
- symbolic integer under `pow=True` vs concrete integer under `pow=True`.

## Compatibility

No public signature or return type changed. `_TR56`, `TR5`, `TR6`, `TR15`,
`TR16`, and `TR22` retain the same parameters and still return SymPy
expressions. The change only narrows when a rewrite is attempted.
