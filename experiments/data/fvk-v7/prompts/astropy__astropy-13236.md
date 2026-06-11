# Guidance: Using the Solved Examples to Repair astropy__astropy‑13236

Study each solved example carefully. They are not blueprints that you copy line‑by‑line; their value lies in the **diagnostic approach** and the **fix shape** they reveal. Focus on:

- Where the root cause lived relative to the reported symptom.
- How small and targeted the patch was (often a single conditional change).
- Whether the fix adds a guard, narrows an existing condition, removes an unnecessary conversion, or corrects a dtype‑inference path.
- The conventions of the codebase (numpy‑heavy, public API preservation, error‑handling style).

Then apply the most fitting *pattern* to the new issue, keeping your own fix equally focused.

---

### Example 1: astropy__astropy‑8872

**Issue Summary**  
`float16` quantities are automatically upgraded to `float64` when the `Quantity` is created, while other float widths (`float32`, `float64`, `float128`) are preserved. The casting logic in `Quantity.__new__` used `np.can_cast(np.float32, value.dtype)` to decide whether to force a float dtype – a check that unintentionally excluded `float16`.

**Relevance to target**  
The problem was an over‑broad *conversion condition* that incorrectly triggered dtype changes. The fix replaced a complex `can_cast` test with a simpler, more precise check using `dtype.kind` (`value.dtype.kind in 'iu'` and later `in 'iuO'`). This is a classic *narrow‑the‑condition* pattern: keep the conversion only for the types that genuinely need it (integers, object), and let everything else pass through unchanged.

**Transfer to astropy‑13236**: The auto‑transform of a structured ndarray into `NdarrayMixin` is currently governed by a condition like “if not isinstance(data, Column) and …”. That condition is likely too wide after the changes in #12644, because structured columns may now work correctly. The fix shape you should look for is to **narrow or remove** that transforming branch – analogous to how the `float16` cast was removed by refining the condition to exclude types that already behave correctly. Do not blindly replace the condition with a `dtype.kind` check; instead, find the current gate and make it skip the conversion for cases where it is no longer needed.

**Gold patch**  
```diff
diff --git a/astropy/units/quantity.py b/astropy/units/quantity.py
--- a/astropy/units/quantity.py
+++ b/astropy/units/quantity.py
@@ -215,8 +215,8 @@ class Quantity(np.ndarray, metaclass=InheritDocstrings):
     dtype : ~numpy.dtype, optional
         The dtype of the resulting Numpy array or scalar that will
         hold the value.  If not provided, it is determined from the input,
-        except that any input that cannot represent float (integer and bool)
-        is converted to float.
+        except that any integer and (non-Quantity) object inputs are converted
+        to float by default.
 
     copy : bool, optional
         If `True` (default), then the value is copied.  Otherwise, a copy will
@@ -296,8 +296,7 @@ def __new__(cls, value, unit=None, dtype=None, copy=True, order=None,
                 if not copy:
                     return value
 
-                if not (np.can_cast(np.float32, value.dtype) or
-                        value.dtype.fields):
+                if value.dtype.kind in 'iu':
                     dtype = float
 
             return np.array(value, dtype=dtype, copy=copy, order=order,
@@ -377,9 +376,7 @@ def __new__(cls, value, unit=None, dtype=None, copy=True, order=None,
                             "Numpy numeric type.")
 
         # by default, cast any integer, boolean, etc., to float
-        if dtype is None and (not (np.can_cast(np.float32, value.dtype)
-                                   or value.dtype.fields)
-                              or value.dtype.kind == 'O'):
+        if dtype is None and value.dtype.kind in 'iuO':
             value = value.astype(float)
 
         value = value.view(cls)
```

---

### Example 2: pydata__xarray‑2905

**Issue Summary**  
Assigning an object that has a `.values` attribute into an object‑dtype `DataArray` triggered accidental coercion. The code used `data = getattr(data, "values", data)` to unwrap pandas‑like containers, but this blanket `getattr` grabbed the `.values` of *any* user object, breaking the stored data. The fix narrowed the unwrap to only `pd.Series`, `pd.Index`, and `pd.DataFrame` instances.

**Relevance to target**  
This is a *guard‑by‑type* pattern: an operation that was applied too generally is restricted via explicit `isinstance` checks. The original code treated “anything with a `.values`” as a pandasish object; the fix makes it selective, preserving the original object for everything else.

**Transfer to astropy‑13236**: The current auto‑transform of a structured ndarray into `NdarrayMixin` may be triggered by a blanket condition that treats *any* structured array as problematic. The fix for this target may similarly require adding an `isinstance` guard to skip the transformation when the data is already a `Column`, or when the structured array can be handled natively. That is, you might keep the conversion only for the cases that genuinely need it (just as the xarray fix kept `.values` extraction only for pandas types) and let other structured inputs flow through unchanged.

