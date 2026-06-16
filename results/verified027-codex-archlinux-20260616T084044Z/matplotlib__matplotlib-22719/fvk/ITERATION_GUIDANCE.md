# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 source code unchanged.

## Rationale

- F-001 is resolved by PO-1: `values.size and is_numlike` prevents empty data
  from entering the deprecated numeric pass-through branch.
- F-002 is resolved by PO-5: `data.size and convertible` prevents empty update
  data from emitting the all-convertible log.
- PO-2, PO-3, PO-4, and PO-6 show that the guards preserve non-empty numeric
  warnings, accepted categorical conversion, invalid mixed-type rejection, and
  non-empty all-convertible logging.
- PO-7 and `PUBLIC_COMPATIBILITY_AUDIT.md` show no API or dispatch repair is
  required.

## Rejected follow-up edits

- Do not change `Axis.convert_units`: F-001 localizes the cause to the category
  converter's vacuous numeric classification, and E4 is satisfied by fixing the
  converter path used by both plotting and direct conversion.
- Do not suppress all numeric pass-through warnings: F-003 and PO-2 preserve the
  public non-empty numeric deprecation behavior.
- Do not special-case `Axes.plot`: E4 shows the same bug through
  `ax.convert_xunits([])`, so plotting-only handling would be incomplete.
- Do not edit tests: benchmark instructions forbid test changes, and the proof
  is constructed rather than machine-checked.

## Suggested future validation

In a normal environment, add or run tests covering:

- `ax.plot([], [])` after `ax.xaxis.update_units(["a", "b"])` emits no
  `MatplotlibDeprecationWarning`.
- `ax.convert_xunits([])` on a category-unit axis returns an empty converted
  result without warning.
- Non-empty numeric pass-through still warns.
- Non-empty mixed string/numeric data still fails validation.

These are recommendations only; no tests were run or modified here.
