# FVK Specification: django__django-12774

Status: constructed, not machine-checked.

## Scope

The audited unit is `QuerySet.in_bulk()` in `repo/django/db/models/query.py`.
The behavioral change is the validation of `field_name` before the query is
evaluated. Query batching, filtering, ordering reset, and dictionary
construction are frame conditions: they must behave as before once the
`field_name` validation accepts the field.

## Public Intent Ledger

E1. Source: prompt / issue title.

Quoted evidence: "Allow QuerySet.in_bulk() for fields with total
UniqueConstraints."

Semantic obligation: `in_bulk()` must not reject a field merely because its
global uniqueness is declared with a total `UniqueConstraint` rather than
`unique=True`.

Status: encoded in SPEC-ACCEPT-UNIQUE-CONSTRAINT and CLAIM-ACCEPT-CONSTRAINT.

E2. Source: prompt / issue description.

Quoted evidence: "If a field is unique by UniqueConstraint instead of
unique=True running in_bulk() on that field will fail."

Semantic obligation: for a model with `UniqueConstraint(fields=["slug"], ...)`,
`Article.objects.in_bulk(field_name="slug")` is an in-domain call and should
pass the unique-field validation.

Status: encoded in SPEC-ACCEPT-UNIQUE-CONSTRAINT and finding F1.

E3. Source: public method docstring.

Quoted evidence: "Return a dictionary mapping each of the given IDs to the
object with that ID."

Semantic obligation: an alternate `field_name` is valid only when a single
object is determined by each key. A composite unique constraint does not make
one member field unique by itself.

Status: encoded in SPEC-REJECT-NON-SINGLE and finding F3.

E4. Source: implementation / public error behavior.

Quoted evidence: `in_bulk()'s field_name must be a unique field but %r isn't.`

Semantic obligation: a non-primary-key field that is not individually unique
must still raise `ValueError` with the existing message.

Status: encoded in SPEC-REJECT-NON-UNIQUE.

E5. Source: metadata implementation comment.

Quoted evidence from `Options.total_unique_constraints`: "Return a list of
total unique constraints. Useful for determining set of fields guaranteed to be
unique for all rows."

Semantic obligation: reuse `opts.total_unique_constraints` as the public
metadata source for unconditional `UniqueConstraint`s, rather than inspecting
all `Meta.constraints` directly.

Status: encoded in SPEC-TOTAL-CONSTRAINT-SOURCE.

E6. Source: implementation of `Options.total_unique_constraints`.

Quoted evidence: it includes `UniqueConstraint` instances where
`constraint.condition is None`.

Semantic obligation: conditional unique constraints must not satisfy
`in_bulk()`'s single-key uniqueness requirement.

Status: encoded in SPEC-REJECT-CONDITIONAL and finding F4.

E7. Source: implementation of `Model._check_local_fields()`.

Quoted evidence: local fields are indexed by both `field.name` and, when
present, `field.attname`.

Semantic obligation: for relation fields, a total single-field
`UniqueConstraint` declared using either the field name or its attname should be
recognized as proving the same column unique.

Status: V1 gap resolved by V2; encoded in SPEC-ACCEPT-ATTNAME and finding F2.

## Intent-First Contract

For `QuerySet.in_bulk(id_list=None, *, field_name='pk')`:

SPEC-ACCEPT-PK: If `field_name == 'pk'`, the unique-field validation accepts
the call.

SPEC-ACCEPT-FIELD-UNIQUE: If `field_name != 'pk'` and
`opts.get_field(field_name).unique` is true, the validation accepts the call.

SPEC-ACCEPT-UNIQUE-CONSTRAINT: If `field_name != 'pk'`,
`opts.get_field(field_name).unique` is false, and there exists a constraint in
`opts.total_unique_constraints` whose `fields` tuple has exactly one member
matching either the resolved field's `name` or `attname`, the validation accepts
the call.

SPEC-REJECT-NON-UNIQUE: If none of the accept cases hold, the validation raises
`ValueError("in_bulk()'s field_name must be a unique field but %r isn't." %
field_name)`.

SPEC-REJECT-NON-SINGLE: A multi-field `UniqueConstraint` does not satisfy
SPEC-ACCEPT-UNIQUE-CONSTRAINT for any individual member field.

SPEC-REJECT-CONDITIONAL: A conditional `UniqueConstraint` is not in
`opts.total_unique_constraints` and does not satisfy
SPEC-ACCEPT-UNIQUE-CONSTRAINT.

SPEC-FRAME-QUERY-BEHAVIOR: For every accepted `field_name`, `id_list=None`,
empty `id_list`, batched filtering, unbatched filtering, ordering reset, and
the returned `{getattr(obj, field_name): obj for obj in qs}` behavior are
unchanged from the pre-existing implementation.

## Formalization Summary

The K artifacts model the validation predicate as `validate(fieldName, field,
constraints)`, where a field carries `(name, attname, unique)` and constraints
carry `(fieldIdentifier, qualifiesAsSingleTotal)`. This abstraction preserves
the property under audit: whether the call is accepted or rejected for a
single lookup key. It intentionally abstracts away database execution because
the source edit does not alter that path.

Formal files:

- `fvk/mini-inbulk.k`: a small K fragment for the validation decision.
- `fvk/in-bulk-spec.k`: reachability claims for primary key, `unique=True`,
  single total `UniqueConstraint`, attname matching, and rejection.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-inbulk.k --backend haskell
kast --backend haskell fvk/in-bulk-spec.k
kprove fvk/in-bulk-spec.k
```
