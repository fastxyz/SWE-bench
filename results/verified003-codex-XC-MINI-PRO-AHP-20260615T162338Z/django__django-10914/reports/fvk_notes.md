# FVK Notes

## Summary

The FVK audit confirms the V1 code behavior: changing
`FILE_UPLOAD_PERMISSIONS` to `0o644` is the targeted fix, and the storage layer
already applies a concrete mode to the final saved file on both upload paths.
The only V2 source edit is a documentation wording improvement in
`repo/docs/ref/settings.txt`.

## Decisions

### Keep `FILE_UPLOAD_PERMISSIONS = 0o644`

- Traced findings: `fvk/FINDINGS.md` F-001.
- Traced proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO-001, PO-002, PO-003.
- Reasoning: the public issue requires the default to avoid path-dependent file
  modes. The constructed claims show that both
  `savedMode(temporary, defaultUploadPermissions, TMP, MEM)` and
  `savedMode(memory, defaultUploadPermissions, TMP, MEM)` reach decimal `420`
  (`0o644`).

### Do not change `FileSystemStorage._save()`

- Traced findings: F-001 proof-derived finding section.
- Traced proof obligations: PO-002, PO-003.
- Reasoning: `_save()` already calls `os.chmod(full_path,
  self.file_permissions_mode)` when the mode is not `None`. The bug was that
  the default mode was `None`, not that the finalization rule was missing.

### Improve settings-doc wording

- Traced findings: F-002.
- Traced proof obligations: PO-006.
- Change made: `repo/docs/ref/settings.txt` now says that when
  `FILE_UPLOAD_PERMISSIONS = None`, "files uploaded through a temporary file"
  are saved with the path-dependent mode. This directly addresses the issue's
  concern that docs must describe the final uploaded file, not just an
  intermediate temporary file.

### Keep `FILE_UPLOAD_DIRECTORY_PERMISSIONS = None`

- Traced findings: F-003.
- Traced proof obligations: PO-005.
- Reasoning: the public discussion explicitly says directory permissions do not
  have the reported memory-vs-temporary upload inconsistency, so changing this
  setting would exceed the accepted issue scope.

### Preserve explicit `None`

- Traced findings: F-001, F-004.
- Traced proof obligations: PO-004, PO-007.
- Reasoning: public intent says projects can set `FILE_UPLOAD_PERMISSIONS =
  None` to restore previous behavior. The constructed `TEMP-NONE` and
  `MEMORY-NONE` claims model that path-dependent behavior and the release note
  documents it.

### Do not modify tests or claim machine-checked proof

- Traced findings: F-004.
- Traced proof obligations: all proof obligations are marked constructed, not
  machine-checked.
- Reasoning: this benchmark forbids running tests, Python, or K tooling and
  forbids editing tests. The FVK artifacts include the exact commands to run in
  a suitable environment, but no test removal is recommended here.

## Artifacts Produced

- Required task artifacts:
  - `fvk/SPEC.md`
  - `fvk/FINDINGS.md`
  - `fvk/PROOF_OBLIGATIONS.md`
  - `fvk/PROOF.md`
  - `fvk/ITERATION_GUIDANCE.md`
- Additional FVK contract artifacts:
  - `fvk/mini-upload-permissions.k`
  - `fvk/upload-permissions-spec.k`
  - `fvk/INTENT_SPEC.md`
  - `fvk/PUBLIC_EVIDENCE_LEDGER.md`
  - `fvk/FORMAL_SPEC_ENGLISH.md`
  - `fvk/SPEC_AUDIT.md`
  - `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
