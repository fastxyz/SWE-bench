# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What Is Proved

For every in-domain `stackplot` call with explicit non-empty `colors`, V1
passes cyclic facecolors to `fill_between`, accepts `C<N>` aliases by avoiding
property-cycle validation, and preserves the Axes line color cycle state. For
`colors is None`, V1 preserves the legacy behavior of consuming one Axes line
cycle color per stacked layer.

## Constructed Proof Sketch

1. Branch split on `colors is not None`.

In the explicit branch, V1 executes:

```python
color_cycle = itertools.cycle(colors)
next_color = color_cycle.__next__
```

No statement in this branch writes to `axes` or calls
`axes.set_prop_cycle`. Therefore the Axes cycle state is framed.

2. Layer emission.

The first `fill_between` call receives `facecolor=next_color()`. The loop then
runs exactly `M - 1` times and each iteration also receives
`facecolor=next_color()`. By induction on emitted layers, the sequence of
facecolors is the first `M` values of the local cycle over `colors`, namely
`colors[i mod len(colors)]`.

3. `C<N>` aliases.

The pre-fix failure required the path
`colors -> axes.set_prop_cycle -> validate_color_for_prop_cycle`, where
`validate_color_for_prop_cycle` rejects `C<N>` references. V1 removes that
path. The alias instead flows as
`colors -> local cycle -> fill_between(facecolor=...)`, which is the same
artist-color handling shape used by the successful `plot` and `Rectangle`
examples in the issue.

4. Default path.

When `colors is None`, V1 binds:

```python
next_color = axes._get_lines.get_next_color
```

The same first-layer and loop structure then calls that method exactly once
per layer. This is equivalent to legacy behavior for omitted colors and
preserves existing image-output expectations.

5. Compatibility and frame.

The function signature, return construction, label handling, baseline
branches, stack computation, and `fill_between` producer remain unchanged.
Thus the proof only changes the explicit color source and frames all other
observable behavior.

## Adequacy Gate

The formal English claims in this file match `fvk/SPEC.md`:

- Explicit colors are local and cyclic: pass.
- `C<N>` aliases are accepted through artist color handling: pass.
- Explicit colors do not mutate or consume the Axes cycle: pass.
- Omitted colors retain legacy cycle consumption: pass, with the ambiguity in
  F3 recorded and rejected as a basis for source change.
- Numeric geometry is not re-proved: pass as an explicit proof boundary, not a
  hidden claim.

## Machine-Check Commands

These commands are emitted for later checking only. They were not run.

```sh
cd fvk
kompile mini-stackplot.k --backend haskell
kast --backend haskell stackplot-spec.k
kprove stackplot-spec.k
```

Expected machine-check result after the abstract K model is accepted:
`kprove` returns `#Top` for the listed claims.

## Test Guidance

No test files were modified. Recommended tests to add or keep in the fixed
suite:

- Add: `stackplot(colors=['C2', 'C3', 'C4'])` does not raise.
- Add: explicit `colors=` does not change the next automatic Axes color.
- Add: a shorter explicit color sequence repeats across more layers.
- Keep: existing stackplot image tests for baseline and geometry.

No tests should be removed unless the K commands above are run successfully and
the project maintainers choose to use the proof to subsume narrow unit cases.
