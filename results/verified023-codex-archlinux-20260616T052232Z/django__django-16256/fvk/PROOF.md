# Constructed Proof

Status: constructed, not machine-checked.

## What is proved

Under the abstract dispatch semantics in `mini-related-manager.k`, V1 satisfies
the intended related-manager async dispatch contract:

- reverse many-to-one async create/get-or-create/update-or-create calls reach
  the reverse related manager sync effect;
- many-to-many async calls reach the many-to-many sync effect and preserve
  `through_defaults`;
- generic related-manager async calls reach the generic related manager sync
  effect;
- plain manager async calls remain on the queryset proxy effect;
- related-manager async wrappers are marked as data-mutating.

## Proof sketch

The key implementation fact is Python method lookup on the generated manager
classes. Before V1, `RelatedManager`, `ManyRelatedManager`, and
`GenericRelatedObjectManager` had sync relation-specific methods but no local
async variants, so lookup found copied manager proxy methods from
`BaseManager._get_queryset_methods()`. Those copied methods call
`getattr(self.get_queryset(), name)(*args, **kwargs)`, which is the queryset
proxy path.

V1 adds local async methods directly to each generated related manager class.
Therefore method lookup selects the local wrapper first. Each wrapper calls
`sync_to_async(self.<sync method>)`, so the next semantic step is the existing
relation-specific sync method. The sync method then produces the same
relation-specific effect already specified and publicly tested for the
synchronous API.

## K proof outline

For PO1, the claim starts at:

```k
<k> invokeAsync(reverseFK, O, T) </k>
```

Rule `invokeAsync(M, O, T) => localAsync(M, O, T)` applies because
`isRelated(reverseFK) => true`. Rule
`localAsync(M, O, T) => syncRelated(M, O, T)` applies. Rule
`syncRelated(reverseFK, O, _) => reverseFkEffect(O)` applies. By transitivity,
the original state reaches `reverseFkEffect(O)`.

For PO2, the same first two steps apply for `manyToMany`. The final sync rule
is:

```k
syncRelated(manyToMany, O, T) => manyToManyEffect(O, T)
```

The same symbolic `T` appears in the post-state, proving preservation of
`through_defaults` in the model.

For PO3, the same first two steps apply for `genericRel`, followed by:

```k
syncRelated(genericRel, O, _) => genericEffect(O)
```

For PO4, `invokeAsync(plain, O, T)` does not satisfy `isRelated(M)`, and the
plain-manager frame rule applies:

```k
invokeAsync(plain, O, T) => querysetProxy(O, T)
querysetProxy(O, _) => querysetProxyEffect(O)
```

For PO6, `checkAltersData(M, O) => true` applies under the side condition
`isRelated(M)`.

No loop or recursion circularity is needed; all claims are finite symbolic
dispatch rewrites.

## Machine-check commands

These commands are recorded for later use and were not executed:

```sh
kompile fvk/mini-related-manager.k --backend haskell
kast --backend haskell fvk/related-manager-async-spec.k
kprove fvk/related-manager-async-spec.k
```

Expected machine-check outcome if the fragment parses and the constructed proof
is accepted: `#Top`.

## Residual risk

The proof is partial and abstract. It proves that the async wrappers dispatch to
the sync related-manager methods under the modeled semantics. It does not prove
database behavior, router behavior, transaction behavior, or full Python method
resolution in a production Python-in-K semantics. Those are residual trusted
base assumptions, mitigated by the smallness of the wrappers and by the fact
that V1 delegates to existing synchronous methods.

Test removal is not recommended. The proof is not machine-checked, and no async
related-manager tests exist in this task to classify as redundant.

