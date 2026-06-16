# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 source change for `django__django-15814`.
The target is the deferred-loading mask built by
`Query.deferred_to_data()` and consumed by `SQLCompiler.get_default_columns()`
and `RelatedPopulator`.

The formal model is intentionally small. It does not model SQL generation,
database rows, aliases, or the whole Django ORM. It preserves the property that
distinguishes the failure from the fix: whether the related concrete model's
primary key is present under the same model key used by default-column
selection.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- `E1` and `E2`: the reported proxy `select_related()` plus `only()` query must
  not omit the related primary key and crash with `ValueError: 'id' is not in
  list`.
- `E3`: a related model may be a proxy while its concrete fields belong to its
  concrete model.
- `E6` and `E7`: the mask key must agree with the key later used by
  `get_default_columns()` and `RelatedPopulator`.
- `E4`: the public hint points to normalizing `cur_model`, not to a later
  special case.

## Functional Contract

For a valid `only()`/`select_related()` path that follows relation field `R`
from model `A` to target model `T`, where `T` may be a proxy model, and then
selects concrete related field `F`:

1. `deferred_to_data()` must normalize the traversal target to
   `T._meta.concrete_model` before adding the target primary key to
   `must_include`.
2. In `only()` mode, the merged load mask for `T._meta.concrete_model` must
   include both the related primary key attname and the requested concrete field
   attname.
3. `get_default_columns()` for the related model must select the related primary
   key column whenever it selects the requested related field column.
4. `RelatedPopulator` must therefore be able to find
   `model_cls._meta.pk.attname` in `init_list`.
5. For non-proxy targets, `T._meta.concrete_model is T`, so behavior is
   unchanged.

## K Claims

The formal claims are in `fvk/django-deferred-spec.k`.

- `PROXY-ONLY-PK`: the proxy-target issue shape yields a load mask and selected
  field set containing both `idField` and `nameField` for the concrete related
  model.
- `CONCRETE-TARGET-FRAME`: a concrete target yields the same mask and selected
  field membership, showing that normalization is a frame-preserving identity
  for non-proxy targets.
- `LEGACY-PROXY-COUNTEREXAMPLE`: the pre-fix behavior stores `idField` under the
  proxy key and therefore omits it from concrete default-column selection. This
  claim localizes the bug and is not a desired production behavior.

## Preconditions and Assumptions

- Field paths are valid and have already passed Django's normal field lookup
  validation.
- The path segment being audited is a relation eligible for `select_related()`.
- Proxy models do not add concrete database fields; their concrete fields are
  owned by the concrete model.
- The proof is partial correctness over mask construction and field selection.
  It does not prove termination, SQL execution, database null handling, or
  backend-specific behavior.

