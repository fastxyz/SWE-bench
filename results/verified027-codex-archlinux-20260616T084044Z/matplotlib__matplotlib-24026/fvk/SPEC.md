# FVK Spec: matplotlib__matplotlib-24026

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the color-selection behavior of
`repo/lib/matplotlib/stackplot.py::stackplot`, because V1 changed only that
behavior and the issue's traceback localizes the defect to color handling.
Numeric stacking, baseline calculations, label iteration, and
`fill_between` geometry are frame behavior: they must remain as in the
pre-existing implementation, but this proof does not re-verify their numerical
correctness.

## Public Intent Ledger

E1. Source: problem title. Evidence: "stackplot should not change Axes cycler".
Obligation: an explicit `colors=` argument must be local to the stackplot call
and must not reset the Axes property cycle. Status: encoded.

E2. Source: issue use case. Evidence: the user wants "colors synchronized
across plot types". Obligation: callers must be able to choose stackplot layer
colors explicitly, consistent with other plot primitives. Status: encoded.

E3. Source: issue example. Evidence: `ax.plot(..., color='C0')`,
`Rectangle(..., facecolor='C1')`, and
`ax.stackplot(..., colors=['C2', 'C3', 'C4'])`. Obligation: `C<N>` color-cycle
aliases are in-domain values for `stackplot(colors=...)`. Status: encoded.

E4. Source: issue traceback. Evidence: failure occurs at
`axes.set_prop_cycle(color=colors)` and the validator raises
`Cannot put cycle reference ('C2') in prop_cycler`. Obligation: explicit
stackplot colors must not be routed through the property-cycle validator.
Status: encoded.

E5. Source: stackplot docstring. Evidence: `colors` is "A sequence of colors
to be cycled through" and "The sequence need not be exactly the same length as
the number of provided y". Obligation: explicit colors repeat cyclically across
all stacked layers. Status: encoded.

E6. Source: stackplot docstring. Evidence: "If not specified, the colors from
the Axes property cycle will be used." Obligation: when `colors is None`,
preserve existing default behavior of drawing colors from the Axes line color
cycle. Status: encoded as frame behavior.

E7. Source: Matplotlib public API shape and V1 diff. Evidence: no signature
change to `stackplot`; call sites still pass `facecolor=color` to
`Axes.fill_between`. Obligation: no public API change and no changed producer
or consumer shape. Status: encoded.

## Intent-Only Contract

Let `M` be the number of stacked y-series, with `M >= 1`.

For an explicit non-empty finite color sequence `colors = [c0, ..., cN-1]`:

- `stackplot(..., colors=colors)` returns `M` `PolyCollection` objects.
- Collection `i` is passed `facecolor = colors[i mod N]`.
- `C<N>` aliases, including `C2`, are valid color values for this path.
- The Axes property cycle is not replaced and the Axes line-color iterator is
  not consumed by this explicit-colors path.
- All other visible stackplot behavior is unchanged.

For `colors is None`:

- stackplot continues to use `axes._get_lines.get_next_color` once per stacked
  layer, matching the legacy default behavior and the docstring's "colors from
  the Axes property cycle" statement.

Out of domain for this proof: empty explicit color sequences and invalid color
objects. The public issue and docstring define `colors` as a usable sequence of
colors; they do not specify empty-sequence behavior.

## Formal Core Summary

The formal model represents only the observable color-source state:

- `Axis(Index, Cycle)` models the Axes line color cycle.
- `Explicit(Colors)` models a local explicit color source.
- `Default(Axis)` models the default Axes-cycle source.
- `Collections(Facecolors)` models the sequence of facecolors passed to
  `fill_between`.

The associated K-style artifacts are:

- `fvk/mini-stackplot.k`: abstract mini semantics for explicit and default
  stackplot color selection.
- `fvk/stackplot-spec.k`: reachability claims with provenance comments.

Primary claims:

- `CLAIM-EXPLICIT-COLORS`: explicit colors produce cyclic layer facecolors.
- `CLAIM-EXPLICIT-AXES-FRAME`: explicit colors leave the Axes cycle state
  unchanged.
- `CLAIM-CN-NO-PROP-CYCLE-VALIDATOR`: `C<N>` aliases are accepted because the
  explicit path does not construct an Axes property cycle.
- `CLAIM-DEFAULT-LEGACY-CYCLE`: `colors is None` still consumes the Axes line
  color cycle once per layer.

## Adequacy Audit

The formal claims match E1-E7 for the changed behavior. The only ambiguous
reading is whether the title requires no cycle advancement even when
`colors is None`. I reject that as a code-change basis because E6 explicitly
documents use of the Axes property cycle for omitted colors, Matplotlib plot
methods conventionally advance cycles when defaults are consumed, and the issue
example uses explicit `colors=` to avoid that path.
