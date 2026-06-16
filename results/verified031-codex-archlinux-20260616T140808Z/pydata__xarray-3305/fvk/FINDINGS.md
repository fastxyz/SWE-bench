# Findings

Status after FVK audit: no open semantic code bugs found in the V1 attrs fix.
One documentation mismatch was fixed in V2.

## F1 - Closed code bug: DataArray attrs dropped by quantile

- Evidence: E1/E2/E3.
- Concrete input: `DataArray([0, 0], dims="x", attrs={"units": "K"}).quantile(.9, dim="x", keep_attrs=True)`.
- Observed pre-fix behavior from the issue: result attrs were empty.
- Expected behavior: result attrs contain `{"units": "K"}`.
- Root cause: `DataArray.quantile` delegates through a temporary dataset, but
  attrs live on the underlying variable; pre-fix `Variable.quantile` had no
  `keep_attrs` parameter and always returned a new variable without attrs.
- Obligations: PO-1, PO-4, PO-6.
- V2 status: fixed by the V1 semantic patch; no further semantic edit needed.

## F2 - Confirmed: false/default-false attrs behavior remains guarded

- Evidence: E7 and existing reduction convention.
- Concrete input: same as F1 with `keep_attrs=False`.
- Expected behavior: result attrs are empty.
- Risk checked: a naive fix in `DataArray.quantile` could copy attrs
  unconditionally and violate `keep_attrs=False`.
- Obligations: PO-2, PO-3, PO-7.
- V2 status: V1 handles this by resolving `keep_attrs` and applying it in
  `Variable.quantile`; no further semantic edit needed.

## F3 - Fixed documentation mismatch in DataArray.quantile

- Evidence: E10.
- Concrete input/documented API: `DataArray.quantile(..., keep_attrs=True)`.
- Observed V1 text: the `DataArray.quantile` docstring said "the dataset's
  attributes" even though `DataArray.attrs` delegates to `self.variable.attrs`.
- Expected documentation: this method copies the array's attrs.
- Obligations: PO-12.
- V2 status: fixed by changing the docstring to "array's attributes".

## F4 - Compatibility audit found no broken public call shape

- Evidence: E9 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Concrete call shapes checked: `v.quantile(q)`, `v.quantile(q, dim=...)`,
  `v.quantile(q, dim=..., interpolation=...)`, `Dataset.quantile(...)`,
  `DataArray.quantile(...)`, and `GroupBy.quantile(..., keep_attrs=...)`.
- Expected behavior: existing calls remain valid.
- Obligations: PO-10, PO-11.
- V2 status: no additional code change needed.

## Proof-derived findings from verify

- The proof model can distinguish the reported passing and failing cases because
  attrs are explicit maps in the observable result.
- Numeric quantile correctness is intentionally framed, not proved. Existing
  numeric tests should be kept; do not remove tests unless the `.k` artifacts are
  machine-checked and the test is within the proved attrs-only domain.
- No proof obligation forced a semantic change beyond the V1 patch. The only
  additional V2 change justified by the audit was the docstring correction in
  F3.
