## Demonstration Guidance

Use the solved examples as **precedent, not templates**. Study each one’s mapping from symptom to root cause, the shape of its fix, and what the patch deliberately left unchanged. Then apply the same diagnostic mindset and fix‑shape conventions to the target issue.

The examples below share a core pattern with the target issue: **when a method cannot handle the given inputs, it should return `NotImplemented` (or a graceful fallback) instead of raising an exception or prematurely returning `False`**. They also show how to isolate the change to the exact comparison/dispatch method and to wrap fragile conversion logic in `try/except` to convert errors into the correct sentinel. Transfer these ideas, not line numbers.

---

### Example 1: sympy__sympy-13091

**Issue summary:** SymPy’s rich comparison methods (like `__eq__`) returned `False` when the other object could not be sympified, instead of returning `NotImplemented`. This broke symmetric comparison with external types, because `False` prevented delegation to the other object’s reflected method. The fix changes `return False` to `return NotImplemented` when sympification fails, and ensures `__ne__` calls `self == other` (which may return `NotImplemented`) rather than `self.__eq__(other)`.

**Relation to target issue:** Exactly the “return `NotImplemented` instead of a hard failure” pattern. The target issue asks whether `Quantity.__array_ufunc__` should return `NotImplemented` instead of raising `ValueError` when inputs are incompatible – the same delegation principle. The fix shape demonstrated here: catch the conversion error, return `NotImplemented`, and where applicable adjust neighbouring methods so the dispatch chain is preserved. This directly transfers: the agent should look for a place in `__array_ufunc__` where an incompatibility is currently signalled by `ValueError` and instead return `NotImplemented`.

**Gold patch:**

```diff
diff --git a/sympy/core/basic.py b/sympy/core/basic.py
--- a/sympy/core/basic.py
+++ b/sympy/core/basic.py
@@ -313,7 +313,7 @@ def __eq__(self, other):
             try:
                 other = _sympify(other)
             except SympifyError:
-                return False    # sympy != other
+                return NotImplemented
 
             if type(self) != type(other):
                 return False
@@ -329,7 +329,7 @@ def __ne__(self, other):
 
            but faster
         """
-        return not self.__eq__(other)
+        return not self == other
 
     def dummy_eq(self, other, symbol=None):
         """
@@ -1180,7 +1180,7 @@ def _has(self, pattern):
 
     def _has_matcher(self):
         """Helper for .has()"""
-        return self.__eq__
+        return lambda other: self == other
 
     def replace(self, query, value, map=False, simultaneous=True, exact=False):
         """
diff --git a/sympy/core/exprtools.py b/sympy/core/exprtools.py
--- a/sympy/core/exprtools.py
+++ b/sympy/core/exprtools.py
@@ -797,7 +797,7 @@ def __eq__(self, other):  # Factors
         return self.factors == other.factors
 
     def __ne__(self, other):  # Factors
-        return not self.__eq__(other)
+        return not self == other
 
 
 class Term(object):
@@ -909,7 +909,7 @@ def __eq__(self, other):  # Term
                 self.denom == other.denom)
 
     def __ne__(self, other):  # Term
-        return not self.__eq__(other)
+        return not self == other
 
 
 def _gcd_terms(terms, isprimitive=False, fraction=True):
diff --git a/sympy/core/numbers.py b/sympy/core/numbers.py
--- a/sympy/core/numbers.py
+++ b/sympy/core/numbers.py
@@ -1258,7 +1258,7 @@ def __eq__(self, other):
         try:
             other = _sympify(other)
         except SympifyError:
-            return False    # sympy != other  -->  not ==
+            return NotImplemented
         if isinstance(other, NumberSymbol):
             if other.is_irrational:
                 return False
@@ -1276,7 +1276,7 @@ def __eq__(self, other):
         return False    # Float != non-Number
 
     def __ne__(self, other):
-        return not self.__eq__(other)
+        return not self == other
 
     def __gt__(self, other):
         try:
@@ -1284,7 +1284,7 @@ def __gt__(self, other):
         except SympifyError:
             raise TypeError("Invalid comparison %s > %s" % (self, other))
         if isinstance(other, NumberSymbol):
-            return other.__le__(self)
+            return other.__lt__(self)
         if other.is_comparable:
             other = other.evalf()
…(truncated)
```

