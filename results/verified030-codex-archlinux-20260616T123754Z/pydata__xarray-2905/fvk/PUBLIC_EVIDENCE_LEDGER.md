# Public Evidence Ledger

Status: public/user evidence only. Candidate implementation facts are marked as
implementation evidence and are not used as intent by themselves.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue title | "Variable.__setitem__ coercing types on objects with a values property" | Assignment through `Variable.__setitem__` must not coerce arbitrary `.values` objects to that property. | Encoded by PO1, PO2, K claim `ARBITRARY-VALUES-PRESERVED`. |
| E2 | prompt minimal example | `bad_indexed.loc[{'dim_0': 0}] = HasValues()` currently gives `array([array(5)], dtype=object)` | The pre-fix behavior `object -> object.values` is the defect, not a compatibility target. | Finding F1; pre-fix display marked SUSPECT legacy behavior. |
| E3 | prompt expected output | `bad_indexed.values => array([< __main__.HasValues instance>], dtype=object)` | Expected assignment result contains the original `HasValues` object. | Encoded by PO2. |
| E4 | prompt problem description | "prevents storing objects inside arrays of `dtype==object` even when only performing non-broadcasted assignments if the RHS has a `values` property" | Object preservation applies to arbitrary scalar objects in object-dtype storage, at least for scalar/non-broadcasted assignment. | Encoded by PO1, PO2. |
| E5 | prompt use case | "store `ModelResult` instances from ... `lmfit`" | The obligation is not limited to the toy class; third-party scalar objects with `.values` are in scope. | Encoded by PO1. |
| E6 | public maintainer hint | "it should be supported" for "object type array other than string" | Object arrays are intended to hold arbitrary Python objects. | Encoded by PO1. |
| E7 | public maintainer hint | "change this line to more explicit type checking" | The generic `.values` attribute probe is too broad. | Encoded by PO1, PO4. |
| E8 | public maintainer hint | `xr.DataArray(HasValues, dims=[])` currently produces `array(5)` | Scalar construction path has the same defect and is in scope. | Finding F2; encoded by PO3. |
| E9 | public discussion | "It's a little silly to assume that every object with a `.values` attribute is an xarray.DataArray, xarray.Variable, pandas.Series or pandas.DataFrame." | Positive explicit-unwrapping set includes xarray/pandas containers; arbitrary `.values` objects must not be unwrapped. | Encoded by PO1, PO4. |
| E10 | public maintainer suggestion | `if isinstance(data, (pd.Series, pd.Index, pd.DataFrame)): data = data.values` | Type-based unwrapping is acceptable; in this repository `pd.Index` already has earlier adapter handling, so the index frame condition must be preserved. | Encoded by PO4, PO5. |
| E11 | public tests | `TestAsCompatibleData.test_unchanged_types` expects `PandasIndexAdapter` and `LazilyOuterIndexedArray` to preserve their source ndarray. | Existing special array adapter behavior must not be disturbed. | Encoded by PO5. |
| E12 | public tests | `TestAsCompatibleData.test_converted_types` includes `pd.DataFrame([[0, 1, 2]])` as converted data. | `DataFrame` remains an intentional container conversion. | Encoded by PO4. |
| E13 | public tests | `TestDataArray` constructs from `DataArray`, `DataFrame`, `Series`, `Panel`, and `pd.Index`. | DataArray/pandas constructor compatibility is a frame condition. | Encoded by PO4, PO5, PO7. |
| E14 | implementation | `Variable.__setitem__` calls `as_compatible_data(value)` before wrapping scalar values as `Variable((), value)`. | Assignment proof must pass through the helper rather than a separate special case. | Used in PO2 proof, not intent by itself. |
| E15 | implementation | `DataArray.__init__` calls `_check_data_shape(...)` and then `as_compatible_data(data)`. | Construction proof must pass through the helper. | Used in PO3 proof, not intent by itself. |
