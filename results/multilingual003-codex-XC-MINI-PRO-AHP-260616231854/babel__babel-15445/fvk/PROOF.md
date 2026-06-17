# Constructed Proof

Status: constructed, not machine-checked. No tests, project code, Python, `kompile`, or `kprove` were run.

## Artifacts

- Semantics: `fvk/mini-ts-sourcemap.k`
- Claims: `fvk/source-map-spec.k`
- Human spec: `fvk/SPEC.md`
- Obligations: `fvk/PROOF_OBLIGATIONS.md`
- Findings: `fvk/FINDINGS.md`

## Claim COPY-NO-CONTENT

Initial pattern:

```k
<k> copyInput(SOURCES, noContent) </k>
<contents> M </contents>
```

The semantics has a direct rule:

```k
rule <k> copyInput(SOURCES:List, noContent) => .K ... </k>
```

By one axiom step plus framing of `<contents>`, the computation reaches:

```k
<k> .K </k>
<contents> M </contents>
```

This discharges PO-001: no indexed read exists on the no-content path, so the reported `sourcesContent[0]` crash is unreachable in this model. It also discharges PO-004 for the absent-content case because no generated-map content update occurs.

## Claim COPY-SOME-CONTENT

Initial pattern:

```k
<k> copyInput(SOURCES, someContent(CONTENTS)) </k>
<contents> M </contents>
```

The proof is by structural circularity on the source/content lists.

Base cases:

1. `SOURCES = .List`: the rule `copyInput(.List, someContent(CONTENTS)) => .K` leaves `<contents>` unchanged. This equals `copyPairs(M, .List, CONTENTS) = M`.
2. `SOURCES = ListItem(S) SS` and `CONTENTS = .List`: the rule `copyInput(ListItem(S) SS, someContent(.List)) => .K` leaves `<contents>` unchanged. This equals `copyPairs(M, ListItem(S) SS, .List) = M`.

Step case:

For `SOURCES = ListItem(S) SS` and `CONTENTS = ListItem(C) CS`, the semantics applies:

```k
<k> copyInput(ListItem(S) SS, someContent(ListItem(C) CS))
  => copyInput(SS, someContent(CS)) ... </k>
<contents> M => M[S <- C] </contents>
```

After this genuine rewrite step, guarded circularity applies to the smaller lists `SS` and `CS`. The post-state contents are:

```k
copyPairs(M[S <- C], SS, CS)
```

By the definition of `copyPairs`, this equals:

```k
copyPairs(M, ListItem(S) SS, ListItem(C) CS)
```

This discharges PO-002: every paired source/content entry is copied, and recursion stops before reading beyond the content list.

## Frame Conditions

PO-003 is discharged by static source review rather than the mini-K slice:

- V1 still creates `this._inputMap = new TraceMap(opts.inputSourceMap)` before checking contents.
- `mark()` and original-position lookup are unchanged.
- The no-input-map string `code` branch is unchanged.
- The object `code` branch is unchanged.

PO-005 is discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: no public symbol or signature changed.

## Machine-check commands

These commands are the exact commands to run in a K-enabled environment. Expected result after successful machine checking: `#Top`.

```sh
kompile fvk/mini-ts-sourcemap.k --backend haskell
kast --backend haskell fvk/source-map-spec.k
kprove fvk/source-map-spec.k
```

## Test guidance

No test files were read as oracle requirements beyond public source inspection, and no tests were modified.

Tests that would be useful to add or keep:

- Input map with `sources` and no `sourcesContent` should not throw.
- Input map with `sourcesContent` should still include the provided contents in the output map.
- Direct string/object `code` source-content behavior should remain unchanged.

No test deletion is recommended until the K claims are actually machine-checked.
