# PROOF

Status: constructed, not machine-checked.

## Claims proved by construction

The K claims in `fvk/patch-dash-spec.k` prove the following partial-correctness
properties over the reduced patch dash semantics:

1. Constructor-order tuple setup followed by `draw` forwards
   `scaleOffset(SCALE, O mod C, LW)` to the renderer.
2. Post-init tuple linestyle setup followed by `draw` forwards
   `scaleOffset(SCALE, O mod C, LW)` to the renderer.
3. Under the visible positive-linewidth preconditions, a non-zero normalized
   offset is not zeroed before reaching the renderer.
4. Invisible patches still return without a `set_dashes` call.

There are no loops or recursion in this reduced fragment, so no circularity
claim is needed.

## Constructed proof sketch

For Claim 1:

1. `setLinestyleTuple(O, C, SCALE)` fires with `C > 0` and the initial linewidth
   `0`. It stores `unscaledOffset = O mod C`, `dashCycle = C`, and an initial
   scaled dash pattern for linewidth `0`.
2. `setLinewidth(LW, SCALE)` fires with `LW >= 0`. It writes
   `linewidth = LW` and rescales the already-stored unscaled dash tuple so
   `dashPatternOffset = scaleOffset(SCALE, O mod C, LW)`.
3. `draw` sees `visible = true` and rewrites to `bindDrawPath`.
4. `bindDrawPath` reads the stored `dashPatternOffset` and rewrites to
   `setDashes(DO, DC)` with `DO = scaleOffset(SCALE, O mod C, LW)`.
5. `setDashes` records `rendererDashOffset = DO` and increments
   `dashSetCount`.
6. By transitivity, the final renderer dash offset is
   `scaleOffset(SCALE, O mod C, LW)`.

Claim 2 is the same proof without the intermediate linewidth rescale: the
linewidth is already present when `setLinestyleTuple` stores the scaled dash
pattern.

Claim 3 follows from Claim 1 plus the arithmetic side conditions. If
`SCALE=false`, `scaleOffset` returns `O mod C`, which is non-zero by
precondition. If `SCALE=true`, `scaleOffset` returns `(O mod C) * LW`; with
`LW > 0` and `O mod C != 0`, that product is non-zero over integers.

Claim 4 follows directly from the `visible=false` draw rule, which rewrites
`draw` to `.K` and leaves the renderer dash cells and `dashSetCount` unchanged.

## Adequacy gate

`FORMAL_SPEC_ENGLISH.md` paraphrases every claim. `SPEC_AUDIT.md` compares those
paraphrases against `INTENT_SPEC.md` and the public evidence ledger. No required
behavior is failed or ambiguous. The model boundary is explicit: it proves
offset forwarding to `gc.set_dashes`, not backend pixel rasterization.

## Findings from proof construction

The proof construction re-identifies the pre-fix bug as a single violated
obligation: `Patch.draw()` must not overwrite `_dash_pattern[0]` with `0`.
V1 discharges that obligation. No additional source change is justified by the
FVK artifacts.

## Test-redundancy recommendation

No tests are recommended for removal. The proof is constructed but not
machine-checked, and this benchmark task fixes hidden tests without editing test
files. Future public tests that mock or inspect `gc.set_dashes` for in-domain
rectangle or ellipse dash tuple offsets would be subsumed by these claims only
after `kprove` returns `#Top`; image/backend integration tests should be kept.

## Commands to machine-check later

Do not run these in this benchmark session. They are the emitted commands for a
future environment with K installed:

```sh
cd fvk
kompile mini-patch-dash.k --backend haskell
kast --backend haskell patch-dash-spec.k
kprove patch-dash-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.
