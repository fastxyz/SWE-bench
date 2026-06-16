# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Standard Creator Power Grouping

For every secondquant creation operator base `C` with direct LaTeX `L` and every
exponent string `E`, the standard power path must produce `{L}^{E}`.

Evidence: SPEC ledger E2, E3, E7, E8.

Discharging source points:

- `Creator._latex_power_base` returns `{printer._print(self)}`.
- `LatexPrinter._helper_print_standard_power` uses `_latex_power_base` when the
  base provides it, then applies the standard `"%s^{%s}"` template.

## PO2 - Folded Fractional Creator Power Grouping

For every secondquant creation operator base `C` with direct LaTeX `L` and every
folded rational exponent `P/Q`, the folded fractional-power path must produce
`{L}^{P/Q}`.

Evidence: SPEC ledger E3 and E8.

Discharging source points:

- `LatexPrinter._print_Pow` checks `_latex_power_base` before calling
  `parenthesize`.
- V2 guards the function fallback with `custom_base is None`, so a custom base is
  not bypassed if a future hooked base also satisfies `is_Function`.

## PO3 - Daggered Double-Superscript Exclusion

For a creator base whose direct LaTeX contains an internal dagger superscript,
the final powered output must not contain the ungrouped pattern
`^\dagger_{...}^{...}`.

Evidence: SPEC ledger E2 and E3.

Discharging source points:

- PO1 and PO2 put braces around the whole direct creator LaTeX before the outer
  exponent is appended.

## PO4 - Direct Creator Printing Frame

For direct, unpowered printing, `Bd(i)` must still print as `b^\dagger_{i}` and
`Fd(p)` must still print as `a^\dagger_{p}`.

Evidence: SPEC ledger E4 and E5.

Discharging source points:

- `CreateBoson._latex` and `CreateFermion._latex` are unchanged.
- `_latex_power_base` is only reached through `LatexPrinter._print_Pow`.

## PO5 - Non-Creator Printer Frame

For bases without `_latex_power_base`, standard and folded fractional power
printing must keep the previous branch behavior.

Evidence: SPEC ledger I4 and E6.

Discharging source points:

- Both modified branches fall back to the original `parenthesize` logic when
  `custom_base is None`.
- The existing symbol-specific `parenthesize_super` check remains guarded by the
  same `expr.base.is_Symbol` condition, with the extra `custom_base is None`
  condition vacuous for ordinary symbols.
- The existing function-specific exponent formatting remains available when no
  custom hook is present.

## PO6 - Public Compatibility

The fix must not require changes to public callsites, class constructors, aliases,
or existing `_latex` method signatures.

Evidence: SPEC compatibility audit.

Discharging source points:

- The only new method is private and optional.
- Existing constructor, dagger, application, and direct `_latex` methods retain
  their signatures.

