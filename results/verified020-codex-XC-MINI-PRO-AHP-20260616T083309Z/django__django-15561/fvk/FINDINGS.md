# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: SQLite choices-only changes reached the table-remake path

Classification: fixed code bug.

Evidence: `benchmark/PROBLEM.md` says adding or changing `choices` on SQLite
generated a new table, insert, drop, and rename, even though the same migration
should generate no SQL.

Input -> observed vs expected:

* Input: old and new fields have the same quoted column, path, args, and
  database-relevant kwargs, but different `choices`.
* Pre-fix observed behavior: `_field_should_be_altered()` compared `choices`,
  returned true, and SQLite `alter_field()` proceeded toward table remaking.
* Expected behavior: SQLite classifies the field as not altered and returns
  before generating schema SQL.

Resolution: V2 extends only SQLite's ignored attributes with `choices` through
`_field_should_be_altered_non_database_attrs`.

Proof obligations: PO3, PO5.

## F2: V1 introduced a public-looking base hook name

Classification: compatibility smell fixed in V2.

Evidence: V1 moved the local ignored-attribute list to
`BaseDatabaseSchemaEditor.non_database_attrs`. The FVK compatibility audit treats
changed subclass-visible symbols as obligations.

Input -> observed vs expected:

* Input: a third-party schema editor subclass also defines or introspects a
  `non_database_attrs` attribute for another purpose.
* V1 risk: the base private alteration decision would start consulting that
  public-looking attribute.
* Expected behavior: keep the new extension point as narrow and private as the
  private method it supports.

Resolution: V2 renames the hook to
`_field_should_be_altered_non_database_attrs`, preserving V1 behavior while
reducing public API ambiguity.

Proof obligations: PO8.

## F3: Global `choices` ignoring would violate public compatibility intent

Classification: rejected alternative.

Evidence: the issue discussion in `benchmark/PROBLEM.md` says globally adding
`choices` to ignored attributes could regress third-party enum fields.

Input -> observed vs expected:

* Input: a non-SQLite custom field whose database type or constraint semantics
  depend on `choices`.
* Bad alternative behavior: base `_field_should_be_altered()` ignores a
  choices-only change and may skip a real database alteration.
* Expected behavior: base behavior still treats choices-only changes as
  alteration candidates.

Resolution: V2 leaves the base ignored set without `choices`; only SQLite
extends it.

Proof obligations: PO2, PO4.

## F4: Residual SQLite custom-field assumption

Classification: documented assumption, not a code change.

Evidence: the public issue specifically targets SQLite's unnecessary table
remake for choices metadata and states that overriding only SQLite is safe.

Input -> observed vs expected:

* Input: a third-party SQLite field uses only `choices` to represent a database
  schema change without changing any other deconstruction kwarg, path, args,
  column, or database-relevant attribute.
* V2 behavior: the change is classified as no-op on SQLite.
* Expected within this spec: such fields are outside the core Django SQLite
  metadata-only `choices` contract; they would need to expose schema-affecting
  state through another deconstruction component.

Resolution: no additional code change. The assumption is recorded in `SPEC.md`
and `ITERATION_GUIDANCE.md`.

Proof obligations: PO1, PO5, PO7.

## F5: Proof and test results are not machine-checked

Classification: verification/tooling limitation.

Evidence: task instructions forbid running tests, Python, or K tooling.

Input -> observed vs expected:

* Input: the constructed K commands in `PROOF.md`.
* Observed in this session: commands were not executed.
* Expected before deleting tests or claiming machine verification: run the
  emitted `kompile`, `kast`, and `kprove` commands and obtain `#Top`.

Resolution: keep all tests. No test files were modified.

Proof obligations: PO9.
