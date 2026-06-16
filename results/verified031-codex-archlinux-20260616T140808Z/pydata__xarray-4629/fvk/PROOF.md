# Proof

Status: constructed, not machine-checked. No commands were executed.

## What Is Proved

For any non-empty attrs sequence whose first attrs mapping has contents `M0`, `merge_attrs(variable_attrs, "override")` returns a fresh attrs mapping with contents `M0`. Consequently, along the `xr.merge(..., combine_attrs="override")` path, mutating the result attrs dictionary does not mutate the first source dataset's attrs dictionary.

This is partial correctness of the attrs-combination helper and its merge propagation. There are no loops in the audited helper, so no loop circularity is required.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/merge-attrs-spec.k
kprove fvk/merge-attrs-spec.k
```

Expected machine-check result after a real K run: `#Top` for all claims. This expectation is constructed from the rules and claims here; it has not been confirmed by executing K.

## Constructed Proof Sketch

### Helper-Level Override Claim

Initial symbolic state:

- `<k>` contains `mergeAttrs(consAttr(attr(ID0, M0), REST), override)`.
- `<nextId>` contains `N`.
- Side condition: `N != ID0`.

The mini semantics has the override rule:

```k
rule <k> mergeAttrs(consAttr(attr(ID0, M0), _REST), override) => attr(N, M0) ... </k>
     <nextId> N => N +Int 1 </nextId>
  requires N =/=Int ID0
```

By Axiom, the rule rewrites the initial state to a final state whose result is `attr(N, M0)`. By Consequence and the side condition `N != ID0`, the result object identity is distinct from the first source attrs identity. Because the contents component is exactly `M0`, PO1 is satisfied. Because the identity component is `N` rather than `ID0`, PO2 is satisfied.

### Merge Propagation

Source path:

1. `merge` normalizes inputs and calls `merge_core(..., combine_attrs=combine_attrs)`.
2. `merge_core` computes `attrs = merge_attrs([...], combine_attrs)`.
3. `merge` constructs the result with `Dataset._construct_direct(**merge_result._asdict())`.
4. `_construct_direct` assigns `obj._attrs = attrs` directly.

The old helper returned the first source attrs object, so step 4 installed the source object as the result attrs. V1 returns a fresh dict, so step 4 installs a result-owned attrs mapping. No later source path replaces it with a source attrs object. PO3 follows from PO2 plus this propagation path.

### Other Branches

`drop`, empty attrs, `no_conflicts`, `identical`, and invalid mode are represented as separate claims in `merge-attrs-spec.k`. They are unchanged by V1 and either already allocate fresh mappings (`drop`, `no_conflicts`, `identical`) or return non-mapping/error results (`empty`, invalid). They do not reintroduce the reported override alias.

## Adequacy Check

The English intent in `fvk/INTENT_SPEC.md` requires shallow-copy/non-alias behavior for override. `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K override claim as exactly that behavior. `fvk/SPEC_AUDIT.md` marks the correspondence as pass.

## Test Guidance

No test files were read, modified, or run. A suitable regression test, if added outside this task's constraints, would construct the public issue's two datasets, merge with `combine_attrs="override"`, mutate the result attrs, and assert the first source attrs remains unchanged. Any future test-removal recommendation is conditioned on actually running the K commands above and receiving `#Top`.

## Residual Risk

- Constructed, not machine-checked.
- The mini semantics models only attrs identity and contents, not full Python or full xarray.
- The proof is partial correctness; termination is not a concern for this branch because the helper path has no loop.
- The proof establishes shallow mapping-copy behavior, not deep-copy behavior for attr values.
