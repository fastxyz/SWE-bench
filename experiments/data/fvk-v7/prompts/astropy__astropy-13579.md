# Guidance for Issue astropy__astropy-13579

**How to use the solved examples**

You are repairing an inconsistency in `world_to_pixel` between a full (unsliced) WCS and a sliced WCS (e.g., a 2D spatial slice from a 3D cube with a coupling PC matrix). The task text includes three solved examples, each a real bug that was fixed with a minimal, focused patch. Use them the way a senior engineer uses precedent:

- **Study the example issue → patch mapping**: identify which subsystem is touched, where the root cause sits relative to the symptom, how small and surgical the fix is, and what the patch deliberately did *not* change.
- **Transfer fix *shapes*, not text.** The examples solve *different* problems; never copy their line numbers, file names, or concrete code. What transfers is the diagnostic approach and the structural shape of the fix (e.g., reordering a computation so it always uses the best state, fixing an off‑by‑one threshold, correcting a string‑processing rule).
- **Note coding conventions** visible in the astropy example: deep in the library, a fix often touches a single method/regex and preserves existing public API. Patches are minimal (a few lines) and never restructure unrelated code.
- Then apply the most fitting pattern to the target issue: locate the root cause in the actual files, identify the precise point where slicing loses or distorts information needed by `world_to_pixel`, and shape a fix that is just as focused and minimal as the examples.

Below, each example is restated with its full issue description and the exact gold patch that resolved it. After each, a short analysis explains how it relates to your target inconsistency and what fix shape you should consider transferring.

---

### Example 1: astropy__astropy-14598

**Issue summary** (inconsistency in double single‑quote management in FITS Card):

> Inconsistency in double single-quote ('') management in FITS Card
> 
> ### Description
> 
> The management of single-quotes in FITS cards seem correct, except *sometimes* when dealing with null strings, i.e. double single quotes (`''`), which sometimes are transformed into single single quotes (`'`).
> 
> E.g.:
> ```python
> In [39]: from astropy.io import fits
> In [40]: for n in range(60, 70):
>     ...:     card1 = fits.Card('CONFIG', "x" * n + "''")
>     ...:     card2 = fits.Card.fromstring(str(card1))  # Should be the same as card1
>     ...:     print(n, card1.value == card2.value)
>     ...:     if card1.value != card2.value:
>     ...:         print(card1.value)
>     ...:         print(card2.value)
> ```
> gives
> ```
> 60 True
> 61 True
> 62 True
> 63 True
> 64 True
> 65 False
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx''
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
> 66 True
> 67 False
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx''
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
> 68 False
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx''
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
> 69 False
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx''
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
> ```
> ...

**Gold patch (verbatim):**

```diff
diff --git a/astropy/io/fits/card.py b/astropy/io/fits/card.py
--- a/astropy/io/fits/card.py
+++ b/astropy/io/fits/card.py
@@ -66,7 +66,7 @@ class Card(_Verify):
     # followed by an optional comment
     _strg = r"\'(?P<strg>([ -~]+?|\'\'|) *?)\'(?=$|/| )"
     _comm_field = r"(?P<comm_field>(?P<sepr>/ *)(?P<comm>(.|\n)*))"
-    _strg_comment_RE = re.compile(f"({_strg})? *{_comm_field}?")
+    _strg_comment_RE = re.compile(f"({_strg})? *{_comm_field}?$")
 
     # FSC commentary card string which must contain printable ASCII characters.
     # Note: \Z matches the end of the string without allowing newlines
@@ -859,7 +859,7 @@ def _split(self):
                     return kw, vc
 
                 value = m.group("strg") or ""
-                value = value.rstrip().replace("''", "'")
+                value = value.rstrip()
                 if value and value[-1] == "&":
                     value = value[:-1]
                 values.append(value)
```

**Relevance and transferable fix shape**

This is an astropy issue, so it directly shows the project’s patch style: the fix modifies only the exact regular expression and the specific string‑processing line that caused the inconsistency. The root cause was an incorrect *post‑processing rule* (the unconditional `replace("''", "'")`) that was applied whenever a string was extracted. The fix removed that rule and instead anchored the regex with `$` so the parser no longer needed to mangle the value afterwards.

**What to transfer**: In your WCS inconsistency, look for a post‑processing step or a transformation that is unconditionally applied to a sliced WCS but that distorts the coordinate mapping. The fix shape could be as simple as removing an unnecessary adjustment or correcting a regular expression/pattern that is used differently in the sliced vs. unsliced code path. Both the regex anchor fix and the removal of the `.replace` are examples of *undoing a wrong local adjustment* rather than adding new logic.

---

