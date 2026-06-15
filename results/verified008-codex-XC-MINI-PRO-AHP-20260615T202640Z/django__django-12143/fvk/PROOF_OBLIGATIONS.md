# Proof Obligations

Status: constructed, not machine-checked.

## O1: Prefix domain includes regex metacharacters

For all string prefixes `P`, including strings containing regex metacharacters,
and all primary-key names `K` in the admin helper's domain, the matching
contract is defined over literal field-name text.

Provenance: E1, E2.

## O2: Escaped dynamic fragments denote literal strings

For every string `S` in the domain, the Python regex fragment produced by
`re.escape(S)` matches exactly the literal string `S` and does not interpret any
character of `S` as regex syntax.

Provenance: E3 and Python regex semantics assumed by the public issue's proposed
fix.

## O3: Key-language equivalence

For all POST keys `KEY`, prefixes `P`, and primary-key names `K`, the compiled
V1 regex:

```text
re.escape(P) + "-\d+-" + re.escape(K) + "$"
```

matches an in-domain generated field name iff `KEY` has the literal shape:

```text
P + "-" + one_or_more_decimal_digits + "-" + K
```

Provenance: E1, E2, E3, E4.

## O4: Selection soundness

Every value returned by `_get_edited_object_pks(request, P)` belongs to a POST
item whose key satisfies O3.

Provenance: E5.

## O5: Selection completeness

Every POST item whose key satisfies O3 contributes its value to the returned
list.

Provenance: E5.

## O6: Order preservation

The returned list preserves the order of matching entries from
`request.POST.items()`.

Provenance: E5.

## O7: Compatibility frame

The patch preserves the helper signature, caller protocol, return container
shape, and queryset validation flow.

Provenance: E5 and source callsite search.

## O8: Same-pattern source coverage

Within the allowed `repo/django` source tree, no other
`re.compile/search/match(...format(...))` occurrence remains that matches the
issue's described construction pattern.

Provenance: E6.

