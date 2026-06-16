# Baseline Notes

## Root cause

`Query.deferred_to_data()` builds the field mask used by `only()` and `defer()`.
When it followed a relation whose target was a proxy model, it stored required
fields for the proxy class in `must_include`, while the selected concrete fields
were tracked under the concrete model class.

For `select_related("custom").only("custom__name")` where `custom` points to a
proxy model, this split meant the related model's primary key was recorded under
the proxy model but `get_default_columns()` checked the concrete field's model.
The primary key column was then omitted from the related select list, and
`RelatedPopulator` crashed because the proxy instance could not be initialized
without its primary key attname in `init_list`.

## Changed files

`repo/django/db/models/sql/query.py`

Normalized each relation target in `Query.deferred_to_data()` to its concrete
model before updating `opts` and adding required fields. This keeps
`must_include`, `seen`, and the later column-selection logic keyed consistently
for proxy relations, so the related primary key remains selected alongside the
explicit `only()` fields.

## Assumptions and alternatives

I assumed the intended behavior is for `only()` through a `select_related()`
proxy relation to behave like the same relation through the concrete model: load
the requested field plus the required linking and primary key fields.

I considered changing `opts` alone to `cur_model._meta.concrete_model._meta`,
but leaving `cur_model` as the proxy would still allow mixed proxy/concrete keys
in the deferred-loading dictionaries. Normalizing `cur_model` itself is more
targeted to the actual inconsistency.

I also considered changing `get_default_columns()` or `RelatedPopulator` to
special-case proxy models, but the omission is introduced earlier when the field
mask is built. Fixing the mask construction avoids adding proxy-specific logic to
the later selection and population paths.
