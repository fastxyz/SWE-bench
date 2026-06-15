# FVK PROOF

Status: constructed, not machine-checked. This proof was written without
running tests, Python, `kompile`, `kast`, or `kprove`.

## Reproduce The Machine Check Later

Do not run these commands in this benchmark session. They are the commands that
would machine-check the constructed artifacts in an environment with K:

```sh
kompile fvk/mini-django-ordering.k --backend haskell
kast --backend haskell fvk/model-ordering-spec.k
kprove fvk/model-ordering-spec.k
```

Expected outcome after a future machine check: `#Top` for all claims.

## Proof Sketch For PO-1: `option__pk`

Initial symbolic state: current model is `Child`, previous field is `none`, and
remaining parts are `["option", "pk"]`.

Step 1. `previous = none`, so the scalar-field guard does not fire. The part
`option` is not `pk`. Field lookup in `Child` returns `relation(Option)`.
The loop sets previous field to that relation and current model to `Option`.

Step 2. Remaining part is `pk`; previous field is a relation, not a scalar, so
the scalar-field guard still does not fire. Because the loop is still resolving
a model path, `pk` rewrites to `Option.pk.name`, which is `id`.

Step 3. Field lookup in `Option` for `id` returns the scalar primary-key field.
No exception path is taken, so no `models.E015` is appended. This proves PO-1
under the mini semantics and fixes Finding F1.

## Proof Sketch For PO-2: `option__missing`

Step 1 is identical to PO-1: `option` resolves to `relation(Option)` and moves
the current model to `Option`.

Step 2. The part `missing` is not `pk`, and lookup in `Option` fails. The
previous field is the relation field `option`; by precondition it has no
registered transform named `missing`. The exception branch appends
`models.E015` for the original ordering string. This proves PO-2.

## Proof Sketch For PO-3: `test__pk`

Initial symbolic state: current model is `Model`, previous field is `none`, and
remaining parts are `["test", "pk"]`.

Step 1. `test` resolves to a scalar field. The current model remains `Model`,
and previous field becomes that scalar field.

Step 2. The next part is `pk`, but previous field is scalar. The V2 scalar-field
guard fires before the `pk` alias rewrite, forcing the exception/transform path.
By precondition, `test.get_transform("pk")` is absent. The checker appends
`models.E015` for `test__pk`. This proves PO-3 and discharges Finding F2.

## Proof Sketch For PO-4: `test__lower`

Step 1. `test` resolves to a scalar field, as in PO-3.

Step 2. The next part is `lower`, and the scalar-field guard forces transform
validation. By precondition, `test.get_transform("lower")` exists, so the
exception branch does not append `models.E015`. This proves PO-4 and preserves
registered transform ordering.

## Proof Sketch For PO-5: Frame Conditions

The diff only inserts checks inside the `for part in field.split(LOOKUP_SEP)`
loop used for entries already classified as containing `LOOKUP_SEP`. It does not
touch expression filtering, random ordering marker handling, direct `pk`
filtering, direct field validation, error object construction, method signature,
or return type. Therefore those observable behaviors are framed by unchanged
source code.

## Residual Risk

The proof is partial correctness over a deliberately small semantic model. It
does not prove termination, though the loop iterates over a finite split string
in the actual Python code. It also depends on adequacy of the mini semantics and
has not been machine-checked. No test-removal recommendation is made.
