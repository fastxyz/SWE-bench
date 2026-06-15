# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change in
`repo/astropy/units/decorators.py`, in
`QuantityInput.__call__.wrapper` after the wrapped function has run:

```python
return_annotation = wrapped_signature.return_annotation
if (return_annotation is not inspect.Signature.empty and
        return_annotation is not None):
    return return_.to(return_annotation)
else:
    return return_
```

The proof abstracts earlier argument binding and unit validation as framed
behavior because V1 does not edit those branches. The verified observable is
whether return handling calls `.to(...)`, returns the wrapped function result
unchanged, or reaches the old `AttributeError` path.

## Public Intent Ledger

Critical ledger entries are mirrored from `PUBLIC_EVIDENCE_LEDGER.md`:

- E-001 through E-005 require `@u.quantity_input` to accept a constructor
  annotated with `-> None` and to avoid calling `.to(...)` merely because the
  no-return type hint exists.
- E-006 and E-007 require non-`None` unit return annotations to retain the
  existing `.to(annotation)` conversion behavior.
- E-008 records V1's branch condition as implementation evidence only.

## Domain and Preconditions

The modeled return annotation is one of:

- `emptyAnn`, representing `inspect.Signature.empty`;
- `noneAnn`, representing the Python annotation object `None` from `-> None`;
- `unitAnn(U)`, representing an in-domain unit-like return annotation.

The wrapped function's result is one of:

- `noneRet`, representing Python `None`;
- `quantity(Unit)`, representing an object whose `.to(target)` conversion is
  meaningful for the audit;
- `objectRet(Name)`, representing a non-quantity return.

This proof is partial correctness over the return-handling branch: if argument
validation and the wrapped function terminate, the return-handling branch has
the specified result.

## Formal Claims

The K artifact `quantity-input-spec.k` contains these claims:

- QI-NONE: `wrapper(noneAnn, noneRet)` reaches `returned(noneRet)`.
- QI-NONE-ANY: `wrapper(noneAnn, R)` reaches `returned(R)` for every modeled
  return value `R`.
- QI-EMPTY: `wrapper(emptyAnn, R)` reaches `returned(R)`.
- QI-UNIT: `wrapper(unitAnn(To), quantity(From))` reaches
  `converted(quantity(To), unitAnn(To))`.
- QI-OLD-BUG: the pre-fix abstract wrapper reaches `attrError("NoneType.to")`
  on `buggyWrapper(noneAnn, noneRet)`, matching the reported symptom.

## Frame Conditions

- Function/decorator signatures are unchanged.
- Argument validation is unchanged.
- Equivalency context entry and wrapped-function execution are unchanged.
- Non-`None` unit return annotations continue to convert through `.to`.
- The wrapper does not become a Python type checker; it does not enforce that a
  `-> None` function returns only `None`.

## Residual Ambiguity

Stringified annotations such as `"None"` are not included in the domain because
the public issue uses Python 3.6 runtime annotations and because stringified
argument annotations would raise broader decorator questions not evidenced by
this issue. No code change is justified for that case in this pass.
