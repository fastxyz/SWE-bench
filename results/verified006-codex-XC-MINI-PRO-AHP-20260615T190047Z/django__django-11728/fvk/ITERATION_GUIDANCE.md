# Iteration Guidance

Status: generated from FVK findings and proof obligations.

## Source changes applied in V2

1. Keep the V1 named scanner fix.
   - Evidence: F1.
   - Obligation: POB-N1.

2. Keep the V1 unnamed scanner fix.
   - Evidence: F2.
   - Obligation: POB-U1.

3. Change unnamed reconstruction to use a moving cursor.
   - Evidence: F3.
   - Obligation: POB-U3.

4. Change unnamed span filtering to keep only selected-span ends in `prev_end`
   and to allow adjacent spans.
   - Evidence: F4.
   - Obligation: POB-U2.

## Recommended tests for a later non-benchmark pass

Do not edit tests in this task. When test edits are allowed, add cases covering:

- `simplify_regex(r'^entries/(?P<pk>[^/.]+)/relationships/(?P<related_field>\w+)')`
  should return `/entries/<pk>/relationships/<related_field>`.
- `simplify_regex(r'^a/(\w+)')` should return `/a/<var>`.
- `simplify_regex(r'^a/(\w+)/b/(\d+)')` should return
  `/a/<var>/b/<var>`.
- `simplify_regex(r'^a/(\w+)(\d+)')` should return `/a/<var><var>`.
- `simplify_regex(r'^a/((x)y(z))')` should return `/a/<var>`.

## Residual cautions

- The FVK proof is constructed, not machine-checked.
- Full Python and full regular-expression semantics are outside the mini-model.
- Keep integration tests for admindocs URL extraction because this proof covers
  only the helper span logic and public wrapper composition.
