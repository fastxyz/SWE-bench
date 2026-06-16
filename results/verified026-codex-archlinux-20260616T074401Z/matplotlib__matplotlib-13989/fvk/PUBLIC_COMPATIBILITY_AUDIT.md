# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

No public function signature, return type, import path, virtual dispatch call,
or storage format changed in V1.

The only source change is internal kwargs construction in
`Axes.hist`.

## Public callers and wrappers

- `matplotlib.pyplot.hist` delegates to `Axes.hist` with the same public
  keyword names. V1 does not change that wrapper.
- Existing callers using `range`, `density`, `normed`, or `stacked` retain the
  same API shape.

## Subclasses and overrides

The audited change does not add arguments to a virtual method call and does
not alter an override contract. It only changes the internal dictionary passed
to `np.histogram`.

## Compatibility findings

No compatibility blocker was found.

Frame condition: stacked density remains manually normalized later in
`Axes.hist`; V1 does not pass `density=True` to `np.histogram` when
`stacked=True`.
