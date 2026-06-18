# Findings

Status: constructed, not machine-checked.

## F1: V1 addresses the reported dict/set recursive-printing defect

Input: `srepr({x, y})`

- Legacy symptom from prompt: `{x, y}`
- Expected by intent: set members use `srepr` spelling, modeled as `{Symbol('x'), Symbol('y')}`
- V1 mechanism: `_print_set` sorts members and calls `reprify`, which calls `doprint` on each member.

Input: `srepr({x: y})`

- Legacy symptom from prompt: `{x: y}`
- Expected by intent: key and value use `srepr` spelling, modeled as `{Symbol('x'): Symbol('y')}`
- V1 mechanism: `_print_dict` sorts keys and prints both key and value with `self._print`.

Classification: confirmed fix, constructed not machine-checked.

Recommended code action: no source edit.

## F2: V1 preserves the existing list/tuple regression frame

Input: `srepr([x, y])` and `srepr((x, y))`

- Public intent: these already print correctly and should not change.
- V1 does not edit `_print_list` or `_print_tuple`.
- The K regression claims preserve `[Symbol('x'), Symbol('y')]` and `(Symbol('x'), Symbol('y'))`.

Classification: regression-free for the named scenarios.

Recommended code action: no source edit.

## F3: SymPy Dict handling is an intentional compatibility extension, not a counterexample

Input: modeled `srepr(Dict({x: y}))`

- Risk audited: adding `_print_Dict` could have degraded a SymPy `Dict` to a plain dict literal.
- V1 output shape: `Dict({Symbol('x'): Symbol('y')})`.
- This keeps the wrapper and remains aligned with the eval-friendly `srepr` contract.

Classification: regression risk discharged by claim and compatibility audit.

Recommended code action: no source edit.

## F4: Exact sorting semantics are abstracted

The artifacts model `default_sort_key` with `sortVals` and `sortPairs`. Concrete x/y issue claims reduce to x before y. General sorting correctness is not reimplemented in the mini semantics.

Classification: proof capability and abstraction boundary, not a code bug. The public issue's core requirement is recursive content printing; exact ordering is compatibility-derived from other SymPy printers.

Recommended code action: no source edit. Keep ordering tests if added until the emitted K commands are machine-checked and any richer sorting model is supplied.

## Proof-derived findings from /verify

No concrete counterexample or unmet proof obligation was found that V1 demonstrably fails. Under the revision discipline, V1 stands unchanged.
