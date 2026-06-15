# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The formal core in `fvk/mini-django-ordering.k` defines:

```text
classify(field(is_relation, attname, related_opts_has_ordering),
         lookup(full_name, final_piece, is_pk_shortcut))
  -> direct | expand
```

The spec claims in `fvk/django-ordering-spec.k` establish:

1. `classify(field(true, "root_id", true), lookup("record__root_id",
   "root_id", false)) => direct`.
2. `classify(field(true, "root_id", true), lookup("record__root", "root",
   false)) => expand`.
3. `classify(field(true, "author_id", true), lookup("author_id",
   "author_id", false)) => direct`.
4. `classify(field(true, "id", true), lookup("pk", "pk", true)) => direct`.

## Constructed Proof Sketch

For claim 1, symbolic execution matches the rule:

```text
classify(field(true, A, true), lookup(_N, P, false)) => direct
requires A ==String P
```

with `A = "root_id"` and `P = "root_id"`. The side condition holds by string
reflexivity, so `record__root_id` classifies as direct. In the Django source,
this corresponds to `getattr(field, 'attname', None) != pieces[-1]` evaluating
false, so the related-default-ordering branch is skipped.

For claim 2, symbolic execution matches the rule:

```text
classify(field(true, A, true), lookup(_N, P, false)) => expand
requires A =/=String P
```

with `A = "root_id"` and `P = "root"`. The side condition holds, so
`record__root` still expands related model default ordering.

For claim 3, symbolic execution uses the same direct rule as claim 1 with
`A = P = "author_id"`. Since one-segment lookups have `pieces[-1] == name`, V1
preserves the direct FK attname behavior already documented by the public test.

For claim 4, symbolic execution matches:

```text
classify(field(true, _A, true), lookup(_N, _P, true)) => direct
```

which frames the existing `pk` shortcut behavior.

## Source-Level Composition

The abstract classifier connects to Django source as follows:

1. `find_ordering_name()` strips the sign with `get_order_dir()` and computes
   `pieces = name.split(LOOKUP_SEP)`.
2. `_setup_joins()` resolves the lookup path. `Options.get_field()` can resolve
   both field names and attnames, so the final piece `root_id` resolves to the
   `root` `ForeignKey` whose `attname` is `root_id`.
3. V1 compares that `attname` with `pieces[-1]`. For `record__root_id`, the
   comparison is equal, so related default ordering is not appended.
4. The existing direct branch calls `query.trim_joins()`. The final direct FK
   join can be trimmed because the target remote primary-key column is already
   represented by the local FK column on the previous alias.
5. The returned `OrderBy` wraps the trimmed FK column and uses the original
   `descending` flag from the caller's `order_by()` string.

This discharges PO-001 through PO-004 for the reported bug and PO-005 through
PO-008 for the frame conditions.

## Machine-Check Commands Not Run

The commands to run later are:

```sh
kompile fvk/mini-django-ordering.k --backend haskell
kast --backend haskell -I fvk fvk/django-ordering-spec.k
kprove -I fvk fvk/django-ordering-spec.k
```

Expected result: `kprove` returns `#Top` for the four classifier claims.

## Test Recommendations

No test files were modified. Because this proof is constructed but not
machine-checked, no existing tests should be removed.

Useful tests to keep or add in a normal development setting:

- `order_by("record__root_id")` orders by the `root_id` column and does not add
  the self-join used only for related default ordering.
- `order_by("-record__root_id")` orders by the `root_id` column descending.
- `order_by("record__root")` still expands `OneModel.Meta.ordering`.
- Existing one-hop `order_by("author_id")` behavior remains unchanged.

## Residual Risk

This proof is partial and abstract. It proves the classification predicate and
uses source-level reasoning for the existing join-trimming branch. It does not
machine-check full Django SQL rendering, database backend quoting, or query
execution.
