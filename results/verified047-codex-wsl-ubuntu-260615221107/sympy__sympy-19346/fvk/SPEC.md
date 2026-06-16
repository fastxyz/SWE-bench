# FVK Spec: sympy__sympy-19346

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audit scope is the V1 production change for `srepr` container printing in
`repo/sympy/printing/repr.py`. The target observable is the string returned by
`srepr(expr)` for Python built-in `dict`, `set`, and the directly related
`frozenset` container. Existing list/tuple behavior and SymPy's immutable
`Dict` are frame conditions, not repair targets.

## Intent Spec

1. For a Python built-in `dict`, `srepr` must render each key and value with the
   same recursive repr printer used for list and tuple elements. Example intent:
   `{x: y}` prints as `{Symbol('x'): Symbol('y')}`, not `{x: y}`.
2. For a Python built-in `set`, `srepr` must render each element with the same
   recursive repr printer. Example intent: `{x, y}` prints as
   `{Symbol('x'), Symbol('y')}`, not `{x, y}`.
3. The output should remain an executable representation in the usual SymPy
   environment, consistent with the documented `eval(srepr(expr)) == expr`
   contract.
4. Unordered or order-insensitive containers may be emitted in a deterministic
   SymPy sort order. The issue does not impose insertion-order preservation for
   dict display, and dict equality does not depend on display order.
5. The public API shape of `srepr`, `ReprPrinter`, and printer dispatch must not
   change.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`srepr` prints the element in `list` and `tuple` correctly" with outputs containing `Symbol('x')` | Container elements should be recursively repr-printed. | Encoded in claims C-DICT, C-SET, C-FROZENSET. |
| E2 | prompt | "`srepr` prints the elements in `dict` and `set` wrong" with `{x, y}` and `{x: y}` | Built-in dict/set fallback to normal string form is the defect. | Encoded in expected outputs and findings FVK-F1/FVK-F2. |
| E3 | docs | `srepr` "generates executable code" and satisfies `eval(srepr(expr)) == expr` | Output must remain a Python-evaluable representation. | Encoded as syntax obligations PO3/PO6. |
| E4 | source | `ReprPrinter` already had `_print_list` and `_print_tuple`; base `Printer._print` dispatches by class name. | Built-in `dict`/`set` need `_print_dict`/`_print_set` methods to avoid `emptyPrinter`. | Encoded in PO1. |
| E5 | source | `StrPrinter`, `LatexPrinter`, and `PrettyPrinter` sort dict keys and set elements with `default_sort_key`. | Deterministic key/element order is a supported printer convention. | Encoded in PO4. |
| E6 | source | `Dict` is a SymPy `Basic` wrapper with its own class name and equality contract. | Avoid changing SymPy `Dict` repr unless separately required. | Encoded in PO5. |

## Formal Spec English

C-DICT: For every finite built-in dict represented by key/value pairs `PS`, if
the keys are unique, `srepr(dict(PS))` reaches a dict text whose pair list is
`sreprPairs(sortPairs(PS))`. `sortPairs` models `default_sort_key` over keys,
and `sreprPairs` recursively prints both key and value through the repr printer.

C-SET-EMPTY: `srepr(set())` reaches `emptySetText()`, corresponding to concrete
text `set()`.

C-SET-NONEMPTY: For every finite non-empty built-in set represented by `OS`,
`srepr(set(OS))` reaches a set text containing `sreprObjs(sortObjs(OS))`.
`sortObjs` models `default_sort_key`; `sreprObjs` recursively prints each
element through the repr printer.

C-FROZENSET-EMPTY: `srepr(frozenset())` reaches `frozensetText(emptySetText())`,
corresponding to concrete text `frozenset()`.

C-FROZENSET-NONEMPTY: For every finite non-empty built-in frozenset represented
by `OS`, `srepr(frozenset(OS))` reaches a frozenset text wrapping the same
sorted recursive set text used for non-empty sets.

Frame conditions: list and tuple behavior is unchanged; SymPy `Dict` behavior is
unchanged because no `_print_Dict` method was added; no public signatures or
settings changed.

## K Artifacts

The machine-checkable core is in:

- `fvk/mini-srepr.k`
- `fvk/srepr-container-spec.k`

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-srepr.k --backend haskell
kast --backend haskell fvk/srepr-container-spec.k
kprove fvk/srepr-container-spec.k
```

Expected result if the constructed model and claims are accepted by K:
`kprove` reduces the claims to `#Top`.

## Adequacy Audit

The formal claims cover the full public intent in this issue: built-in dict and
set elements are recursively repr-printed, and the output remains evaluable.
The frozenset claim is an intentionally small family extension justified by the
same built-in unordered-container mechanism and by sibling printers.

No formal claim preserves the legacy `{x, y}` or `{x: y}` output. Those displays
are marked as SUSPECT legacy behavior because the prompt presents them as the
bug.

The only output-order claim is deterministic `default_sort_key` order. This is
not derived from V1 alone: it is supported by existing SymPy printer source and
is compatible with dict/set equality and the executable-output contract.

## Public Compatibility Audit

Changed public symbol: none. V1 only adds private printer methods selected by
existing dispatch.

Changed function signatures: none.

Changed virtual dispatch call shape: none.

Public callsites of `srepr`: unchanged because `srepr(expr, **settings)` still
constructs `ReprPrinter(settings).doprint(expr)`.

Subclass/override risk: low. The new methods affect built-in container classes
through existing `Printer._print` dispatch. Existing object-level `_sympyrepr`
methods still take precedence, and SymPy `Dict` remains on its existing fallback
path because V1 does not add `_print_Dict`.
