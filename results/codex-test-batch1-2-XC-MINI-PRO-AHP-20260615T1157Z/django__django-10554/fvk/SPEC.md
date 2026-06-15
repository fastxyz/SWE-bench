# Spec

Status: constructed, not machine-checked.

## Scope

This FVK run audits V1 for `django__django-10554`. The target code is
`repo/django/db/models/sql/query.py::Query.clone()` as used by combined
queryset derivation through `QuerySet._clone()` and `Query.chain()`.

The model abstracts a Django `Query` to:

- a selected column width;
- an order-by position, where `0` means unordered;
- zero or two component child query references.

This abstraction preserves the failing observable from the issue:
`ORDER BY position 4 is not in select list`.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-1 and E-3 require that evaluating a derived `values_list('pk')` queryset
  must not break subsequent evaluation of the source ordered union.
- E-2 defines the observable failure: the original union orders by a selected
  position that disappeared from its component select list.
- E-4 requires copying before query-state mutation.
- E-5 identifies `Query.clone()` as the derivation boundary.
- E-7 is the compatibility reason not to change set-operation construction.

## Formal Contract

For an original ordered combined query `orig` with component queries `c1` and
`c2`, all having selected column width `4`, deriving a values-list queryset:

```text
deriveValuesPk(orig, derived, d1, d2)
```

must:

1. create `derived` with cloned component queries `d1` and `d2`;
2. narrow only the derived query and its derived components to width `1`;
3. preserve `orig`, `c1`, and `c2` unchanged;
4. leave `assertOrderable(orig)` successful, because `orig` still orders by
   position `4` and both original components still expose width `4`.

The formal claim is `ORDERED-UNION-DERIVED-VALUES-FRAME` in
`fvk/query-clone-spec.k`.

## Frame Conditions

FC-1. `orig` remains `query(4, 4, kids(c1, c2))`.

FC-2. `c1` and `c2` remain width `4`.

FC-3. `derived`, `d1`, and `d2` may be width `1`.

FC-4. No public method signature, return shape, or call protocol changes.

## Model Adequacy

The model distinguishes the passing and failing cases:

- Passing V1 case: `derived` points at `d1`/`d2`, while `orig` still points at
  `c1`/`c2`; narrowing derived children leaves `assertOrderable(orig)` true.
- Failing pre-V1 shallow clone case: `derived` points at `c1`/`c2`; narrowing
  derived children changes `c1`/`c2` to width `1`; `assertOrderable(orig)` fails
  because `4 <= 1` is false.

That discriminator is independent of SQL string formatting and captures the
bug's cause.
