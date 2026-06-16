# Findings

Status: constructed, not machine-checked.

## F-001: Pre-fix mpmath lambdify emitted bare rational division

Classification: code bug, resolved by V1.

Evidence: `benchmark/PROBLEM.md` shows generated source containing `RisingFactorial(18, x) - 232/3` and states that `232/3` is not evaluated at full precision.

Input / scenario:

```python
lambdify(x, rf(18, x) - (77 + S(1)/3), 'mpmath')
```

Observed pre-fix behavior: generated source contains bare Python integer division `232/3`.

Expected behavior: generated source uses mpmath-wrapped operands for the rational, e.g. `mpf(232)/mpf(3)` under lambdify's unqualified mpmath namespace.

V1 status: closed. `MpmathPrinter._print_Rational` now emits `mpf`-formatted numerator and denominator for `q > 1`.

Proof obligations: PO-1, PO-2, PO-5, PO-7.

## F-002: Negative non-integer rationals require the same wrapping

Classification: corner-case obligation, resolved by V1.

Evidence: the prompt obligation is for "rationals", not only the positive reproducer `232/3`.

Input / scenario:

```text
MpmathPrinter prints Rational(-1, 3)
```

Observed V1 behavior: emits `-F(1)/F(3)`.

Expected behavior: generated expression keeps the negative sign but divides mpmath values, not Python integers.

V1 status: closed.

Proof obligations: PO-2, PO-3.

## F-003: Direct machine proof and real mpmath final rounding are out of scope for this run

Classification: proof capability gap / residual risk, not a source-code bug.

Evidence: the task forbids running K tooling, Python, or tests. The mini-K semantics models generated expression shape and mpmath-value dispatch, not full Python execution or mpmath internals.

Input / scenario:

```text
Very large p/q where final correctly-rounded rational evaluation could be sensitive to mpmath internals.
```

Observed in this FVK run: no execution result is available; no machine check was run.

Expected handling: keep the source fix because it satisfies the public issue's "wrap rationals" obligation, but label the proof constructed-not-machine-checked and keep precision-edge tests until real execution/proof tooling can confirm them.

V1 status: no code change justified.

Proof obligations: PO-8.

## F-004: Non-mpmath printer behavior has no issue-derived change obligation

Classification: frame condition, confirmed.

Evidence: the public issue names `modules='mpmath'` and precision loss through mpmath/nsolve.

Input / scenario:

```text
Generic Python, NumPy, SciPy, SymPy, TensorFlow, or NumExpr printer emits a rational.
```

Observed V1 behavior: unchanged, because only `MpmathPrinter` is modified.

Expected behavior: unchanged for this issue unless separate public intent requires otherwise.

V1 status: confirmed.

Proof obligations: PO-6.
