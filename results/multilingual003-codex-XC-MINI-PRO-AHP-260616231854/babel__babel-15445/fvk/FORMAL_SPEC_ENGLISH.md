# Formal Spec English

Status: constructed, not machine-checked.

## Claim COPY-NO-CONTENT

For every finite list of resolved sources and every existing generated-map content state, running the input-map content copy step with no source-content array terminates immediately and leaves the generated-map content state unchanged.

This models the JavaScript branch where `const sourcesContent = this._inputMap.sourcesContent; if (sourcesContent) { ... }` is false.

## Claim COPY-SOME-CONTENT

For every finite list of resolved sources, every finite list of provided source contents, and every existing generated-map content state, running the input-map content copy step copies contents pairwise by index. It writes `sourcesContent[i]` to `resolvedSources[i]` for indices that exist in both lists and performs no read or write for source indices beyond the content list length.

This models the JavaScript loop:

```ts
for (let i = 0; i < resolvedSources.length; i++) {
  if (i < sourcesContent.length) {
    setSourceContent(map, resolvedSources[i], sourcesContent[i]);
  }
}
```

## Frame Conditions

The formal slice does not change `_inputMap` creation, `mark()` lookup behavior, direct source-content insertion from `code`, public method signatures, or exported result shapes.

## Machine Commands

The proof is constructed only. The commands that would machine-check it are:

```sh
kompile fvk/mini-ts-sourcemap.k --backend haskell
kast --backend haskell fvk/source-map-spec.k
kprove fvk/source-map-spec.k
```
