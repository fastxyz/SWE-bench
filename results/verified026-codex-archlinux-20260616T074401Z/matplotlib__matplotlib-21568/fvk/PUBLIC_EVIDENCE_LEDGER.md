# Public Evidence Ledger

This ledger mirrors the entries in `fvk/SPEC.md`.

E1: Problem summary says "Datetime axis with usetex is unclear".
Obligation: TeX-rendered datetime labels must be visually clear.

E2: Expected outcome asks for "spacing from version 3.3 in a tex format".
Obligation: TeX wrapping must preserve visible separation that normal text had.

E3: Public hint says "protecting spaces didn't happen properly".
Obligation: Regular spaces inside math mode must be replaced by a TeX spacing
command.

E4: Public workaround replaces `-`, `:`, and space before wrapping in
`\mathdefault`.
Obligation: Protect the separator family `-`, `:`, and space.

E5: Formatter docstrings describe `usetex` as using TeX math mode.
Obligation: The TeX path changes; non-TeX output remains raw formatter text.

E6: Existing public tests keep alphabetic month text outside `\mathdefault`.
Obligation: Preserving alphabetic splitting is compatible unless it conflicts
with E1-E4. It does not.

E7: Existing public tests keep raw spaces and colons in `\mathdefault`.
Obligation: Mark as SUSPECT because E1-E4 identify that behavior as buggy.

E8: Source call sites route built-in date formatter TeX labels through
`_wrap_in_tex`.
Obligation: A helper-level fix covers the built-in formatter paths.
