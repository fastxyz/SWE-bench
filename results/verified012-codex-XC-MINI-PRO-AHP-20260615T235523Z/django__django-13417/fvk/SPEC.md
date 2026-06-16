# FVK Spec

Status: constructed, not machine-checked. Tests, Python, and K tooling were not
run.

## Scope

Target function/property: `django.db.models.query.QuerySet.ordered`.

The proof abstracts the relevant query state into six booleans:

- `isEmpty`: `isinstance(self, EmptyQuerySet)`.
- `hasExtraOrderBy`: truthiness of `self.query.extra_order_by`.
- `hasExplicitOrderBy`: truthiness of `self.query.order_by`.
- `defaultOrderingEnabled`: `self.query.default_ordering`.
- `hasMetaOrdering`: truthiness of `self.query.get_meta().ordering`.
- `hasGroupBy`: truthiness of `self.query.group_by`.

This abstraction is property-complete for the audited branch because these are
exactly the values read by `QuerySet.ordered` and the corresponding compiler
ordering decision relevant to default `Meta.ordering` suppression.

## Intent Ledger

The public evidence ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.
Critical entries:

- E1: The issue states that `ordered` should say whether the queryset will be
  ordered.
- E2: The issue shows a grouped annotated queryset whose SQL has no `ORDER BY`
  while `ordered` reports `True`.
- E3: The public hint says `Meta.ordering` does not affect `GROUP BY` queries.
- E5: The compiler selects `_meta_ordering` only for default model ordering and
  then drops it when grouping is emitted.

## Intended Orderedness Formula

For the audited state space:

```text
ordered_expected =
    isEmpty
    or hasExtraOrderBy
    or hasExplicitOrderBy
    or (
        defaultOrderingEnabled
        and hasMetaOrdering
        and not hasGroupBy
    )
```

The V1 source implements this formula:

```python
if isinstance(self, EmptyQuerySet):
    return True
if self.query.extra_order_by or self.query.order_by:
    return True
elif (
    self.query.default_ordering and
    self.query.get_meta().ordering and
    not self.query.group_by
):
    return True
else:
    return False
```

## Formal Core

Formal files:

- `fvk/mini-queryset-ordered.k`: a minimal K model of the boolean decision and
  compiler-derived effective ordering source.
- `fvk/queryset-ordered-spec.k`: reachability claims for the general equivalence
  and boundary cases.

Primary K claim:

```k
claim <k> ordered(QS:QueryState) => compilerOrdered(QS) </k>
  [all-path]
```

Concrete issue claim:

```k
claim <k> ordered(qs(false, false, false, true, true, true)) => false </k>
  [all-path]
```

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the formal claims, and
`fvk/SPEC_AUDIT.md` compares them to `fvk/INTENT_SPEC.md`. All claims pass the
adequacy audit. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records that the public API
shape is unchanged.
