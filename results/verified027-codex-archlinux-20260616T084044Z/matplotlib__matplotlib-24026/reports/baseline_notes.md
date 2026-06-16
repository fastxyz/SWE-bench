# Baseline Notes

## Root cause

`stackplot` handled an explicit `colors=` argument by calling
`axes.set_prop_cycle(color=colors)`. That had two undesirable effects:

- It replaced the Axes' property cycle even though `colors=` is local to this
  single stackplot call.
- It routed the supplied colors through the property-cycle color validator,
  which rejects `C0`-style cycle references. Those references are valid normal
  color specifications for artists such as lines and patches, so they should be
  accepted when used as stackplot face colors.

## Changed files

- `repo/lib/matplotlib/stackplot.py`: Replaced the `set_prop_cycle` call with a
  local `itertools.cycle` over the explicit `colors=` sequence. Stackplot now
  pulls layer colors from that local iterator when `colors` is supplied, and
  continues to use `axes._get_lines.get_next_color` when `colors` is omitted.
  This keeps explicit colors local to the stackplot call and lets artist color
  validation handle `C0`-style aliases.

## Assumptions and alternatives considered

- I treated the issue as applying to the explicit `colors=` path. The default
  no-`colors` behavior still consumes colors from the Axes line cycle, matching
  existing stackplot behavior and avoiding unrelated changes to default image
  output.
- I considered validating the supplied colors before plotting, but rejected that
  because the failure came from using the property-cycle validator specifically.
  Passing each value as `facecolor` to `fill_between` uses the normal artist
  color handling, which is the behavior requested by the issue.
- I considered switching stackplot's default colors to the patch/fill cycle, but
  that would be a broader compatibility change unrelated to accepting explicit
  `C0`-style colors without mutating the Axes property cycle.

No tests or matplotlib code were run, per the task instructions.
