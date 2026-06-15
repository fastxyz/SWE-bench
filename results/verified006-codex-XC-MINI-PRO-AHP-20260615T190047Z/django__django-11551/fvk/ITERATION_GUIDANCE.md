# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 should not stand completely unchanged. FVK Finding F2 showed that V1 still
let `ModelAdmin` attributes short-circuit before model field metadata, while
the public docs and runtime lookup order say model fields are interpreted first.

V2 keeps the V1 fix for Finding F1 and adds the field-first validation order
required by PO3:

1. Accept callables immediately.
2. Resolve model fields through `_meta.get_field(item)`.
3. Reject resolved `ManyToManyField` values with `admin.E109`.
4. If metadata lookup fails, accept `ModelAdmin` attributes.
5. If admin lookup fails, fall back to model attributes/methods.
6. Emit `admin.E108` only when all relevant lookups fail.

## Suggested Tests If Test Editing Were Allowed

The task forbids modifying tests, so these are recommendations only:

- Add a descriptor-backed model field whose class-level attribute access raises
  `AttributeError` but `_meta.get_field()` succeeds; expect no `admin.E108`.
- Add a `ManyToManyField` with a same-named `ModelAdmin` method; expect
  `admin.E109` because model field precedence wins.
- Add a model attribute fallback that resolves `None`; expect success, not
  `admin.E108`.
- Keep the existing missing-field and direct `ManyToManyField` checks.

## Verification Commands To Run Later

```sh
cd fvk
kompile mini-admin-check.k --backend haskell
kast --backend haskell list-display-check-spec.k
kprove list-display-check-spec.k
```

Expected result: `kprove` returns `#Top` for all claims.

## Next Iteration Risks

No open finding remains for the audited contract. A broader audit of invalid
non-callable, non-string `list_display` items would be a separate contract
question because the public docs define the supported item family as callables
and string names.

