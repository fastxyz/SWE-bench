# FVK Notes

The FVK audit confirms V1 without further source edits.

Decision D-001: keep the V1 dependency-generation patch unchanged. Finding
F-001 identifies the actual bug as missing ordering between base
`RemoveField` and subclass `CreateModel`; PO-001 proves V1 emits the missing
dependency, PO-002 proves existing dependency matching understands it, and
PO-003 proves same-app topological sorting places the remove operation first.

Decision D-002: do not add duplicate `RemoveField` generation. Finding F-002
tracks the public hint about multiple subclasses. PO-005 shows V1 only adds
dependencies and leaves `generate_removed_fields()` as the single producer of
the base `RemoveField`.

Decision D-003: do not change `check_dependency()`. PO-002 shows the existing
removed-field branch already matches `(app_label, model_name, field_name,
False)`, and F-001 is closed by supplying that dependency from
`generate_created_models()`.

Decision D-004: keep the dependency tied to fields actually declared by the new
subclass. PO-007 records the frame condition: unrelated removed base fields do
not cause the reported field clash, and constraining them would exceed the
public intent captured by F-001 and F-005.

Decision D-005: no prompt, warning, or public API behavior was added. F-005
classifies warning/prompt behavior as underspecified for this issue, and PO-007
confirms the V1 patch changes no signatures, operation classes, or questioner
behavior.

Decision D-006: no tests, Python, or K tooling were run. F-006 and PO-009 are
the honesty gate for this benchmark; `fvk/PROOF.md` records the proof as
constructed, not machine-checked, and recommends no test deletion.
