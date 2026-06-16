# Public Compatibility Audit

Changed symbol: `Creator`.

Change: adds private method `_latex_power_base(self, printer)`.

Compatibility status: pass. Existing construction, aliases, `apply_operator`,
dagger methods, and direct `_latex` methods are unchanged.

Changed symbol: `LatexPrinter._print_Pow` and
`LatexPrinter._helper_print_standard_power`.

Change: optionally consult `_latex_power_base` on a power base.

Compatibility status: pass. Objects without the hook follow the legacy paths.
Existing symbol and function behavior remains guarded by `custom_base is None`.

Changed public output: powered `CreateBoson` and `CreateFermion`.

Compatibility status: intentional. This is the public issue's required behavior
change for daggered secondquant creator bases.

Public tests/callsites checked by source inspection: direct `Bd` and `Fd` LaTeX
expectations remain compatible because direct `_latex` implementations are
unchanged.

