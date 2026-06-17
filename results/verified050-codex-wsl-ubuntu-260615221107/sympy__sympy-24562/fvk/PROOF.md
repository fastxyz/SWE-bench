# Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Claims Proved on Paper

The constructed K-style claims are in `fvk/rational-normalization-spec.k` and use the mini semantics in `fvk/mini-rational.k`.

The primary claim is:

```text
normalize(PN, PD, QN, QD, autoGcd, false)
  -> canonical(PN * QD, PD * QN, autoGcd, false)
```

under `PD > 0`, `QD > 0`, and `QN != 0`.

## Symbolic Proof Sketch

Assume both operands are valid finite rational-like values:

```text
Rational(p) = PN/PD, PD > 0
Rational(q) = QN/QD, QD > 0
```

V1 first initializes `qden = 1`.

Case 1: `p` is a Python/SymPy integer. The code sets `p = int(p)`. This is the same as `PN = p` and `PD = 1`, so `qden` remains `1`.

Case 2: `p` is not an integer. The code computes `p = Rational(p)`, then stores `qden = p.q` and `p = p.p`. This sets `qden = PD` and `p = PN`.

For `q`:

Case A: `q` is a Python/SymPy integer. The code sets `q = qden * int(q)`. This is `q = PD * QN` with `QD = 1`, while `p` remains `PN = PN * QD`.

Case B: `q` is not an integer. The code computes `q = Rational(q)`, then sets `p *= q.q` and `q = qden * q.p`. This gives `p = PN * QD` and `q = PD * QN`.

Thus all finite cases reach the pre-canonical pair:

```text
(PN * QD, PD * QN)
```

which represents `(PN/PD) / (QN/QD)`. No proof step multiplies the raw `q` object; PO1 is discharged.

For the reported input, `Rational('0.5') = 1/2` and `Rational('100') = 100/1`, so the pair is `(1 * 1, 2 * 100) = (1, 200)`. The bad legacy pair `(1, 100100)` is unreachable because no raw string multiplication remains.

## Frame Proof

After the pre-canonical pair is computed, V1 enters the same downstream code as the baseline:

- `q == 0` handles complex infinity, NaN, or `ValueError`.
- `q < 0` normalizes the sign.
- `if not gcd` reduces by `igcd(abs(p), q)`.
- `q == 1` returns `Integer(p)`.
- `p == 1 and q == 2` returns `S.Half`.
- otherwise a `Rational` object stores `p` and `q`.

Because V1 changes only how the pair is computed before these branches, PO4 through PO7 are frame-preserved.

## Adequacy Gate

`fvk/SPEC_AUDIT.md` marks all formal paraphrases as matching `fvk/INTENT_SPEC.md`. The public compatibility audit passes. The proof therefore supports `V2 == V1` for this issue.

## Machine Check Commands

These commands are recorded for a real environment. They were not executed here.

```sh
cd fvk
kompile mini-rational.k --backend haskell
kast --backend haskell rational-normalization-spec.k
kprove rational-normalization-spec.k
```

Expected outcome after a successful machine check: `kprove` returns `#Top` for all claims.

## Test Recommendation

Do not remove tests in this task. After machine-checking, point tests that instantiate the finite quotient family, including the public suggested family over `('1.5', 1.5, 2)`, would be subsumed by PO2. Boundary tests for invalid inputs, zero denominators, and compatibility should be kept because they exercise frame behavior outside the primary finite quotient claim.