### Example 2: scikit-learn__scikit-learn-13142

**Issue summary** (GaussianMixture predict and fit_predict disagree when n_init>1):

> GaussianMixture predict and fit_predict disagree when n_init>1
> 
> #### Description
> When `n_init` is specified in GaussianMixture, the results of fit_predict(X) and predict(X) are often different.  The `test_gaussian_mixture_fit_predict` unit test doesn't catch this because it does not set `n_init`.
> ...

**Gold patch (verbatim):**

```diff
diff --git a/sklearn/mixture/base.py b/sklearn/mixture/base.py
--- a/sklearn/mixture/base.py
+++ b/sklearn/mixture/base.py
@@ -257,11 +257,6 @@ def fit_predict(self, X, y=None):
                 best_params = self._get_parameters()
                 best_n_iter = n_iter
 
-        # Always do a final e-step to guarantee that the labels returned by
-        # fit_predict(X) are always consistent with fit(X).predict(X)
-        # for any value of max_iter and tol (and any random_state).
-        _, log_resp = self._e_step(X)
-
         if not self.converged_:
             warnings.warn('Initialization %d did not converge. '
                           'Try different init parameters, '
@@ -273,6 +268,11 @@ def fit_predict(self, X, y=None):
         self.n_iter_ = best_n_iter
         self.lower_bound_ = max_lower_bound
 
+        # Always do a final e-step to guarantee that the labels returned by
+        # fit_predict(X) are always consistent with fit(X).predict(X)
+        # for any value of max_iter and tol (and any random_state).
+        _, log_resp = self._e_step(X)
+
         return log_resp.argmax(axis=1)
```

**Relevance and transferable fix shape**

Here two methods (`predict` and `fit_predict`) were inconsistent because an important computation (the final e‑step) was performed *before* the loop that selects the best parameters, so it used stale parameters when `n_init > 1`. The fix simply **moved the computation block to a later point**, after the best parameters are restored, guaranteeing that the final e‑step always uses the correct, final model state.

**What to transfer**: Your target has an inconsistency between two code paths: the full WCS `world_to_pixel` and the sliced WCS `world_to_pixel`. This often happens when slicing changes some internal state (e.g., the pixel shape or the mapping matrix) but a later step still relies on the state that was only valid for the full WCS. The fix shape may be to **reorder operations**: ensure that any computation that depends on the current WCS state (like the inverse transformation, pixel shape, or axis mapping) is *re‑evaluated* or *re‑applied* after slicing. Alternatively, if a shared object is mutated during slicing and not restored, the fix might be to save/restore that state, analogous to how this example moves the e‑step to use the restored parameters.

---

### Example 3: matplotlib__matplotlib-26113

**Issue summary** (inconsistent behavior of hexbin's mincnt parameter depending on C parameter):

> Inconsistent behavior of hexbins mincnt parameter, depending on C parameter
> 
> ### Bug report
> 
> **Bug summary**
> 
> Different behavior of `hexbin`s `mincnt` parameter, depending on whether the `C` parameter is supplied.
> ...

**Gold patch (verbatim):**

```diff
diff --git a/lib/matplotlib/axes/_axes.py b/lib/matplotlib/axes/_axes.py
--- a/lib/matplotlib/axes/_axes.py
+++ b/lib/matplotlib/axes/_axes.py
@@ -5014,7 +5014,7 @@ def reduce_C_function(C: array) -> float
             if mincnt is None:
                 mincnt = 0
             accum = np.array(
-                [reduce_C_function(acc) if len(acc) > mincnt else np.nan
+                [reduce_C_function(acc) if len(acc) >= mincnt else np.nan
                  for Cs_at_i in [Cs_at_i1, Cs_at_i2]
                  for acc in Cs_at_i[1:]],  # [1:] drops out-of-range points.
                 float)
```

**Relevance and transferable fix shape**

The inconsistency arose from a single, off‑by‑one comparison: `>` instead of `>=`. Because the condition depended on whether `mincnt` was supplied explicitly or defaulted, the behaviour diverged. The fix is a one‑character change that makes the threshold inclusive in all branches, eliminating the inconsistency without any other modifications.

**What to transfer**: In the WCS inconsistency, look for a **boundary condition or an indexing check** that behaves differently when the dimensions are reduced by slicing. For example, the PC matrix coupling might cause a calculation that uses a dimension index or compares against a length; when slicing removes a dimension, an off‑by‑one in a loop or a condition like `if dim == 3` vs `if dim >= 3` could shift the results for the remaining axes. The fix shape could be as small as changing a comparison operator or adjusting an index calculation to respect the reduced dimensionality, similar to this example’s `>` → `>=` change.
