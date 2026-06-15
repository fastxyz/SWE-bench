# FVK Spec: django__django-13033

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target behavior is the ordering-resolution decision in
`SQLCompiler.find_ordering_name()` for string orderings that resolve to a
foreign key field, especially multi-hop paths such as `record__root_id`.

The observable under audit is whether a resolved ordering:

- orders directly by the resolved concrete target column after `trim_joins()`;
- expands to the related model's `Meta.ordering`; and
- applies the explicit `order_by()` direction to the intended column.

Invalid field names, transform failures, SQL backend differences, and complete
query rendering are outside this proof slice. They are handled by existing
resolver/compiler paths and are only framed here.

## Intent Spec

INT-001: `order_by()` overrides a queryset/model's default ordering with the
fields explicitly supplied by the caller.

INT-002: Ordering by a relation name, for example `record__root`, uses the
related model's default ordering when that related model defines
`Meta.ordering`.

INT-003: Ordering by a relation `_id` / FK attname, for example
`record__root_id`, is an explicit request to order by the concrete FK column,
not by the related object. It must not inherit the related model's default
ordering.

INT-004: The explicit sign on the user-supplied ordering controls the direction
of direct FK-column ordering: `record__root_id` is ascending by default and
`-record__root_id` is descending.

INT-005: The self-referential nature of the target FK does not justify a
different ordering rule. The attname rule is path-local and applies after each
lookup segment is resolved.

INT-006: Existing behavior for direct FK attnames such as `author_id`, relation
names such as `author`, non-relation fields, and the `pk` shortcut must be
preserved.

## Public Evidence Ledger

E-001 source=problem quote=`order_by("record__root_id")` produced `ORDER BY
T3."id" DESC`; semantic obligation=reported legacy behavior is suspect because
it expands to related ordering and flips direction; status=encoded as
FINDING F-001 and proof obligations PO-001 through PO-004.

E-002 source=problem quote=`order_by('record__root_id') should result in ORDER
BY root_id`; semantic obligation=multi-hop FK attname must directly order by the
FK column; status=encoded in `django-ordering-spec.k` claim 1 and PO-001.

E-003 source=problem quote=`order_by('record__root') should use
OneModel.Meta.ordering`; semantic obligation=relation-name ordering must still
expand related default ordering; status=encoded in claim 2 and PO-005.

E-004 source=docs quote=`If you try to order by a field that is a relation to
another model, Django will use the default ordering on the related model`;
semantic obligation=relation-name lookup expands; status=encoded in INT-002.

E-005 source=docs quote=`explicitly order by the relation _id field ... or the
referenced one`; semantic obligation=`_id` is a public escape hatch from related
default ordering; status=encoded in INT-003.

E-006 source=public-test quote=`ordering by a foreign key by its attribute name
prevents the query from inheriting its related model ordering option`;
semantic obligation=direct FK attname behavior must be preserved and generalized
to joined paths; status=encoded in claim 3 and PO-006.

E-007 source=code quote=`get_field() should also be able to fetch a field by
attname`; semantic obligation=`root_id` resolves to the `root` FK field whose
`attname` is `root_id`; status=implementation fact used in proof.

E-008 source=code quote=`append the default ordering ... unless it is the pk
shortcut or the attribute name of the field that is specified`; semantic
obligation=compiler branch already intends an attname exception; status=used to
confirm V1 changes comparison granularity, not policy.

## Formal Core

The abstract K core is in:

- `fvk/mini-django-ordering.k`
- `fvk/django-ordering-spec.k`

It models only the branch predicate:

```text
classify(field(is_relation, attname, related_opts_has_ordering),
         lookup(full_name, final_piece, is_pk_shortcut))
  -> direct | expand
```

The V1 code implements the model by comparing `field.attname` with
`pieces[-1]`, the final lookup segment, not with `name`, the whole lookup path.

## Adequacy Audit

Claim 1 says `record__root_id` with final piece `root_id` and field attname
`root_id` classifies as `direct`. This passes INT-003 and E-002/E-005.

Claim 2 says `record__root` with final piece `root` and field attname `root_id`
classifies as `expand`. This passes INT-002 and E-003/E-004.

Claim 3 says a one-hop `author_id` FK attname classifies as `direct`. This
passes INT-006 and E-006.

Claim 4 says `pk` shortcut classifies as `direct`. This passes INT-006 and the
existing compiler comment.

No claim relies on legacy pre-fix SQL as expected behavior; the legacy SQL is
recorded only as suspect observed behavior.

## Compatibility Audit

No public method signature, return type, or dispatch protocol changed. The only
source edit is inside the existing predicate in `find_ordering_name()`.

Internal callsites of `find_ordering_name()` still pass the same arguments and
receive the same return shape. The recursion and `already_seen` loop guard are
unchanged.
