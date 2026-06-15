# Formal Spec English

Status: paraphrase of `fvk/fitsdiff-vla-spec.k`.

1. `isVLA(P)` is true.
2. `isVLA(Q)` is true.
3. `isVLA(OTHER)` is false.
4. A VLA row pair with different shapes differs.
5. A same-shape floating VLA row pair differs exactly when the floating helper
   says it is not close.
6. A same-shape non-floating numeric VLA row pair differs exactly when numeric
   closeness fails.
7. A same-shape non-numeric VLA row pair differs exactly when exact element
   equality fails.
8. A `Q` VLA column with no differing rows contributes zero row differences.
9. A `P` or `Q` VLA column with a differing row contributes that row as a
   difference.
10. Non-VLA formats do not use the VLA row-difference contribution in the
    formal branch model.
