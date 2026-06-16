# FVK Specification: `ModelAdmin.lookup_allowed()`

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited production unit is
`repo/django/contrib/admin/options.py::BaseModelAdmin.lookup_allowed()`.
The observable result is the returned boolean for a query-string lookup path.

The proof abstraction models the part of the method that walks a lookup path
through model metadata and compares candidate field paths with configured admin
filters. The abstraction treats Django metadata queries as resolved symbolic
facts:

- whether a part resolves to a field on the current model,
- whether a resolved field is relational,
- whether a resolved field is one of the previous relation's target fields,
- which configured paths appear in `list_filter`.

This abstraction is property-complete for the issue because the defect is the
loss of one lookup-path segment during target-field normalization.

## Intent Spec

I1. `lookup_allowed()` must allow model local fields, configured
`ModelAdmin.list_filter` field paths, and required `limit_choices_to` lookups.

I2. A `list_filter` field path may span relations.

I3. If a path is explicitly configured in `list_filter`, `lookup_allowed()` must
accept that path even when an intermediate primary-key field is itself a
relation.

I4. Target-field aliases must continue to be accepted. A URL parameter generated
by an admin filter may append the related target field and a lookup suffix while
still representing the configured filter path.

I5. A lookup that reaches a real field beyond the configured filter path is not
allowed merely because the prefix is configured.

## Public Evidence Ledger

E1. Source: docs, `repo/docs/ref/contrib/admin/index.txt`.
Quote: "By default, `lookup_allowed()` allows access to a model's local fields,
field paths used in `ModelAdmin.list_filter`..."
Obligation: configured `list_filter` paths must be accepted.
Status: encoded by PO3 and PO4.

E2. Source: docs, `repo/docs/ref/contrib/admin/filters.txt`.
Quote: "Field names in `list_filter` can also span relations using the `__`
lookup."
Obligation: relation-spanning configured filter paths are in-domain.
Status: encoded by PO3.

E3. Source: prompt issue.
Quote: "`restaurant__place__country` ... isn't in `list_filter`" after it is
shortcutted to "`restaurant__country`".
Obligation: a relational primary-key field such as `place` must not make the
configured actual path unrecognizable.
Status: encoded by PO3 and FINDING F1.

E4. Source: prompt issue.
Quote: "And you can't add `restaurant__country` to `list_filter` because
`country` isn't actually on `restaurant`."
Obligation: the normalized path cannot replace the actual configured path when
that replacement is not a valid Django field path.
Status: encoded by PO3 and PO5.

E5. Source: code, `repo/django/contrib/admin/filters.py`.
Quote: `self.lookup_kwarg = "%s__%s__exact" % (field_path, field.target_field.name)`.
Obligation: a configured related filter path must also accept admin-generated
lookup keys with trailing target-field aliases and lookup suffixes.
Status: encoded by PO4.

E6. Source: public test, `repo/tests/modeladmin/tests.py`.
Quote: `lookup_allowed("employee__department__code", "test_value")` is expected
to be `True`.
Obligation: target-field aliases such as `to_field="code"` remain allowed.
Status: encoded by PO4.

E7. Source: docs, `repo/docs/ref/contrib/admin/index.txt`.
Quote: query-string lookups "must be sanitized to prevent unauthorized data
exposure."
Obligation: accepting configured paths must not accept arbitrary real fields
beyond the configured path.
Status: encoded by PO5.

## Formal Model

Let `resolved_parts(lookup)` be the maximal list of lookup segments that resolve
to Django fields before lookup transforms, lookup names, or nonexistent fields
stop field traversal.

Let `fields(lookup)` be the corresponding field objects.

Let `collapsed_parts` be the V1-normalized path produced by the existing Django
rule: append a resolved part unless it is a target field of the previous
relation.

Let `actual_parts` be the resolved field path without target-field collapsing.

Let `strip_target_suffixes(actual_parts)` be every prefix obtained by repeatedly
removing a trailing field when that field is a target field of the previous
relation.

Let `valid_lookups` be the set consisting of `date_hierarchy`, configured
`list_filter` paths, tuple/list filter first elements, and
`SimpleListFilter.parameter_name` values.

The V1 decision rule under audit is:

```text
if related_fkey_lookup_matches(lookup, value):
    return True

if len(collapsed_parts) <= 1:
    return True

candidates =
    { join(collapsed_parts),
      join(collapsed_parts + [last_seen_part]),
      join(actual_parts) }
    union strip_target_suffixes(actual_parts)

return candidates intersects valid_lookups
```

## K-Style Claims

The companion K-style artifacts are:

- `fvk/mini-admin-lookup.k`
- `fvk/lookup-allowed-spec.k`

The same claims are summarized here:

```k
// CLAIM-ISSUE-ACTUAL-PATH
// restaurant__place__country is accepted when it is the configured list_filter.
claim <k> lookupAllowed(issueLookup, issueFilterSet) => true </k>

// CLAIM-RELATED-FILTER-TARGET-SUFFIX
// restaurant__place__country__id__exact is accepted for the configured
// restaurant__place__country related filter.
claim <k> lookupAllowed(issueGeneratedLookup, issueFilterSet) => true </k>

// CLAIM-DIRECT-RELATION-TARGET-ALIAS
// restaurant__place__exact remains accepted for list_filter restaurant.
claim <k> lookupAllowed(directGeneratedLookup, directFilterSet) => true </k>

// CLAIM-NO-REAL-FIELD-BEYOND-FILTER
// restaurant__place__country__name is not accepted by the configured
// restaurant__place__country filter because name is a real field beyond it.
claim <k> lookupAllowed(realFieldBeyondLookup, issueFilterSet) => false </k>
```

## Formal Spec English

FE1. The reported lookup resolves to the actual field path
`restaurant__place__country`; because that exact path is configured in
`list_filter`, the result is `True`.

FE2. A related-filter URL key that appends the target primary-key field and a
lookup suffix strips the trailing target-field alias and compares the configured
path; the result is `True`.

FE3. A direct relation filter whose remote primary key is relational remains
allowed through the existing collapsed-path rule; the result is `True`.

FE4. A lookup that continues from the configured related filter to a real field
such as `name` has actual path `restaurant__place__country__name` and no valid
candidate equal to `restaurant__place__country`; the result is `False`.

## Spec Audit

FE1 passes I2 and I3, supported by E2, E3, and E4.

FE2 passes I4, supported by E5 and E6.

FE3 passes I4 and the local/direct relation behavior in I1, supported by E1 and
E5.

FE4 passes I5, supported by E7.

No formal-English clause is legacy-derived without public evidence. The only
implementation-derived facts are the metadata abstraction and the existing
target-field alias mechanism, both used as proof machinery and constrained by
public compatibility obligations.

## Public Compatibility Audit

Changed public symbol: `BaseModelAdmin.lookup_allowed(self, lookup, value)`.

Signature compatibility: unchanged.

Return type: unchanged boolean.

Callers: `repo/django/contrib/admin/views/main.py` checks the boolean and raises
`DisallowedModelAdminLookup` on false. The caller contract is unchanged.

Subclass/override compatibility: no new parameters, no new callback protocol,
and no changed dispatch shape. Existing overrides continue to receive the same
arguments.

Producer/consumer compatibility: `FieldListFilter` subclasses can still produce
lookup keys with target fields and suffixes. V1 keeps these accepted through the
collapsed path and stripped-target candidates.
