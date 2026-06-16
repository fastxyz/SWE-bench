# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Commands Not Run

The commands that would machine-check the lightweight K-style artifacts are:

```sh
kompile fvk/mini-admin-lookup.k --backend haskell
kast --backend haskell fvk/lookup-allowed-spec.k
kprove fvk/lookup-allowed-spec.k
```

Expected result in a K environment: `#Top` for the stated claims.

## Proof Shape

`lookup_allowed()` has no loop in the audited code path. The proof is a finite
case split over the method's decision branches:

1. `limit_choices_to` match returns `True`.
2. Resolved collapsed relation path length at most one returns `True`.
3. Otherwise, build `valid_lookups`.
4. Build `valid_lookup_candidates` from the collapsed path, the collapsed path
plus the last seen part, the actual resolved field path, and actual-path
prefixes obtained by stripping trailing target fields.
5. Return whether candidates intersect `valid_lookups`.

The only V1 change is in step 4.

## Claim 1: Reported Lookup Is Accepted

Initial symbolic state:

```text
lookup = "restaurant__place__country"
valid_lookups = {"restaurant__place__country"}
metadata:
  Waiter.restaurant is relational, target field Restaurant.place
  Restaurant.place is relational, target field Place.id
  Place.country is relational, target field Country.id
```

Symbolic execution:

```text
part restaurant:
  relation_parts = ["restaurant"]
  field_parts = ["restaurant"]

part place:
  place is target field of previous relation restaurant
  relation_parts remains ["restaurant"]
  field_parts = ["restaurant", "place"]

part country:
  country is not target field of previous relation place
  relation_parts = ["restaurant", "country"]
  field_parts = ["restaurant", "place", "country"]
```

Since `len(relation_parts) = 2`, validation checks candidates:

```text
{
  "restaurant__country",
  "restaurant__country__country",
  "restaurant__place__country"
}
```

The candidate `restaurant__place__country` intersects `valid_lookups`, so the
result is `True`.

Discharges: PO3 and F1.

## Claim 2: Generated Related-Filter Lookup Is Accepted

Initial symbolic state:

```text
lookup = "restaurant__place__country__id__exact"
valid_lookups = {"restaurant__place__country"}
metadata includes target(country) = id
```

Symbolic execution resolves fields through `id` and stops before `exact`:

```text
field_parts =
  ["restaurant", "place", "country", "id"]
relation_parts =
  ["restaurant", "country"]
```

The initial candidates do not include the configured filter path, so the
trailing-target loop checks the suffix:

```text
id is target field of country
strip id:
  field_parts = ["restaurant", "place", "country"]
  add "restaurant__place__country"

country is not target field of place
stop stripping
```

The candidate `restaurant__place__country` intersects `valid_lookups`, so the
result is `True`.

Discharges: PO4 and F2.

## Claim 3: Direct Relation Target Alias Is Preserved

Initial symbolic state:

```text
lookup = "restaurant__place__exact"
valid_lookups = {"restaurant"}
metadata:
  Waiter.restaurant targets Restaurant.place
```

Symbolic execution:

```text
part restaurant:
  relation_parts = ["restaurant"]
  field_parts = ["restaurant"]

part place:
  place is target field of previous relation restaurant
  relation_parts remains ["restaurant"]
  field_parts = ["restaurant", "place"]

part exact:
  does not resolve as a field on Place
  traversal stops
```

`len(relation_parts) = 1`, so the unchanged direct-relation branch returns
`True`.

Discharges: PO2, PO4, and F3.

## Claim 4: Real Field Beyond Configured Filter Is Rejected

Initial symbolic state:

```text
lookup = "restaurant__place__country__name"
valid_lookups = {"restaurant__place__country"}
metadata:
  Country.name is a real field
  Country.name is not target field of Place.country
```

Symbolic execution:

```text
field_parts =
  ["restaurant", "place", "country", "name"]
relation_parts =
  ["restaurant", "country", "name"]
```

Candidates:

```text
{
  "restaurant__country__name",
  "restaurant__country__name__name",
  "restaurant__place__country__name"
}
```

The trailing-target loop does not strip `name` because it is not a target field
of `country`. The candidates do not intersect `valid_lookups`, so the result is
`False`.

Discharges: PO5 and F4.

## Adequacy Check

The formal claims cover the reported path, the generated related-filter suffix
path, the direct relation alias compatibility path, and a negative security
path. Those cover the public-intent obligations in `fvk/SPEC.md`.

No claim depends on hidden tests, evaluator output, or upstream patches.

## Residual Risk

The proof is not machine-checked. The lightweight K-style model abstracts
Django metadata resolution into symbolic facts, so a future machine proof would
need either a fuller Python/Django semantics or trusted metadata assumptions.

Termination is trivial for the modeled path traversal because the method
iterates over the finite `lookup.split(LOOKUP_SEP)` list, but total correctness
was not separately machine-proved.

No test redundancy is recommended. Existing tests should be kept unless the
emitted proof artifacts are machine-checked and mapped to specific test cases.
