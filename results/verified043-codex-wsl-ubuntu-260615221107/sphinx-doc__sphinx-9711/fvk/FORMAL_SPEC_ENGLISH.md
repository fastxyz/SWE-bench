# Formal Spec In English

The formal model is a small version-checking fragment, not full Python. It
models the observable behavior relevant to `needs_extensions`: finite
requirement entries, loaded extension versions, missing extensions, the
`unknown version` sentinel, valid version comparison, and fallback comparison
for invalid version strings.

C-001. For any required and loaded strings that are valid version strings,
`_is_version_requirement_satisfied(required, loaded)` returns true exactly when
the parsed loaded version is greater than or equal to the parsed required
version.

C-002. For the concrete witness, required `0.6.0` and loaded `0.10.0` are valid
version strings and the helper returns true.

C-003. If either string is not a valid version string, the helper falls back to
the previous lexicographic comparison `loaded >= required`; this is a
compatibility behavior, not a semantic-version proof.

C-004. `verify_needs_extensions(app, config)` returns immediately when
`config.needs_extensions is None`.

C-005. For each configured requirement whose extension is missing from
`app.extensions`, `verify_needs_extensions` emits a warning and continues to the
remaining requirements.

C-006. For each configured requirement whose extension is loaded with
`unknown version`, `verify_needs_extensions` raises `VersionRequirementError`.

C-007. For each configured requirement whose extension is loaded with a known
valid version older than the required version, `verify_needs_extensions` raises
`VersionRequirementError`.

C-008. For each configured requirement whose extension is loaded with a known
valid version greater than or equal to the required version, that entry does not
raise and checking continues.

C-009. Over a finite `needs_extensions` dictionary, if every loaded known valid
entry satisfies C-008, every missing entry follows C-005, and no entry follows
C-006 or C-007, the function completes without `VersionRequirementError`.

C-010. The fix does not change public signatures or metadata storage shape.
