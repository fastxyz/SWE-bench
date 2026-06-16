# FVK Notes

## Decisions and Traceability

I kept V1's guard:

```python
if rv.exp.is_integer is not True:
    return rv
```

Reason: `fvk/FINDINGS.md` F1 identifies the reported failure as an ordered
comparison on `I`, and `fvk/PROOF_OBLIGATIONS.md` PO-1 requires every
non-integer exponent to return before ordered comparisons, parity checks, or
`perfect_power`. This directly addresses `simplify(cos(x)**I)`.

I added a concrete-`Integer` guard in the `pow=True` branch:

```python
if not rv.exp.is_Integer:
    return rv
```

Reason: `fvk/FINDINGS.md` F2 shows that V1 still allowed symbolic integer
exponents into `perfect_power`, whose implementation requires a concrete
integer. `fvk/PROOF_OBLIGATIONS.md` PO-6 requires non-concrete symbolic integer
exponents to remain unchanged in `pow=True` mode.

I changed the `perfect_power` acceptance check from:

```python
if not p:
    return rv
```

to:

```python
if not p or p[0] != 2:
    return rv
```

Reason: `fvk/FINDINGS.md` F2 identifies odd perfect powers such as `9` as a
V1 gap: `perfect_power(9)` succeeds even though `_TR56`'s docstring and inline
comment say `pow=True` is for exponents expressible as powers of two.
`fvk/PROOF_OBLIGATIONS.md` PO-6 requires concrete non-powers of two to remain
unchanged.

## Confirmation

No other code changes were made. `fvk/FINDINGS.md` F3 records that tests and K
tooling were not run because this task forbids execution. `fvk/PROOF.md`
therefore labels the proof as constructed, not machine-checked, and recommends
no test removal.

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` confirms that `_TR56` and its wrappers keep
their signatures and return category, satisfying `fvk/PROOF_OBLIGATIONS.md`
PO-8.
