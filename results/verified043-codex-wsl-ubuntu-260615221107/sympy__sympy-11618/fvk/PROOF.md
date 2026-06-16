# FVK PROOF - sympy__sympy-11618

Status: constructed, not machine-checked. No commands in this file were run.

## What Is Proved

For `Point.distance`, V1 satisfies the zero-fill Euclidean distance contract:

```text
distance(A, B) =
sqrt(sum((coord(A, i) - coord(B, i))**2 for i in range(max(len(A), len(B)))))
```

with `coord(L, i) = 0` for indexes outside `L`.

This proves the reported example:

```text
Point(2, 0).distance(Point(1, 0, 2)) == sqrt(5)
```

## Source-Level Proof Sketch

1. V1 selects the second coordinate sequence with:

   ```python
   p.args if isinstance(p, Point) else p
   ```

   This preserves the prior public behavior for `Point` and iterable arguments.

2. V1 pairs coordinates with:

   ```python
   zip_longest(self.args, other_args, fillvalue=S.Zero)
   ```

   For coordinate lists of lengths `m` and `n`, `zip_longest` emits
   `max(m, n)` pairs. Any missing coordinate is `S.Zero`.

3. V1 maps each pair `(a, b)` to `(a - b)**2`.

4. V1 sums all squared differences and applies `sqrt`.

5. Therefore the result is exactly PO-001.

6. In the reported example, the pairs are `(2, 1)`, `(0, 0)`, and `(0, 2)`.
   The sum of squared differences is `1 + 0 + 4 = 5`, so the result is
   `sqrt(5)`.

## K Claims

The supporting K files are:

- `fvk/mini-python.k`
- `fvk/point-distance-spec.k`

Constructed claims:

- `POINT-DISTANCE-GENERAL`: proves PO-001 over arbitrary finite coordinate
  lists in the mini distance fragment.
- `POINT-DISTANCE-REPORTED`: proves PO-002 for `(2, 0)` and `(1, 0, 2)`.
- `POINT-DISTANCE-SAME-DIM-FRAME`: proves PO-003 for representative equal
  length coordinate lists and records the general frame argument in comments.

## Verification Conditions

VC-001. Longest-coordinate coverage:

`zip_longest` emits all positions up to `max(len(A), len(B))`.

Discharge:

By the Python standard behavior represented in the mini-K recursive `sumsq`
definition: the recursion continues until both lists are empty, adding a
zero-filled term when exactly one list is empty.

VC-002. Missing-coordinate zero contribution:

When a coordinate is absent from one list, the term is `(a - 0)**2` or
`(0 - b)**2`.

Discharge:

By the `sumsq(A ; AS, .Ints)` and `sumsq(.Ints, B ; BS)` equations in
`fvk/mini-python.k`.

VC-003. Same-dimensional preservation:

When neither list ends early, every term is `(a - b)**2`; no zero-filled branch
is used.

Discharge:

By the `sumsq(A ; AS, B ; BS)` equation in `fvk/mini-python.k`.

## Residual Risk

This is a partial correctness proof over a mini expression semantics, not a full
Python-in-K semantics. There is no loop termination issue in `Point.distance`
beyond finite coordinate iteration. The trusted base is the adequacy of the
mini-K model for the coordinate-pair property, the K reachability framework, and
the eventual `kprove` run.

The proof has not been machine-checked in this session.

## Reproduce the Machine Check Later

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/point-distance-spec.k
kprove fvk/point-distance-spec.k
```

Expected result after a real machine check:

`#Top`.

## Test Guidance

Do not remove tests based on this constructed proof alone. After machine
checking, tests that assert in-domain instances of PO-001 can be considered
subsumed by the proof. Boundary, integration, and public API compatibility tests
should be kept.
