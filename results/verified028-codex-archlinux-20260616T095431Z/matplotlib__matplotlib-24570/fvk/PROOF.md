# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims Proved in the Model

The formal claims are in `fvk/offsetbox-align-spec.k`:

- CLAIM-bottom-edge: `lowerEdge(offset(H, D, T, bottomA), D) => 0`
- CLAIM-top-edge: `upperEdge(offset(H, D, T, topA), D, H) => T`
- CLAIM-left-edge: `lowerEdge(offset(W, D, T, leftA), D) => 0`
- CLAIM-right-edge: `upperEdge(offset(W, D, T, rightA), D, W) => T`
- CLAIM-baseline-frame: `offset(H, D, T, baselineA) => 0`

All directional claims require `0 <= D <= size <= T`.

## Human Proof

For bottom alignment, V1 uses the lower-edge branch:

```text
o = d
child_bottom = o - d = d - d = 0
```

Thus every child bottom edge is on the parent bottom edge.

For top alignment, V1 uses the upper-edge branch:

```text
o = H - h + d
child_top = o - d + h
          = (H - h + d) - d + h
          = H
```

Thus every child top edge is on the parent top edge.

For `VPacker` left/right, the same helper is used with width/xdescent in place
of height/descent. `left` remains `o = d`, so the near edge is `0`; `right`
remains `o = W - w + d`, so the far edge is `W`.

The pre-V1 table failed the two `HPacker` claims:

- pre-V1 `bottom`: `o = H - h + d`, so `child_bottom = H - h`, not `0` unless
  `h == H`.
- pre-V1 `top`: `o = d`, so `child_top = h`, not `H` unless `h == H`.

V1 swaps exactly those branch memberships and discharges the intended
obligations.

## Symbolic Execution Sketch

For CLAIM-bottom-edge:

1. Evaluate `offset(H, D, T, bottomA)` using the mini semantics:
   `offset(...) => D`.
2. Evaluate `lowerEdge(D, D)`:
   `D -Int D => 0`.
3. The result matches the post-state `<k> 0 </k>`.

For CLAIM-top-edge:

1. Evaluate `offset(H, D, T, topA)`:
   `offset(...) => T -Int H +Int D`.
2. Evaluate `upperEdge(T -Int H +Int D, D, H)`:
   `(T - H + D) - D + H => T`.
3. The result matches the post-state `<k> T </k>`.

The left/right claims are the same derivations with width substituted for
height. No loop circularity is needed.

## Exact Commands Not Run

The commands that would machine-check these artifacts later are:

```sh
cd fvk
kompile mini-python-offsetbox.k --backend haskell
kast --backend haskell offsetbox-align-spec.k
kprove offsetbox-align-spec.k
```

Expected machine-check result after successful tooling setup: `#Top` for all
claims. This expectation is not asserted as observed, because this session must
not run K tooling.

## Residual Risk

This is a property-complete mini semantics for the branch table and edge
geometry, not full Python or full Matplotlib rendering semantics. It proves the
axis manipulated by the fix. It does not prove renderer integration,
termination, performance, or visual raster output.

Test removal is not recommended here. Existing and hidden tests should remain
the external integration check unless and until the K commands are actually run
and the project owners decide to rely on them.
