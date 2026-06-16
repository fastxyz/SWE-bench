# FVK Spec: xarray unicode index copy

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Intent Spec

The public issue requires copy operations to preserve the dtype xarray exposes
for `IndexVariable` coordinates with NumPy fixed-width unicode dtype `<U*>`.
The specific regression is that deep copying changes the dimension coordinate
from `<U3` to `object`.

The intended observable is dtype preservation, not object identity of the
private pandas index. For an `IndexVariable` whose adapter dtype is `<U N>`, the
copied variable must also expose `<U N>`.

The issue text mentions `DataArray.copy(deep=True/False)`, but the public hint
corrects that `DataArray.copy(deep=False)` is not affected. In this checkout,
`__copy__` for `Variable`, `Dataset`, and `DataArray` routes through
`deep=False`, so shallow-copy preservation remains a frame condition rather than
a new failing branch.

## Public Evidence Ledger

E1. Source: prompt. Quote: "REGRESSION: copy(deep=True) casts unicode indices to
object." Obligation: `IndexVariable.copy(deep=True)` must preserve unicode
adapter dtype. Status: encoded by PO-1 and K claim `unicode(N), true`.

E2. Source: prompt example. Quote: `ds.copy(deep=True)` changes coordinate `x`
from `<U3 'foo'` to `object 'foo'`. Obligation: dataset-level deep copy must
compose the component `IndexVariable` guarantee. Status: encoded by PO-4.

E3. Source: prompt example. Quote: `ds.z.copy()` and `ds.z.copy(deep=True)` show
the `x` coordinate as object. Obligation: DataArray copy must preserve coordinate
index dtype when it copies coordinates. Status: encoded by PO-5.

E4. Source: public hint. Quote: "Correction, DataArray.copy(deep=False) is not
affected." Obligation: do not treat shallow `DataArray.copy(deep=False)` as a
separate broken path, but still preserve dtype as a frame condition. Status:
encoded by PO-2 and Finding F-002.

E5. Source: source docstring/name. Quote: `copy` returns a "New object with
dimensions, attributes, encodings, and optionally data copied from original."
Obligation: copy must not change dtype metadata unless replacement `data` is
provided. Status: encoded by PO-1 through PO-6.

E6. Source: implementation. `PandasIndexAdapter.__init__` stores
`self.array = utils.safe_cast_to_index(array)` and separately stores
`self._dtype`; `__array__` defaults to that adapter dtype. Obligation: a copy
that reconstructs a `PandasIndexAdapter` must preserve the adapter dtype when
the pandas index dtype differs. Status: encoded by PO-1 and K state
`adapter(PANDAS, ADAPTER)`.

## Formal Spec English

Claim C1: For every positive unicode width `N`, if an `IndexVariable` has a
pandas index whose dtype may be `object` but has adapter dtype `unicode(N)`, then
`copy(deep=True, data=None)` returns an `IndexVariable` whose adapter dtype is
still `unicode(N)`.

Claim C2: For every positive unicode width `N`, the shallow `deep=False` copy of
the same state preserves adapter dtype `unicode(N)`.

Claim C3: For every adapter dtype `D`, the deep-copy branch preserves `D`,
independent of the dtype reported by the underlying pandas index.

Dataset and DataArray obligations are compositional: they call `copy` on their
component variables/coordinates, so if each component preserves dtype then the
container-visible dtype is preserved.

## Spec Audit

C1 passes. It is directly entailed by E1 and E2.

C2 passes. It is a frame condition supported by E4 and the copy contract in E5.
It also prevents overfitting the spec only to `deep=True`.

C3 passes. It is the generalized form of C1 and is justified by the copy
contract in E5 plus the adapter implementation evidence in E6. It is not derived
from V1's current output alone: the independent intent is dtype preservation
during copy.

The issue's broad statement about `copy.copy()` is ambiguous against this
checkout and the public correction. The spec therefore requires shallow-copy
dtype preservation but does not require changing the `__copy__` dispatch.

## Public Compatibility Audit

No public function signature changed. `IndexVariable.copy(self, deep=True,
data=None)` retains the same parameters and return type. `Dataset.copy`,
`DataArray.copy`, `__copy__`, and `__deepcopy__` call sites remain compatible
because V1 only changes the value passed to `PandasIndexAdapter` inside the
existing deep-copy branch.

No subclass override incompatibility was introduced by V1: no new keyword,
virtual dispatch shape, or public protocol was added.

## Supporting Formal Core

The supporting formal core is in:

- `fvk/mini-xarray-copy.k`
- `fvk/xarray-copy-spec.k`

The model deliberately keeps the dtype axis visible as
`adapter(PANDAS_DTYPE, ADAPTER_DTYPE)`. This passes the FVK discriminator test:
a failing pre-fix state maps to `adapter(object, object)` after deep copy, while
the intended/V1 state maps to `adapter(object, unicode(N))`; the model can
distinguish the bug from the fix.
