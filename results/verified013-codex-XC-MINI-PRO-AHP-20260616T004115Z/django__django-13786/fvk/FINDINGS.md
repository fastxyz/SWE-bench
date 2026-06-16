# FVK Findings

Status: constructed, not machine-checked.

## F-001: Plain merge preserved omitted alterable options

Classification: code bug found by formalization; fixed by V1.

Evidence: E-001, E-002, E-003, PO-002, PO-003.

Concrete input:

```text
self.options = {
    "ordering": ["name"],
    "verbose_name": "Old name",
    "db_table": "app_model",
}
operation.options = {}
operation.ALTER_OPTION_KEYS contains "ordering" and "verbose_name"
```

Observed before V1:

```text
{"ordering": ["name"], "verbose_name": "Old name", "db_table": "app_model"}
```

Expected:

```text
{"db_table": "app_model"}
```

Reasoning: applying `CreateModel.state_forwards()` and then
`AlterModelOptions.state_forwards()` would remove omitted alterable keys. A
plain merge cannot express key removal, so it is not state-equivalent to the
original operation sequence.

Resolution: V1 builds the merged options map, iterates over
`operation.ALTER_OPTION_KEYS`, and removes keys omitted from
`operation.options`.

## F-002: Empty `operation.options` boundary is discharged

Classification: fixed boundary case.

Evidence: E-002, PO-003.

Concrete input:

```text
self.options = {"ordering": ["name"]}
operation.options = {}
```

Observed with V1 by inspection:

```text
{}
```

Expected:

```text
{}
```

Reasoning: after the merge, `ordering` exists in the local `options` dict. The
loop sees that `ordering` is in `ALTER_OPTION_KEYS` and absent from
`operation.options`, then removes it.

## F-003: Non-alter options are preserved

Classification: frame condition confirmed.

Evidence: E-004, E-005, PO-004.

Concrete input:

```text
self.options = {"db_table": "app_model", "ordering": ["name"]}
operation.options = {}
```

Observed with V1 by inspection:

```text
{"db_table": "app_model"}
```

Expected:

```text
{"db_table": "app_model"}
```

Reasoning: the removal loop only visits `ALTER_OPTION_KEYS`. `db_table` is not
part of that list, so it remains after the merge.

## F-004: Operation-provided values override and survive removal

Classification: override condition confirmed.

Evidence: E-004, PO-005.

Concrete input:

```text
self.options = {"ordering": ["old"], "verbose_name": "Old"}
operation.options = {"ordering": ["new"]}
```

Observed with V1 by inspection:

```text
{"ordering": ["new"]}
```

Expected:

```text
{"ordering": ["new"]}
```

Reasoning: the merge sets `ordering` to the operation value. The removal loop
does not remove `ordering` because the key is present in `operation.options`; it
does remove `verbose_name` because that key is alterable and omitted.

## F-005: No V2 source edit is justified by the proof obligations

Classification: no-change decision.

Evidence: PO-001 through PO-008.

Reasoning: every proof obligation induced by the public issue is already
discharged by the V1 source. The audit found no missing key class, no
over-deletion, no override regression, and no public compatibility change.

Resolution: keep V1 unchanged.

## F-006: Residual verification limits

Classification: proof capability and process limit, not a source bug.

Evidence: PO-009.

The proof is constructed but not machine-checked. The environment also forbids
running Django tests, Python snippets, or K tooling. Test removal is therefore
not recommended, and all tests should be kept.
