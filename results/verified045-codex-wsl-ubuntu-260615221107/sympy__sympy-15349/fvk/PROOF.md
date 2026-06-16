# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Summary

V1 proves the intended contract for `Quaternion.to_rotation_matrix()` on
nonzero quaternions: the returned matrix applies the same active rotation to a
point as `q * point * conjugate(q)`. The proof localizes the reported failure
to the `(1, 2)` entry, `M12`, and confirms the V1 edit from `+ q.b*q.a` to
`- q.b*q.a`.

## Algebraic Derivation

Let `q = a + b*i + c*j + d*k`, `p = 0 + x*i + y*j + z*k`, and
`qbar = a - b*i - c*j - d*k`. SymPy's Hamilton product in
`Quaternion._generic_mul()` is:

```
(a1, b1, c1, d1) * (a2, b2, c2, d2)
= (a1*a2 - b1*b2 - c1*c2 - d1*d2,
   b1*a2 + c1*d2 - d1*c2 + a1*b2,
  -b1*d2 + c1*a2 + d1*b2 + a1*c2,
   b1*c2 - c1*b2 + d1*a2 + a1*d2)
```

First multiply `q*p`:

```
r0 = -b*x - c*y - d*z
r1 =  a*x + c*z - d*y
r2 =  a*y + d*x - b*z
r3 =  a*z + b*y - c*x
```

Then multiply `r*qbar`. The vector part is:

```
x' = (a**2 + b**2 - c**2 - d**2)*x
     + 2*(b*c - a*d)*y
     + 2*(b*d + a*c)*z

y' = 2*(b*c + a*d)*x
     + (a**2 - b**2 + c**2 - d**2)*y
     + 2*(c*d - a*b)*z

z' = 2*(b*d - a*c)*x
     + 2*(c*d + a*b)*y
     + (a**2 - b**2 - c**2 + d**2)*z
```

Dividing by `N = a**2 + b**2 + c**2 + d**2` gives the matrix in `fvk/SPEC.md`.
The coefficient of `z` in `y'` is `2*(c*d - a*b)/N`, so `M12` must carry the
negative `a*b` term. This discharges PO2.

## Reported Case

For the issue input
`q = Quaternion(cos(t/2), sin(t/2), 0, 0)`, `N = 1`, so:

```
M11 = cos(t/2)**2 - sin(t/2)**2 = cos(t)
M12 = -2*sin(t/2)*cos(t/2) = -sin(t)
M21 =  2*sin(t/2)*cos(t/2) =  sin(t)
M22 = cos(t/2)**2 - sin(t/2)**2 = cos(t)
```

Therefore the expected matrix is:

```
[[1, 0, 0],
 [0, cos(t), -sin(t)],
 [0, sin(t),  cos(t)]]
```

This discharges PO3 and resolves F1.

## Convention Preservation

For the documented z-axis case
`q = Quaternion(cos(t/2), 0, 0, sin(t/2))`, the repaired `M12` term is still
zero and the matrix remains:

```
[[cos(t), -sin(t), 0],
 [sin(t),  cos(t), 0],
 [0,       0,      1]]
```

This matches the existing `to_rotation_matrix` docstring and the active
`rotate_point` convention, discharging PO4.

The sign differences used by `from_rotation_matrix()` also line up:

```
M21 - M12 = 4*a*b/N
M02 - M20 = 4*a*c/N
M10 - M01 = 4*a*d/N
```

The pre-fix formula made `M21 - M12 = 0`, which cannot support the sign
recovery for `b`. This discharges PO5.

## Homogeneous Matrix

The 4x4 branch computes `m03`, `m13`, and `m23` as `v - M*v`. Since the 3x3
block is now corrected, the rotation-about-point transform inherits the same
fix. For the visible legacy example `Quaternion(1, 2, 3, 4)` and
`v = (1, 1, 1)`, the corrected `M12 = 2/3` makes `m13 = 0`, not the legacy
`-4/15`. This discharges PO6 and explains F2.

## Machine-Check Commands

These commands are emitted for later machine checking. They were not run.

```sh
kompile fvk/mini-quaternion.k --backend haskell
kast --backend haskell fvk/quaternion-rotation-spec.k
kprove fvk/quaternion-rotation-spec.k
```

Expected successful machine-check result after installing/running K:
`#Top` for all claims.

## Test Redundancy Recommendation

No tests were modified. If the K claims are later machine-checked, in-domain
unit tests that assert individual `to_rotation_matrix()` entries covered by
the formal contract become candidates for removal or narrowing. Tests covering
API wiring, SymPy simplification behavior, zero-quaternion policy, and
integration with other modules should be kept. Visible tests that expect the
legacy `M12 = 14/15` for `Quaternion(1, 2, 3, 4)` should be updated in a normal
project workflow, but this task forbids test edits.

## Residual Risk

The proof is partial correctness over the algebraic core of the method. It
does not machine-check SymPy's full expression semantics, `trigsimp`, matrix
storage, or termination/performance. The trusted base is the mini-K fragment,
the Hamilton product formula read from source, standard ring/trigonometric
identities, and a future K/Z3 check of the emitted claims.
