# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## F1 - Missing dependency on scalar-to-FK AlterField

Classification: code bug, resolved by V1.

Input: an existing field such as `testapp1.App1.another_app` changes from
`models.UUIDField(...)` to
`models.ForeignKey("testapp2.App2", null=True, blank=True, ...)`.

Observed before V1: `generate_altered_fields()` emitted an `AlterField` without
dependency metadata, so `_build_migration_list()` had no target-app auto
dependency to resolve. The generated migration could omit `testapp2` and later
raise `ValueError: Related model 'testapp2.App2' cannot be resolved`.

Expected: the generated `AlterField` carries
`_get_dependencies_for_foreign_key(field)` in `_auto_deps`, allowing migration
building to add the target app dependency.

Evidence: SPEC E1-E5. Proof obligations: PO1, PO2, PO3.

Resolution: V1 adds dependency collection and passes it to `add_operation()` for
the `AlterField` path.

## F2 - Broad relation-target handling is justified

Classification: audit decision, no source change required.

Input: an altered field whose new emitted definition is relational, including a
scalar-to-FK transition and relation-to-relation alterations.

Observed in V1: dependency metadata is added whenever the emitted altered field
has `remote_field.model`, not only when the old field was non-relational.

Expected: the dependency requirement follows from the new relational target,
because the generated migration must be ordered after the target model's
migration state is available. Reusing the existing helper also keeps swappable
and through-model behavior aligned with `AddField`.

Evidence: SPEC E3-E6. Proof obligations: PO1, PO2, PO4.

Resolution: V1 stands. Narrowing the condition to only `not old_field.is_relation`
would satisfy the reported example but would leave the same dependency invariant
unapplied to other relational `AlterField` cases.

## F3 - Verification is constructed only

Classification: proof honesty / environment constraint.

Input: the FVK proof artifacts and abstract K claims.

Observed: the benchmark forbids running tests, Python code, `kompile`, or
`kprove`.

Expected: proof artifacts record the commands and the expected outcome without
claiming a machine-checked result.

Evidence: SPEC E7. Proof obligations: PO7.

Resolution: PROOF.md labels the result as constructed, not machine-checked, and
ITERATION_GUIDANCE.md keeps all test-removal recommendations conditional.

## F4 - Test coverage gap remains external to this task

Classification: test gap, not a source bug in V1.

Input: public Django test suite maintenance for migrations autodetection.

Observed: the issue hint says tests should be added for
`generate_altered_fields()`, but the benchmark forbids modifying test files.

Expected: a future test should assert that altering a scalar field to a
`ForeignKey` in another app gives the altering app's migration a dependency on
the referenced app's latest migration.

Evidence: SPEC E7 and public hint in E3-E5. Proof obligations: PO7.

Resolution: no test files were edited. The needed test is recorded in
ITERATION_GUIDANCE.md.
