# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## Claims

The formal core is in:

- `fvk/mini-query-alias.k`
- `fvk/query-alias-spec.k`

The proof covers the alias-normalization slice that produces the reported
failure:

1. `bumpExcept()` preserves excluded aliases and produces a `change_map` whose
   keys and values are disjoint.
2. `combineNormalize()` preserves the RHS initial alias and eliminates the
   overlapping-key/value shape before `combine()` starts join merging.
3. The combine path performs this normalization on an isolated clone, preserving
   the RHS frame condition.

## Proof Sketch

### PO-1 and PO-4

`Query.bump_prefix()` now computes a candidate `change_map` for each candidate
fresh prefix:

```python
change_map = {
    alias: '%s%d' % (prefix, pos)
    for pos, alias in enumerate(self.alias_map)
    if alias not in exclude
}
```

It accepts the candidate only if:

```python
set(change_map).isdisjoint(change_map.values())
set(change_map.values()).isdisjoint(set(self.alias_map).difference(change_map))
```

The first predicate is exactly the `Query.change_aliases()` safety condition.
The second predicate protects aliases left unchanged by `exclude`, including
the preserved initial alias. Therefore, once a prefix is accepted,
`self.change_aliases(change_map)` cannot see the reported overlapping map shape
inside `bump_prefix()`.

### PO-2

`combine()` computes:

```python
initial_alias = next(iter(rhs.alias_map), None)
rhs.bump_prefix(self, exclude={initial_alias})
```

Since `bump_prefix()` omits excluded aliases from `change_map`, the first RHS
alias remains unchanged. This preserves the combine invariant that both sides
share the same base alias while allowing every later RHS alias to move to the
fresh prefix namespace.

### PO-3

The V1 combine path runs the prefix bump before `change_map = {}` and before
the `for alias in rhs_tables` join loop. Thus the aliases that later become
combine-map keys are already normalized. In the reported pattern, RHS aliases
`T4` and `T5` become fresh-prefix aliases such as `U3` and `U4` before LHS
allocates replacements such as `T5` and `T6`; the merge map shape becomes
`U3 -> T5`, `U4 -> T6`, whose keys and values are disjoint under the alias
namespace assumptions in `SPEC.md`.

### PO-5

`combine()` clones RHS before relabeling:

```python
rhs = rhs.clone()
rhs.table_map = {
    table_name: aliases[:]
    for table_name, aliases in rhs.table_map.items()
}
```

`change_aliases()` mutates `table_map` alias lists when replacing old aliases
with new aliases. Copying those lists on the clone prevents this mutation from
leaking back into the original RHS query, discharging the docstring frame
condition.

### PO-6 and PO-7

The fix reuses `bump_prefix()` and its deterministic `prefix_gen()` sequence.
Existing `bump_prefix(outer_query)` calls pass `exclude=None`, which becomes
`set()`, so all aliases are relabeled as before. Only the combine path opts into
excluding the initial alias.

## Expected Machine Check Commands

These commands are recorded for a future environment with K installed. They
were not executed here.

```sh
cd fvk
kompile mini-query-alias.k --backend haskell
kast --backend haskell query-alias-spec.k
kprove query-alias-spec.k
```

Expected result after any syntax adjustments required by a local K
installation: `#Top` for the two claims in `query-alias-spec.k`.

## Test Recommendation

Do not remove any tests. Add or keep a regression test equivalent to the public
`qs1 | qs2` reproduction, plus a frame check that combining with RHS does not
mutate the RHS query's alias structures. Any test-redundancy decision is
conditioned on future machine checking and is outside this benchmark's allowed
actions.