**Gold patch**  
```diff
diff --git a/xarray/core/variable.py b/xarray/core/variable.py
--- a/xarray/core/variable.py
+++ b/xarray/core/variable.py
@@ -218,7 +218,8 @@ def as_compatible_data(data, fastpath=False):
         data = np.timedelta64(getattr(data, "value", data), "ns")
 
     # we don't want nested self-described arrays
-    data = getattr(data, "values", data)
+    if isinstance(data, (pd.Series, pd.Index, pd.DataFrame)):
+        data = data.values
 
     if isinstance(data, np.ma.MaskedArray):
         mask = np.ma.getmaskarray(data)
```

---

### Example 3: pydata__xarray‑3095

**Issue Summary**  
`Dataset.copy(deep=True)` and `DataArray.copy(deep=True)` cast Unicode indices (`dtype='<U3'`) to object, a regression introduced after v0.12.1. The `PandasIndexAdapter.__init__` was not preserving the original dtype when the array was copied, and `__array__` did not respect the stored dtype. The fix added proper dtype handling in `__init__` (reading the array’s dtype directly) and used that dtype in `__array__`.

**Relevance to target**  
The core issue was an **unnecessary conversion step that lost type information** – similar to the structured array being forced into an `NdarrayMixin`, which loses the natural `Column`‑like behavior. The fix removed the aggressive dtype inference and preserved the original dtype.

**Transfer to astropy‑13236**: The patch did not add a new, complex type‑handling pathway; it simply removed the part that destroyed the dtype. In the target, the transformation to `NdarrayMixin` may now be entirely unnecessary because structured columns work after #12644. The fix shape could be to **delete or comment out** the conversion block, or to add an early return that bypasses it for structured arrays that are already compatible with `Column`. The pattern is: if a conversion only exists to work around an old limitation that no longer exists, the cleanest fix is to eliminate the conversion.

**Gold patch**  
```diff
diff --git a/xarray/core/indexing.py b/xarray/core/indexing.py
--- a/xarray/core/indexing.py
+++ b/xarray/core/indexing.py
@@ -3,12 +3,13 @@
 from collections import defaultdict
 from contextlib import suppress
 from datetime import timedelta
-from typing import Sequence
+from typing import Any, Tuple, Sequence, Union
 
 import numpy as np
 import pandas as pd
 
 from . import duck_array_ops, nputils, utils
+from .npcompat import DTypeLike
 from .pycompat import dask_array_type, integer_types
 from .utils import is_dict_like
 
@@ -1227,9 +1228,10 @@ def transpose(self, order):
 
 
 class PandasIndexAdapter(ExplicitlyIndexedNDArrayMixin):
-    """Wrap a pandas.Index to preserve dtypes and handle explicit indexing."""
+    """Wrap a pandas.Index to preserve dtypes and handle explicit indexing.
+    """
 
-    def __init__(self, array, dtype=None):
+    def __init__(self, array: Any, dtype: DTypeLike = None):
         self.array = utils.safe_cast_to_index(array)
         if dtype is None:
             if isinstance(array, pd.PeriodIndex):
@@ -1241,13 +1243,15 @@ def __init__(self, array, dtype=None):
                 dtype = np.dtype('O')
             else:
                 dtype = array.dtype
+        else:
+            dtype = np.dtype(dtype)
         self._dtype = dtype
 
     @property
-    def dtype(self):
+    def dtype(self) -> np.dtype:
         return self._dtype
 
-    def __array__(self, dtype=None):
+    def __array__(self, dtype: DTypeLike = None) -> np.ndarray:
         if dtype is None:
             dtype = self.dtype
         array = self.array
@@ -1258,11 +1262,18 @@ def __array__(self, dtype=None):
         return np.asarray(array.values, dtype=dtype)
 
     @property
-    def shape(self):
+    def shape(self) -> Tuple[int]:
         # .shape is broken on pandas prior to v0.15.2
         return (len(self.array),)
 
-    def __getitem__(self, indexer):
+    def __getitem__(
+            self, indexer
+    ) -> Union[
+        NumpyIndexingAdapter,
+        np.ndarray,
+        np.datetime64,
+        np.timedelta64,
+    ]:
         key = indexer.tuple
         if isinstance(key, tuple) and len(key) == 1:
             # unpack key so it can index a pandas.Index object (pandas.Index
@@ -1299,9 +1310,20 @@ def __getitem__(self, indexer):
 
         return result
 
-    def transpose(self, order):
+    def transpose(self, order) -> pd.Index:
         return self.array  # self.array should be always one-dimensional
 
-    def __repr__(self):
+    def __repr__(self) -> str:
…
```
