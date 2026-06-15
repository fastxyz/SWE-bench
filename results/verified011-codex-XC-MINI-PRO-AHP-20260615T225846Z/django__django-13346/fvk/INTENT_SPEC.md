# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Required behavior

I1. For a `JSONField` key transform and a direct literal RHS list, `key__in=[v]` must match the same rows as `key=v` for each non-`None` value `v` in the list.

I2. The behavior applies on MySQL, SQLite, and Oracle, where JSON key extraction returns backend-specific SQL/JSON values and the RHS must be adapted into the same comparison domain.

I3. PostgreSQL already has native JSON support for this path; the fix must preserve its existing generic `IN` behavior.

I4. A single-element RHS list is in scope. The public issue explicitly identifies single-element `__in` lists as the failing case.

I5. Oracle string RHS values are in scope. The public issue explicitly says Oracle fails when the list contains strings.

I6. The normal `In` lookup mechanics remain in scope: direct RHS lists still deduplicate, discard SQL `NULL` (`None`), raise `EmptyResultSet` for an empty effective list, preserve expression/subquery handling, and split large lists where the backend requires it.

I7. SQL generated for literal string values must remain a valid SQL literal for the value being represented. This is a default public ORM safety/validity assumption and is required for "strings" as a family, not only strings without quotes.

## Out of scope or preserved behavior

O1. This audit does not change generic `field__in=[None]` semantics. The generic `In` lookup removes `None` because SQL `NULL` is never equal to anything; no public evidence in this issue requires redefining JSON key-transform `__in` to match JSON null.

O2. This audit does not change subquery or expression RHS behavior beyond preserving the existing generic expression compilation path.
