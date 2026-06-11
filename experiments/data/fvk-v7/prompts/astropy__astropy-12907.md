# Guidance for Repairing `separability_matrix` Bug (astropy#12907)

You are fixing an issue where `separability_matrix` produces incorrect results for nested `CompoundModel`s. Use the three solved examples below as precedents. Study each example’s root cause → fix mapping, then transfer the diagnostic approach and the *shape* of the fix, **not** the exact code. The examples are from a different codebase (sympy), but the patterns of matrix-composition bugs are directly relevant.

- **Pattern 1 (Example 1):** Edge‑case handling of dimensions when stacking matrices.  
  The bug arose because a zero‑row/zero‑col matrix was not correctly propagated, leading to a wrong final shape. Transfer: in `separability_matrix`, ensure that when assembling the boolean matrix from submodels (especially nested compounds), any subcomponent with a trivial (e.g., 0×0) or identity‑like separability contribution is correctly integrated without corrupting the overall structure. Look for branching that treats “empty” or “fully separable” cases incorrectly during composition.

- **Pattern 2 (Example 2):** Off‑by‑one error in an index computation during column insertion.  
  The fix was a single‑character change to an arithmetic expression that shifted columns incorrectly. Transfer: the separability matrix is built by placing sub‑matrices at certain row/column offsets. Check the indexing logic that combines the separability matrices of child models; a subtle miscalculation could place `True` values in the wrong blocks, making separable dimensions appear non‑separable, exactly as seen in the nested‑compound case.

- **Pattern 3 (Example 3):** Missing simplification step when composing hierarchical matrix structures.  
  The bug occurred because block‑matrix multiplication did not fully collapse intermediate results, causing a shape mismatch on repeated multiplication. Transfer: `separability_matrix` likely computes the separability of a compound model by recursively combining the matrices of its components. If a nested compound model is not recursively decomposed down to its leaf models, its internal separability structure may be taken as a monolithic block (all `True` or all `False`), leading to the reported bug. The fix pattern is to ensure that the composition logic explicitly decomposes nested compounds and applies the correct logical operation (AND/OR) to the leaf matrices, rather than using a pre‑composed matrix as a black box.

## Solved Examples

### Example 1: sympy#13031 – Stacking zero‑dimension matrices changed shape
**Issue:** `Matrix.hstack` and `vstack` gave wrong shape for null matrices after version 1.1. For an empty 0×0 matrix followed by non‑empty matrices, the output shape dropped columns.

**Fix:** Added explicit checks for zero rows/cols and created a correctly sized empty intermediate matrix before stacking.

```diff
diff --git a/sympy/matrices/sparse.py b/sympy/matrices/sparse.py
--- a/sympy/matrices/sparse.py
+++ b/sympy/matrices/sparse.py
@@ -985,8 +985,10 @@ def col_join(self, other):
         >>> C == A.row_insert(A.rows, Matrix(B))
         True
         """
-        if not self:
-            return type(self)(other)
+        # A null matrix can always be stacked (see  #10770)
+        if self.rows == 0 and self.cols != other.cols:
+            return self._new(0, other.cols, []).col_join(other)
+
         A, B = self, other
         if not A.cols == B.cols:
             raise ShapeError()
@@ -1191,8 +1193,10 @@ def row_join(self, other):
         >>> C == A.col_insert(A.cols, B)
         True
         """
-        if not self:
-            return type(self)(other)
+        # A null matrix can always be stacked (see  #10770)
+        if self.cols == 0 and self.rows != other.rows:
+            return self._new(other.rows, 0, []).row_join(other)
+
         A, B = self, other
         if not A.rows == B.rows:
             raise ShapeError()
```

### Example 2: sympy#13647 – `col_insert` shifted identity block incorrectly
**Issue:** Inserting a two‑column matrix into an identity matrix placed the trailing identity block in the wrong rows due to an off‑by‑one error in the index expression.

**Fix:** Removed the erroneous extra `- pos` term from the fallback index.

```diff
diff --git a/sympy/matrices/common.py b/sympy/matrices/common.py
--- a/sympy/matrices/common.py
+++ b/sympy/matrices/common.py
@@ -86,7 +86,7 @@ def entry(i, j):
                 return self[i, j]
             elif pos <= j < pos + other.cols:
                 return other[i, j - pos]
-            return self[i, j - pos - other.cols]
+            return self[i, j - other.cols]
 
         return self._new(self.rows, self.cols + other.cols,
                          lambda i, j: entry(i, j))
```

### Example 3: sympy#17630 – `BlockMatrix` multiplication exception with zero blocks
**Issue:** Multiplying `BlockMatrix` containing `ZeroMatrix` blocks worked once but threw an exception on a second multiplication because intermediate `MatAdd` nodes were not fully simplified, leaving shape mismatches.

**Fix:** Added an explicit `doit` call for `MatAdd` inside the postprocessor so that additions are collapsed immediately during block multiplication.

```diff
diff --git a/sympy/matrices/expressions/matexpr.py b/sympy/matrices/expressions/matexpr.py
--- a/sympy/matrices/expressions/matexpr.py
+++ b/sympy/matrices/expressions/matexpr.py
@@ -627,6 +627,8 @@ def _postprocessor(expr):
                 # manipulate them like non-commutative scalars.
                 return cls._from_args(nonmatrices + [mat_class(*matrices).doit(deep=False)])
 
+        if mat_class == MatAdd:
+            return mat_class(*matrices).doit(deep=False)
         return mat_class(cls._from_args(nonmatrices), *matrices).doit(deep=False)
     return _postprocessor
```
