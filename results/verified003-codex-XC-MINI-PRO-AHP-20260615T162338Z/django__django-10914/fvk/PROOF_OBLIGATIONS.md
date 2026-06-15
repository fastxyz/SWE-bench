# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Default Setting

- Claim: the default upload-permission setting is `mode(420)`, where `420` is
  octal `0o644`.
- Public evidence: E1 and E4.
- Code evidence: `repo/django/conf/global_settings.py` sets
  `FILE_UPLOAD_PERMISSIONS = 0o644`.
- Formal claim: `defaultUploadPermissions => mode(420)`.
- Status: discharged by static inspection and the constructed K claim.

## PO-002: Temporary Upload Path Under Default

- Claim: after a successful save through the temporary-file path under the
  default setting, the final uploaded-file mode is `420` (`0o644`).
- Public evidence: E2 and E3.
- Code evidence: `_save()` calls `file_move_safe(...)`, then reaches
  `os.chmod(full_path, self.file_permissions_mode)` when the mode is not
  `None`.
- Formal claim: `savedMode(temporary, defaultUploadPermissions, TMP, MEM) => 420`.
- Status: discharged by symbolic rewriting in the constructed proof.

## PO-003: Memory Upload Path Under Default

- Claim: after a successful save through the memory-stream path under the
  default setting, the final uploaded-file mode is `420` (`0o644`).
- Public evidence: E2 and E3.
- Code evidence: `_save()` creates and writes the file, then reaches
  `os.chmod(full_path, self.file_permissions_mode)` when the mode is not
  `None`.
- Formal claim: `savedMode(memory, defaultUploadPermissions, TMP, MEM) => 420`.
- Status: discharged by symbolic rewriting in the constructed proof.

## PO-004: Explicit `None` Restores Previous Behavior

- Claim: if `FILE_UPLOAD_PERMISSIONS` is explicitly `None`, final file mode is
  path-dependent: temporary uploads keep `TMP`, memory uploads keep `MEM`.
- Public evidence: E5.
- Code evidence: `_save()` skips `os.chmod()` when `file_permissions_mode is
  None`.
- Formal claims:
  - `savedMode(temporary, none, TMP, MEM) => TMP`
  - `savedMode(memory, none, TMP, MEM) => MEM`
- Status: discharged by symbolic rewriting in the constructed proof and
  documented in settings docs and release notes.

## PO-005: Directory Permission Frame Condition

- Claim: this issue must not change `FILE_UPLOAD_DIRECTORY_PERMISSIONS`.
- Public evidence: E7.
- Code evidence: `repo/django/conf/global_settings.py` still sets
  `FILE_UPLOAD_DIRECTORY_PERMISSIONS = None`.
- Formal handling: frame condition outside the modeled file-mode transition.
- Status: discharged by static inspection.

## PO-006: Documentation and Release Notes

- Claim: public docs must no longer describe `None` as the default and must
  explain explicit `None` in terms of final uploaded-file behavior.
- Public evidence: E6 and the issue's clarification about confusing docs.
- Files checked:
  - `repo/docs/ref/settings.txt`
  - `repo/docs/howto/deployment/checklist.txt`
  - `repo/docs/releases/3.0.txt`
- Status: V2 satisfies this obligation; F-002 records the V2 wording
  improvement.

## PO-007: Public Compatibility

- Claim: no public method signature, virtual dispatch call, or setting name is
  changed; users can still configure `FILE_UPLOAD_PERMISSIONS = None` to restore
  previous OS-dependent behavior.
- Public evidence: E5.
- Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`.
