# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - `Min()` Empty-Argument Result

- Claim: when `cls is Min` and `args` is empty,
  `MinMaxBase.__new__` returns `S.Infinity` (`oo`).
- Provenance: ledger E1, E3, E4, E5.
- Formal claim: `MIN-EMPTY` in `fvk/minmax-spec.k`.
- V1 discharge: the empty branch returns `cls.identity`; for `Min`, the class
  attribute is `S.Infinity`.

## PO2 - `Max()` Empty-Argument Result

- Claim: when `cls is Max` and `args` is empty,
  `MinMaxBase.__new__` returns `S.NegativeInfinity` (`-oo`).
- Provenance: ledger E1, E3, E4, E5.
- Formal claim: `MAX-EMPTY` in `fvk/minmax-spec.k`.
- V1 discharge: the empty branch returns `cls.identity`; for `Max`, the class
  attribute is `S.NegativeInfinity`.

## PO3 - Empty Arguments Must Not Reach Comparability Filtering

- Claim: zero-argument calls should not raise a comparability or missing
  argument error.
- Provenance: ledger E2, E3.
- Formal claims: `MIN-EMPTY`, `MAX-EMPTY`.
- V1 discharge: `if not args: return cls.identity` exits before sympification,
  `_new_args_filter`, `_collapse_arguments`, and `_find_localzeros`.

## PO4 - Non-Empty Constructor Frame Condition

- Claim: for any non-empty argument list, the V1 edit must preserve the existing
  constructor path.
- Provenance: ledger E8 and compatibility audit.
- Formal claim: `NONEMPTY-FRAME` in `fvk/minmax-spec.k`.
- V1 discharge: the only changed source line is inside the `if not args` branch;
  non-empty calls skip that branch and execute the original code.

## PO5 - Public Compatibility

- Claim: the fix must not change the public constructor signature or introduce
  a new call protocol.
- Provenance: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- V1 discharge: `def __new__(cls, *args, **assumptions)` is unchanged; no new
  keyword, return container, or virtual dispatch shape is introduced.

## PO6 - Honesty and Reproducibility

- Claim: proof status and test recommendations must be labeled constructed,
  not machine-checked, because the task forbids running K tooling or tests.
- Provenance: FVK `verify.md` honesty gate and user no-execution rule.
- V1 discharge: all artifacts carry the constructed/not-machine-checked caveat;
  no tests or K commands were run.

## Machine-Check Commands for Later

These commands are intentionally not run in this session:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell minmax-spec.k
kprove minmax-spec.k
```

Expected machine-check outcome after a valid K environment is available:
`kprove` returns `#Top` for the three claims.

