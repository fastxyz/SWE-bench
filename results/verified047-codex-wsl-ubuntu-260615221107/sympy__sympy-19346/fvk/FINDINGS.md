# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent
and source reasoning only.

## Findings From Formalization

### FVK-F1: Built-in set elements used legacy string rendering before V1

Input: `srepr({x, y})`

Observed pre-fix behavior from the issue: `{x, y}`

Expected behavior from prompt and docs: `{Symbol('x'), Symbol('y')}` up to the
deterministic container order chosen by the printer.

Classification: code bug, fixed by V1.

Evidence: E1, E2, E3. Proof obligation: PO1, PO2, PO3, PO4.

### FVK-F2: Built-in dict keys and values used legacy string rendering before V1

Input: `srepr({x: y})`

Observed pre-fix behavior from the issue: `{x: y}`

Expected behavior from prompt and docs: `{Symbol('x'): Symbol('y')}`.

Classification: code bug, fixed by V1.

Evidence: E1, E2, E3. Proof obligation: PO1, PO2, PO3, PO4.

### FVK-F3: Built-in frozenset had the same recursive-printing gap

Input: `srepr(frozenset({x, y}))`

Observed pre-V1 source behavior: no `_print_frozenset` existed in
`ReprPrinter`, so built-in frozenset would fall through to fallback string
formatting for contained SymPy objects.

Expected behavior by family reasoning: recursive element rendering in
`frozenset({Symbol('x'), Symbol('y')})`, with `frozenset()` for empty input.

Classification: related built-in container bug, fixed by V1.

Evidence: E3 and sibling printer handling of `frozenset` with `set`. Proof
obligation: PO2, PO3, PO4.

### FVK-F4: V1 dispatch localizes the reported cause

Input class: Python built-in `dict`, `set`, and `frozenset`

Observed V1 source behavior: `Printer._print` dispatches by class name, so
built-in `dict` reaches `_print_dict`, built-in `set` reaches `_print_set`, and
built-in `frozenset` reaches `_print_frozenset`.

Expected behavior: the reported containers should no longer reach
`emptyPrinter` and `str(expr)`.

Classification: confirmation; no further source edit required.

Evidence: E4. Proof obligation: PO1.

### FVK-F5: Dict display order is not specified by the issue, but deterministic order is justified

Input: a multi-key built-in dict whose insertion order differs from
`default_sort_key` order.

Observed V1 source behavior: keys are sorted by `default_sort_key`.

Expected behavior: every key and value must be recursively repr-printed and the
output must be evaluable; public intent does not require insertion-order display.
Existing SymPy printers use `default_sort_key` for dicts and sets, so V1's order
is a supported printer convention rather than an implementation-only guess.

Classification: resolved ambiguity, no source edit required.

Evidence: E3, E5. Proof obligation: PO4.

### FVK-F6: SymPy `Dict` remains outside the built-in dict repair

Input: `srepr(Dict({x: y}))`

Observed V1 source behavior: no `_print_Dict` was added, so the SymPy `Dict`
class keeps its existing `Basic`/fallback representation path.

Expected behavior: the issue examples are Python built-in literals, and changing
SymPy `Dict` could alter existing `eval(srepr(expr)) == expr` behavior for a
different public container type.

Classification: compatibility confirmation, no source edit required.

Evidence: E6. Proof obligation: PO5.

## Proof-Derived Findings From `/verify`

### FVK-F7: Machine checking remains pending

The K claims are constructed but were not run through `kompile`, `kast`, or
`kprove`, per task constraints. Test removal is therefore not justified by this
session.

Classification: proof honesty gate, not a code bug.

Recommended next action: run the commands listed in `fvk/PROOF.md` in an
environment with K installed before treating the claims as machine-checked.
