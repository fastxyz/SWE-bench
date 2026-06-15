# FVK Findings

Status: audit findings from formalization and constructed verification. No
tests, Python, or K tooling were run.

## F1 - Original HTML writer ignored supplied formats

- Classification: code bug, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` says the HTML `formats` option is ignored,
  while CSV and RST respect the same format dictionary.
- Concrete input: a table with column `a = [1.23875234858e-24,
  3.2348748432e-15]`, written with `format="html"` and
  `formats={"a": lambda x: f"{x:.2e}"}`.
- Pre-V1 observed behavior: HTML cells for `a` use full precision, e.g.
  `1.23875234858e-24`.
- Expected behavior: HTML cells for `a` use the formatter, e.g. `1.24e-24`.
- V1 resolution: `HTML.write` now sets `self.data.cols = cols` and calls
  `self.data._set_col_formats()` before any `col.info.iter_str_vals()`
  iterator is created.
- Related obligations: O1, O2.

## F2 - Multicolumn temporary columns can bypass source-column formatting

- Classification: completeness risk in the HTML formatting pipeline, resolved
  by V1.
- Evidence: `HTML.write` splits multidimensional columns into new temporary
  `Column([el[i] for el in col])` objects before rendering subcells.
- Concrete input class: a multidimensional column `C2` rendered with
  `htmldict={"multicol": True}` and `formats={"C2": format_spec}`.
- Pre-V1 risk: even if the source column received `format_spec`, a newly
  constructed split column would have no copied `info.format`, so its
  `iter_str_vals()` call could render unformatted values.
- Expected behavior: the source column's active format applies uniformly to
  the HTML cells derived from that source column.
- V1 resolution: each temporary split column receives
  `new_col.info.format = col.info.format` before its iterator is constructed.
- Related obligations: O5.

## F3 - Proof is constructed over a focused mini-semantics

- Classification: proof capability boundary, not a code bug.
- Evidence: FVK MVP constructs proofs without running `kprove`, and the full
  Astropy/Python object model is larger than the bundled mini-language recipe.
- Consequence: The artifact proves the format-propagation path against a
  property-complete abstraction, not against full Python-in-K semantics.
- Recommended action: keep ordinary tests and, in an environment with K, run
  the emitted commands before treating any tests as proof-subsumed.
- Related obligations: O7.

## Proof-derived findings from `/verify`

The constructed proof found no additional source changes beyond V1. The only
open point is the honesty gate in F3: the proof was not machine-checked.
