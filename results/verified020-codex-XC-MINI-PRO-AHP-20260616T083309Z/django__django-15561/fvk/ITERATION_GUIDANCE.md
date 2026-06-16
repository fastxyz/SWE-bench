# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1's behavioral fix stands, but V2 tightens the implementation by renaming the
new ignored-attribute hook from public-looking `non_database_attrs` to private
`_field_should_be_altered_non_database_attrs`.

## Code Guidance

No further source edits are recommended for this issue.

Keep:

* base behavior that does not ignore `choices`;
* SQLite behavior that ignores `choices` for the no-op decision;
* all other schema-affecting deconstruction differences as alteration
  candidates;
* no test modifications in this task.

## Future Verification

When an execution environment is available, run:

```sh
kompile fvk/mini-schema-editor.k --backend haskell
kast --backend haskell fvk/schema-editor-spec.k
kprove fvk/schema-editor-spec.k
```

Then run the Django test suite relevant to schema editor migrations on SQLite.
The proof artifacts alone are constructed, not machine-checked.

## Future Test Suggestions

If test edits become allowed in a separate task, add coverage for:

* SQLite `AlterField` where only `choices` changes: assert no SQL/table remake.
* SQLite `AlterField` where `choices` and `max_length` or another
  database-relevant kwarg changes: assert alteration still occurs.
* A non-SQLite/base decision check showing `choices` is not globally ignored.

## Residual Assumption

The spec assumes Django core SQLite fields do not encode database schema solely
through `choices`. A third-party SQLite field that needs choices-dependent
schema must expose that schema-affecting state through another deconstruction
component or override the schema editor behavior.
