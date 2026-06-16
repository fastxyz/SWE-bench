# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Adequacy Gate

- `INTENT_SPEC.md` records the public intent before accepting candidate
  behavior.
- `PUBLIC_EVIDENCE_LEDGER.md` traces each nontrivial obligation to public issue
  text, local source/API documentation, or marked-suspect public tests.
- `FORMAL_SPEC_ENGLISH.md` paraphrases each claim.
- `SPEC_AUDIT.md` marks all claim-to-intent comparisons PASS.
- `PUBLIC_COMPATIBILITY_AUDIT.md` finds no signature, dispatch, or callsite
  incompatibility.

The proof therefore targets the intended contract: zero-argument `Min()` and
`Max()` return `oo` and `-oo`, respectively, while non-empty calls stay on the
existing constructor path.

## Symbolic Execution

### Claim `MIN-EMPTY`

Initial configuration:

```k
<k> construct(MinCls, .Args) </k>
```

The empty-argument semantic rule applies:

```k
construct(C, .Args) => identity(C)
```

with substitution `C := MinCls`. The function rule for `identity` rewrites
`identity(MinCls)` to `oo`. The final configuration matches:

```k
<k> oo </k>
```

This discharges PO1 and PO3 for `Min`.

### Claim `MAX-EMPTY`

Initial configuration:

```k
<k> construct(MaxCls, .Args) </k>
```

The same empty-argument rule applies with substitution `C := MaxCls`.
The function rule for `identity` rewrites `identity(MaxCls)` to `negOo`, the
model value for SymPy `-oo`. The final configuration matches:

```k
<k> negOo </k>
```

This discharges PO2 and PO3 for `Max`.

### Claim `NONEMPTY-FRAME`

Initial configuration:

```k
<k> construct(C, consArg(A, REST)) </k>
```

The side condition on the non-empty rule is:

```k
notBool isEmptyArgs(consArg(A, REST))
```

The `isEmptyArgs` function rewrites `isEmptyArgs(consArg(_, _))` to `false`,
so the side condition reduces to `true`. The non-empty semantic rule applies:

```k
construct(C, AS) => tailResult(C, AS)
```

with `AS := consArg(A, REST)`. The final configuration matches:

```k
<k> tailResult(C, consArg(A, REST)) </k>
```

This discharges PO4.

## Code-to-Proof Alignment

The V1 source branch:

```python
if not args:
    return cls.identity
```

corresponds to the empty-argument semantic rule in `mini-python.k`. The class
attributes:

```python
Max.identity = S.NegativeInfinity
Min.identity = S.Infinity
```

correspond to the `identity(MaxCls) => negOo` and `identity(MinCls) => oo`
rules. Because the source edit is confined to the empty branch, the non-empty
proof obligation is a frame condition rather than a reproof of the full SymPy
Min/Max simplification algorithm.

## Residual Risk

- The proof is constructed, not machine-checked. The exact K commands are in
  `PROOF_OBLIGATIONS.md`.
- The mini semantics abstracts the non-empty constructor tail. It proves the
  edit preserves dispatch to that tail, not that every non-empty simplification
  rule in SymPy is correct.
- Termination is trivial for the modeled branch, but no project code was run.

## Test Guidance

- Tests asserting `Min() == oo` and `Max() == -oo` would be covered by PO1 and
  PO2 after machine-checking.
- Existing visible tests asserting `ValueError` for zero-argument calls are
  SUSPECT legacy tests and should be updated when test edits are allowed.
- Non-empty behavior tests should be kept; this proof only frames that branch
  around the edit.