---

### Example 2: sympy__sympy-18211

**Issue summary:** `solveset` was raising `NotImplementedError` for an equation that it could not solve analytically, instead of returning a `ConditionSet`. The fix catches the `NotImplementedError` raised by `solve_univariate_inequality` and falls back to constructing a `ConditionSet` over the reals.

**Relation to target issue:** Although the target is about `__array_ufunc__` returning `NotImplemented`, this example shows the sibling pattern: when a method encounters an unsolvable case, it should not propagate an exception but instead return an appropriate sentinel (`ConditionSet`) that the caller can handle. In the ufunc context, the sentinel is `NotImplemented` itself. The fix shape is: scope the failing operation with `try/except`, catch the specific exception that currently signals inability, and return the correct sentinel. This teaches that the agent can wrap the problematic part of `__array_ufunc__` in a `try/except` to convert `ValueError` (or similar) into a `NotImplemented` return.

**Gold patch:**

```diff
diff --git a/sympy/core/relational.py b/sympy/core/relational.py
--- a/sympy/core/relational.py
+++ b/sympy/core/relational.py
@@ -389,10 +389,17 @@ def __nonzero__(self):
     def _eval_as_set(self):
         # self is univariate and periodicity(self, x) in (0, None)
         from sympy.solvers.inequalities import solve_univariate_inequality
+        from sympy.sets.conditionset import ConditionSet
         syms = self.free_symbols
         assert len(syms) == 1
         x = syms.pop()
-        return solve_univariate_inequality(self, x, relational=False)
+        try:
+            xset = solve_univariate_inequality(self, x, relational=False)
+        except NotImplementedError:
+            # solve_univariate_inequality raises NotImplementedError for
+            # unsolvable equations/inequalities.
+            xset = ConditionSet(x, self, S.Reals)
+        return xset
 
     @property
     def binary_symbols(self):
```

---

### Example 3: astropy__astropy-7606

**Issue summary:** Comparing an `UnrecognizedUnit` instance to `None` raised `TypeError` because the constructor `Unit(None, ...)` threw `TypeError` before `__eq__` could return `False`. The fix wraps the unit conversion in `try/except` and returns `NotImplemented` on failure, allowing Python’s normal comparison delegation to work.

**Relation to target issue:** This is practically the same pattern in the same project (astropy) and the same module (units). It demonstrates that in astropy’s unit code, methods that cannot convert an input should return `NotImplemented` rather than raising an error. The fix shape is a minimal change to a specific comparison method: surround the conversion with `try/except`, catch the relevant errors, and `return NotImplemented`. This transfers directly to `Quantity.__array_ufunc__`: find where incompatible inputs currently cause an exception, wrap that in a `try/except`, and return `NotImplemented` instead. The agent should follow the same conservative style, altering only the necessary method.

**Gold patch:**

```diff
diff --git a/astropy/units/core.py b/astropy/units/core.py
--- a/astropy/units/core.py
+++ b/astropy/units/core.py
@@ -728,7 +728,7 @@ def __eq__(self, other):
         try:
             other = Unit(other, parse_strict='silent')
         except (ValueError, UnitsError, TypeError):
-            return False
+            return NotImplemented
 
         # Other is Unit-like, but the test below requires it is a UnitBase
         # instance; if it is not, give up (so that other can try).
@@ -1710,8 +1710,12 @@ def _unrecognized_operator(self, *args, **kwargs):
         _unrecognized_operator
 
     def __eq__(self, other):
-        other = Unit(other, parse_strict='silent')
-        return isinstance(other, UnrecognizedUnit) and self.name == other.name
+        try:
+            other = Unit(other, parse_strict='silent')
+        except (ValueError, UnitsError, TypeError):
+            return NotImplemented
+
+        return isinstance(other, type(self)) and self.name == other.name
 
     def __ne__(self, other):
         return not (self == other)
```
