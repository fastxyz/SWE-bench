# PROOF.md

Status: constructed, not machine-checked. No tests, Python code, `kompile`,
`kast`, or `kprove` were executed.

## Claims

The formal core is in `fvk/mini-capture.k` and `fvk/encodedfile-spec.k`.

- `MODE-GETTER`: reading `EncodedFile.mode` rewrites to `stripB(M)`.
- `MODE-NO-B`: `stripB(M)` contains no binary flag.
- `BUFFER-MODE-PRESERVED`: reading `EncodedFile.buffer.mode` rewrites to `M`.
- `STRIPB-PRESERVES-NON-B`: `stripB` preserves every non-binary mode flag.

These claims correspond to PO-1, PO-2, PO-3, and PO-5 in
`fvk/PROOF_OBLIGATIONS.md`.

## Constructed Proof

1. The mini semantics represents a buffer mode as a finite list of mode
   characters. `mcB` is the binary flag; all other mode flags are represented by
   non-`mcB` constructors.
2. The rule for `encodedFileMode(M)` rewrites directly to `stripB(M)`. This
   models V1's `self.buffer.mode.replace("b", "")` and discharges PO-2.
3. `stripB` is defined structurally:
   - on the empty mode it returns the empty mode;
   - on `mcB M` it drops `mcB` and recurses on `M`;
   - on any non-`mcB` head it preserves the head and recurses on `M`.
4. Structural induction on `M` proves `hasB(stripB(M)) == false`.
   - Base case: `M = .Mode`; `stripB(.Mode) = .Mode`; `hasB(.Mode) = false`.
   - Binary-head case: `M = mcB T`; `stripB(mcB T) = stripB(T)`, and the
     induction hypothesis gives `hasB(stripB(T)) = false`.
   - Non-binary-head cases: `M = C T` where `C` is not `mcB`; `stripB(C T) =
     C stripB(T)`, and `hasB(C stripB(T)) = hasB(stripB(T)) = false` by the
     induction hypothesis.
   This discharges PO-1.
5. The same structural definition proves non-binary flag preservation: the
   binary-head case drops only `mcB`; every non-binary-head case preserves the
   head and recurses. This discharges PO-3.
6. The rule for `encodedFileBufferMode(M)` rewrites to `M`; V1 does not assign
   to `self.buffer` or `self.buffer.mode`, so reading `.mode` has no mutation
   path that could change the underlying mode. This discharges PO-5.
7. `write()` and `__getattr__` are unchanged by V1. Therefore PO-4 and PO-6 are
   source-level frame obligations discharged by comparing the V1 diff to the
   audited source.

There are no loop circularities, no recursive calls, and no arithmetic VCs.

## Adequacy Result

The formal English paraphrase in `fvk/SPEC.md` matches the intent-only
obligations derived from `benchmark/PROBLEM.md`: the wrapper mode no longer
contains `b`, while the underlying buffer mode remains available through
`.buffer.mode`. No claim preserves the buggy legacy equality between
`EncodedFile.mode` and `EncodedFile.buffer.mode`.

## Test Guidance

No tests were added or modified, per task constraints.

Recommended public tests for a maintainer to add later:

- Under fd capture, `sys.stdout.mode` does not contain `b`.
- Under fd capture, `sys.stdout.buffer.mode` still contains `b`.
- Directly wrapping a fake buffer whose mode is `rb+` gives wrapper mode `r+`.
- A buffer with no `mode` attribute still raises `AttributeError` on
  `EncodedFile.mode`.

No test should be removed on the basis of this constructed proof alone. Test
removal would require machine-checking the K claims first.

## Reproduce The Machine Check Later

These commands are recorded for a future environment. They were not run here.

```sh
kompile fvk/mini-capture.k --backend haskell
kast --backend haskell fvk/encodedfile-spec.k
kprove fvk/encodedfile-spec.k
```

Expected result after a successful future machine check: `#Top`.
