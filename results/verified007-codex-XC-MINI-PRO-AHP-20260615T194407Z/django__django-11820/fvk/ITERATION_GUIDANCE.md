# FVK ITERATION GUIDANCE

Status: V2 source change applied; proof constructed, not machine-checked.

## Decision

Do not keep V1 unchanged. Finding F2 shows V1 accepted `test__pk` by applying
the model `pk` alias after a scalar field. The source was revised so suffixes
after scalar fields are validated as transforms only.

Keep the V1 idea of mapping `pk` to the current model's primary-key field while
the path is still traversing related model fields. Finding F1 and PO-1 justify
that part of the fix.

## Suggested Public Tests For A Future Environment

Do not edit tests in this benchmark session. If a normal development
environment is available later, add focused tests for:

- `Meta.ordering = ('option__pk',)` where `option` is a foreign key: no
  `models.E015`.
- `Meta.ordering = ('test__pk',)` where `test` is a scalar field with no `pk`
  transform: `models.E015`.
- `Meta.ordering = ('test__id',)` where `test` is scalar and `id` is only a
  model field, not a transform on `test`: `models.E015`.
- Existing registered transform ordering such as `test__lower`: still no error.
- Nested relation primary-key ordering such as `parent__option__pk`: no error
  when each relation exists.

## Future Verification

When execution is allowed, run the K commands recorded in `fvk/PROOF.md`, then
run the relevant Django model-check tests. Test deletion should remain off the
table until the K proof is actually machine-checked and the project tests pass.

## Remaining Risk

The proof abstracts Django field objects to relation/scalar/transform facts. If
future work changes relation fields whose `get_path_info()` raises
`AttributeError`, the abstraction should be revisited. No such change is part of
this issue.
