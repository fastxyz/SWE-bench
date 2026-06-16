# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in the Constructed Model

`CLAIM-WRAP-IN-TEX`: for any in-domain date label string `T`,
`wrapInTex(T)` rewrites to:

`pruneEmptyMathdefault(mathWrap(replaceSpace(replaceColon(replaceDash(alphaTextSplit(T))))))`

`CLAIM-PROTECT-SEPARATORS`: for any in-domain `T`, the output of
`wrapInTex(T)` satisfies `protectsDateSeparators(T, OUT)`.

`CLAIM-DATEFORMATTER-USETEX`: built-in formatter output is `expectedWrap(T)`
when `usetex=True`.

`CLAIM-DATEFORMATTER-NON-TEX`: formatter output is `T` when `usetex=False`.

There are no loop circularities because `_wrap_in_tex` is modeled as a finite
deterministic string pipeline.

## Symbolic Proof Sketch

1. Start with `<k> wrapInTex(T) </k>`.
2. Apply the `wrapInTex` semantic rule from `mini-python-datewrap.k`.
3. The result is exactly `expectedWrap(T)`, discharging
   `CLAIM-WRAP-IN-TEX` by one rewrite plus reflexivity.
4. For `CLAIM-PROTECT-SEPARATORS`, rewrite `wrapInTex(T)` to
   `expectedWrap(T)`, then apply the simplification lemma
   `protectsDateSeparators(T, expectedWrap(T)) => true`.
5. For `CLAIM-DATEFORMATTER-USETEX`, rewrite
   `dateFormatterResult(true, T)` to `expectedWrap(T)`.
6. For `CLAIM-DATEFORMATTER-NON-TEX`, rewrite
   `dateFormatterResult(false, T)` to `T`.

The proof uses transitivity for the `wrapInTex` to `expectedWrap` to predicate
chain, and consequence for the boolean `ensures` predicate.

## Adequacy Check

The English claims above match `fvk/INTENT_SPEC.md`:

- They protect spaces, colons, and dashes as required by the issue workaround.
- They preserve non-TeX formatter behavior.
- They preserve the existing alphabetic split, which is compatible with the
  issue and supported by public tests that do not conflict on that point.

The proof does not claim full TeX rendering equivalence or pixel-level layout
metrics. Those are integration properties outside the mini string semantics.

## Machine-Check Commands Not Run

From the workspace root, a later machine-checking pass would run:

```sh
kompile fvk/mini-python-datewrap.k --backend haskell
kast --backend haskell fvk/datewrap-spec.k
kprove fvk/datewrap-spec.k
```

Expected result after a real toolchain run: `#Top` for all claims. This
expectation is constructed from the proof above, not observed.

## Test Recommendation

No test files were modified. Do not remove tests based on this constructed proof
alone. Existing public tests that assert raw spaces/colons in TeX math chunks
should be treated as stale for this issue, but any test updates or removals must
occur outside this task and after normal project review.
