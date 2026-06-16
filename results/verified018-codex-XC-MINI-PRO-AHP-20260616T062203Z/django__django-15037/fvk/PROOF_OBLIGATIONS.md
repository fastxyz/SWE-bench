# Proof Obligations

Status: constructed, not machine-checked. The K fragments below are an abstract,
property-complete model of the changed decision logic, not a full Python or
Django semantics.

## Abstract State

Symbols:

- `RelColumn`: the referenced database column from `relations[column_name][0]`.
- `RelTable`: the referenced database table from `relations[column_name][1]`.
- `TargetPk`: `get_primary_key_column(RelTable)`.
- `TargetFieldMap`: mapping from target database columns to generated Django
  model field names, produced by `normalize_table_columns()`.
- `ExtraParams`: field keyword arguments accumulated by `inspectdb`.
- `EmitField`: the final generated relation declaration.

Helper functions in the model:

```text
target_field(RelTable, RelColumn) =
    TargetFieldMap[RelColumn] if present
    RelColumn otherwise

relation_extra_params(RelColumn, TargetPk, TargetFieldMap) =
    {} if RelColumn == TargetPk
    {"to_field": target_field(RelTable, RelColumn)} otherwise
```

## O1 - Non-PK Target Preservation

Precondition:

```text
column_name in relations
relations[column_name] == (RelColumn, RelTable)
RelColumn != TargetPk
```

Postcondition:

```text
ExtraParams["to_field"] == target_field(RelTable, RelColumn)
EmitField contains ", to_field=<that value>"
```

Evidence: E1, E2, E3, E4, E5, E6.

V1 code locus: `inspectdb.py` lines 150-153.

Constructed K-style claim:

```k
claim
  <k> relationExtraParams(RelColumn, TargetPk, TargetField)
      => "to_field" |-> TargetField </k>
  requires RelColumn =/=K TargetPk
  [all-path]
```

Expected machine-check result if the abstract semantics is encoded and run:
`#Top`.

## O2 - Primary-Key Target Frame

Precondition:

```text
column_name in relations
relations[column_name] == (RelColumn, RelTable)
RelColumn == TargetPk
```

Postcondition:

```text
"to_field" not in ExtraParams
EmitField keeps Django's default primary-key relation semantics
```

Evidence: E5, E8.

V1 code locus: `inspectdb.py` lines 150-153.

Constructed K-style claim:

```k
claim
  <k> relationExtraParams(TargetPk, TargetPk, TargetField)
      => .Map </k>
  [all-path]
```

Expected machine-check result if the abstract semantics is encoded and run:
`#Top`.

## O3 - Target Field-Name Soundness

Precondition:

```text
table_description is the target table description
relations is the target table relation map or {}
RelColumn is a column in table_description
```

Postcondition:

```text
normalize_table_columns(table_description, relations)[RelColumn]
==
the att_name that the normal inspectdb field-generation loop would assign to
RelColumn when generating the target model
```

Evidence: E6, E7.

V1 code locus: `inspectdb.py` lines 202-217 and the existing
`normalize_col_name()` implementation.

Proof shape: induction over `table_description`.

- Base: the empty description produces an empty mapping and no generated fields.
- Step: for the next row, both `normalize_table_columns()` and the generation
  loop call `normalize_col_name(column_name, used_column_names,
  column_name in relations)` with the same `used_column_names`; both append the
  returned `att_name`; therefore the mappings agree at this row and the
  induction hypothesis applies to the suffix.

Expected machine-check result for an abstract list/map semantics: `#Top`.

## O4 - Relation Output Frame

Precondition:

```text
The audited row is a relation row.
```

Postcondition:

The V1 branch preserves:

- `ForeignKey` vs. `OneToOneField` selection;
- self-relation and forward-reference model spelling;
- `models.DO_NOTHING`;
- existing `primary_key`, `db_column`, `blank`, and `null` parameters;
- non-relation field generation.

Evidence: E8 and source control-flow inspection.

V1 code locus: relation logic around `inspectdb.py` lines 141-157 and field
description assembly around lines 181-197.

Expected machine-check result for the abstract frame model: `#Top`.

## O5 - Public Compatibility

Precondition:

```text
Existing public callers use inspectdb command APIs and backend introspection APIs.
```

Postcondition:

No public function signature, command argument, backend method contract, or test
file changes.

Evidence: E4, E8.

Expected result: pass by source inspection.

## Exact Commands Not Executed

The task forbids K tooling. These are the commands that would be used to check
the abstract K fragments committed under `fvk/`:

```sh
kompile fvk/mini-inspectdb.k --backend haskell
kast --backend haskell fvk/inspectdb-spec.k
kprove fvk/inspectdb-spec.k
```

Expected outcome for O1-O5 in the abstract model: `#Top`. This expectation is
constructed, not machine-checked.
