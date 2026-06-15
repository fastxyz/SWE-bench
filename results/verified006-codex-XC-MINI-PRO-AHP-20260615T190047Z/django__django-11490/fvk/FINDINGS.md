# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations. No tests,
Python, or K tooling were executed.

## F-001: Pre-fix child-query mutation causes stale selected columns

Classification: code bug, resolved by V1.

Evidence:

- Intent ledger I-001 and I-002 require repeated `values()` /
  `values_list()` evaluations of a combined queryset to independently choose
  their output columns.
- In the pre-fix compiler shape, `get_combinator_sql()` built compilers
  directly from the child queries in `combined_queries`.
- The compiler then called `compiler.query.set_values(...)` when the child had
  no `values_select` and the outer combined query did have one.

Concrete counterexample from the issue:

```py
qs = ReservedName.objects.all()
qs.union(qs).values_list('name', 'order').get()
qs.union(qs).values_list('order').get()
```

Observed pre-fix behavior: the second result still uses the old two-column
selection and returns a tuple shaped like `('a', 2)`.

Expected behavior: the second result's selected column list is only `order`, so
`values_list('order')` returns a one-column tuple.

Resolution: V1 changes child compiler construction to use `query.clone()`,
making the `set_values()` mutation local to the compilation. This discharges
PO-2 and PO-3.

## F-002: V1 preserves the single-compilation column-alignment rule

Classification: confirmation, no source change required.

Evidence:

- Intent ledger I-005 requires child branches of a compound query to compile
  with the same limited outer column list when the child has no explicit
  selection.
- V1 still executes the same `if not compiler.query.values_select and
  self.query.values_select: compiler.query.set_values(...)` branch.
- The only changed receiver is the cloned child compiler query.

Result: the proof obligation PO-1 remains satisfied. V1 does not drop the
necessary in-compilation alignment of selected columns.

## F-003: The audit found no public API or compatibility break

Classification: confirmation, no source change required.

Evidence:

- The V1 change is internal to `SQLCompiler.get_combinator_sql()`.
- No method signature, queryset API, return type, or caller contract changes.
- `combined_queries`, `combinator`, and `combinator_all` storage are unchanged.

Result: PO-4 is satisfied. No compatibility-driven repair is needed.

## F-004: Proof is constructed but not machine-checked

Classification: proof capability gap / honesty gate.

Evidence:

- The task forbids running K tooling.
- The FVK method requires exact commands and the label "constructed, not
  machine-checked" unless `kprove` actually returns `#Top`.

Result: do not remove tests based on this proof alone. Keep or add tests for
the issue scenario until the emitted K commands and the Django test suite can be
run in an appropriate environment.
