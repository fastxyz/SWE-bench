# Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was run in this environment.

## Artifacts

- Semantics: `fvk/mini-quantity-input.k`
- Claims: `fvk/quantity-input-spec.k`
- Human spec and audits: `fvk/SPEC.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`,
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Machine-Check Commands

These commands are emitted for later checking only:

```sh
cd fvk
kompile mini-quantity-input.k --backend haskell
kast --backend haskell quantity-input-spec.k
kprove quantity-input-spec.k
```

Expected result after machine checking: `#Top` for all claims.

## Constructed Proof Sketch

### QI-NONE

Initial state: `<k> wrapper(noneAnn, noneRet) </k>`.

The semantics evaluates `shouldConvert(noneAnn)` to `false`, mirroring V1's
Python condition:

```python
return_annotation is not inspect.Signature.empty and return_annotation is not None
```

The conversion rule is disabled. The non-conversion rule rewrites the state to
`<k> returned(noneRet) </k>`. This discharges PO-RNONE for the constructor
reproducer.

### QI-NONE-ANY

Initial state: `<k> wrapper(noneAnn, R) </k>` for arbitrary modeled return value
`R`.

The same `shouldConvert(noneAnn) => false` consequence applies. The wrapper
rewrites to `returned(R)`. This proves the wrapper treats `-> None` as "no
return conversion", not as a unit target and not as a runtime type assertion.

### QI-EMPTY

Initial state: `<k> wrapper(emptyAnn, R) </k>`.

The semantics evaluates `shouldConvert(emptyAnn)` to `false`, matching the
existing empty-annotation branch. The wrapper rewrites to `returned(R)`. This
discharges PO-REMPTY and the no-annotation frame condition.

### QI-UNIT

Initial state:
`<k> wrapper(unitAnn(TO), quantity(FROM)) </k>`.

The semantics evaluates `shouldConvert(unitAnn(TO))` to `true`, so the wrapper
rewrites to `to(quantity(FROM), unitAnn(TO))`. The modeled `.to` rule rewrites
that state to `converted(quantity(TO), unitAnn(TO))`. This discharges PO-RUNIT
and proves V1 preserves documented unit return conversion for non-`None`
annotations.

### QI-OLD-BUG

Initial state: `<k> buggyWrapper(noneAnn, noneRet) </k>`.

The pre-fix abstract branch converts every non-empty annotation, including
`noneAnn`, so it rewrites to `to(noneRet, noneAnn)`. The modeled `.to` operation
on `noneRet` rewrites to `attrError("NoneType.to")`, matching the public
traceback. This localizes the reported failure to the return-conversion branch.

## Composition with Real Code

The source branch in V1 corresponds to `shouldConvert`:

- `inspect.Signature.empty` maps to `emptyAnn` and returns unchanged;
- `None` maps to `noneAnn` and returns unchanged;
- all present non-`None` annotations map to `unitAnn` for the in-domain unit
  return feature and convert through `.to`.

The earlier wrapper steps are framed:

- argument binding and validation are unchanged;
- the equivalency context is unchanged;
- the wrapped function call is unchanged;
- no public signature or dispatch shape changes.

## Completeness Check

The proof covers the full public issue domain: a constructor with an argument
unit annotation, a return annotation of `None`, and an underlying `None` return.
It also covers the relevant frame branches for empty annotations and unit return
annotations.

Stringified annotations and static type enforcement are outside the public
intent domain and remain residual ambiguity, not a source-code obligation.

## Test-Redundancy Recommendation

No tests were modified. If the K claims are later machine-checked, a narrow unit
test that only asserts `wrapper(noneAnn, noneRet) -> returned(noneRet)` would be
subsumed by QI-NONE, but integration tests around the real decorator should be
kept because the mini semantics frames argument validation and function calling.
