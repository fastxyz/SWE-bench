# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## K artifacts

* Semantics fragment: `fvk/mini-autodoc.k`
* Spec claims: `fvk/autodoc-filter-spec.k`

The fragment models the part of `Documenter.filter_members()` that decides whether a member is kept and whether it is treated as an attribute. Parser/analyzer behavior is represented by the `AttrPresent` and `AttrMeta` inputs, justified by PO-1.

## Claims and proof sketch

### `META-PUBLIC-VARIABLE`

Initial symbolic state:

* `NamePrivate = true`
* `DocMeta = noneMeta`
* `AttrPresent = true`
* `AttrMeta = publicMeta`
* `WantAll = true`
* all earlier skip inputs are false

Symbolic execution:

1. `choosePrivate(true, noneMeta, true, publicMeta)` rewrites to `metaPrivate(publicMeta)` because `hasVisibility(publicMeta)` is true.
2. `metaPrivate(publicMeta)` rewrites to `false`.
3. The attribute branch applies because `AttrPresent = true`.
4. `attrKeep(false, true, false)` rewrites to true.
5. The final state is `decision(true, true)`.

This proves the issue example's visibility decision, assuming the analyzer premise PO-1.

### `META-PRIVATE-VARIABLE`

Initial symbolic state has `NamePrivate = false`, `AttrPresent = true`, and `AttrMeta = privateMeta`. The same branch rewrites `choosePrivate(...)` to true, and `attrKeep(true, true, false)` rewrites to false. The final state is `decision(false, true)`, preserving the documented private metadata family.

### `ATTR-VISIBILITY-PRECEDENCE`

Initial symbolic state has conflicting metadata: `DocMeta = privateMeta` and `AttrMeta = publicMeta`. Because `AttrPresent = true` and `AttrMeta` has a visibility marker, `choosePrivate(...)` uses `AttrMeta`, not `DocMeta`. The result is `decision(true, true)`.

This is the proof step V1 failed conceptually: V1 unioned the two metadata dictionaries, so the later `private` check could still see the runtime-docstring marker. V2 changes the source to make the constructed proof match the intended attribute-documentation source.

### `DOCSTRING-PUBLIC-FRAME`

Initial symbolic state has `DocMeta = publicMeta`, `AttrPresent = true`, and `AttrMeta = noneMeta`. Since the attribute documentation has no visibility marker, `choosePrivate(...)` falls back to `DocMeta`. The member remains public and is kept as an attribute. This preserves existing docstring metadata behavior.

## Residual risk

This proof is partial correctness over the modeled decision. It does not prove Sphinx end-to-end rendering, event-handler behavior, import side effects, or termination. The trusted base is the adequacy of `mini-autodoc.k` for the visibility decision and the source-inspected parser/analyzer premises.

## Machine-check commands recorded but not run

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-filter-spec.k
kprove fvk/autodoc-filter-spec.k
```

Expected result after a future machine check: `#Top` for all four claims. Until then, the proof remains constructed, not machine-checked.

## Test-redundancy recommendation

No test deletion is recommended. Existing public tests exercise integration-style autodoc output and the constructed proof only covers the local keep/isattr decision. Future focused tests for variable `:meta public:` / `:meta private:` would be logically subsumed by the local proof only after the K claims are machine-checked, but they should still be kept as integration coverage unless maintainers choose otherwise.
