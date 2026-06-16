# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Code Decision

Keep V1 unchanged.

Rationale:

- F1 identifies the only public-intent bug found by the audit.
- PO-1 and PO-2 are discharged by binding the temporary probe object's database
  before `natural_key()`.
- PO-3 through PO-5 confirm that natural-primary lookup, branch behavior, and
  public compatibility remain intact.
- PO-6 favors V1 over a `Model.from_db()` rewrite because public intent requires
  database context only, not a change in model construction semantics.

## Recommended Follow-up Outside This Task

Add a regression test covering:

- `loaddata --database other`
- fixture data with natural primary keys and natural foreign keys
- a model natural key that follows a foreign key
- the related row present in `other` and absent from `default`

Do not delete any tests based on this FVK pass. The proof is constructed, not
machine-checked.

## Future Machine Verification

Run:

```sh
kompile fvk/mini-django-serializer.k --backend haskell
kast --backend haskell fvk/django-15525-spec.k
kprove fvk/django-15525-spec.k
```

If `kprove` does not return `#Top`, inspect the residual obligation and update
`FINDINGS.md` before changing production code.
