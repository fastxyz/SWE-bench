# FVK Spec: django__django-10914

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Scope

This FVK pass audits the behavior changed by the issue:

- the default value of `settings.FILE_UPLOAD_PERMISSIONS`;
- the final permission mode applied by `FileSystemStorage._save()` after a
  successful save through either the temporary-file path or the memory-stream
  path;
- the public documentation and release-note obligations attached to that
  default change.

The model intentionally abstracts away directory creation, filename collision
retry, lock acquisition, byte writing, `file_move_safe()` internals, and actual
OS `chmod()` effects. Those operations are outside the reported defect as long
as save succeeds and the final `os.chmod(full_path, mode)` call is reached.

## Public Intent Ledger

| ID | Source | Public evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Set default FILE_UPLOAD_PERMISSION to 0o644." | The existing plural setting `FILE_UPLOAD_PERMISSIONS` must default to `0o644`. | Encoded by `defaultUploadPermissions => mode(420)`. |
| E2 | issue | "permissions for a file uploaded to FileSystemStorage might not be consistent depending on whether a MemoryUploadedFile or a TemporaryUploadedFile was used" | Under default settings, both upload paths must produce the same final uploaded-file mode. | Encoded by temporary and memory default claims. |
| E3 | issue | "with the default FILE_UPLOAD_HANDLERS, in turn depends on the uploaded data size" | The spec must cover both default handler paths, not only one path. | Encoded by separate temporary and memory claims. |
| E4 | public hint | "Adjust the default." | The code change belongs in the setting default, not a new storage algorithm. | Encoded and checked against `global_settings.py`. |
| E5 | public hint | "set to None to restore previous behaviour" | `None` must remain a supported explicit setting that leaves OS/path-dependent behavior. | Encoded by `savedMode(..., none, ...)` claims and documented. |
| E6 | public hint | "Adjust the references in the settings docs and deployment checklist." | Docs must describe `0o644` as the current default and explain explicit `None` behavior accurately. | Checked against docs; V2 tightens the temporary-path wording. |
| E7 | public hint | "There is no such inconsistency with directory permissions... changes should not be needed to FILE_UPLOAD_DIRECTORY_PERMISSIONS." | Directory permission defaults must remain unchanged in this issue. | Frame condition: no source change to `FILE_UPLOAD_DIRECTORY_PERMISSIONS`. |
| E8 | implementation | `_save()` calls `os.chmod(full_path, self.file_permissions_mode)` when `file_permissions_mode is not None`. | Once the setting has a concrete default, the existing finalization step normalizes final uploaded-file permissions. | Used as implementation evidence for the state transition. |

## Human-Readable Contract

Let `initialMode(source, tempMode, memoryMode)` be the final mode a file would
have after the source-specific save step but before Django's configured
permission normalization:

- `source = temporary` gives `tempMode`;
- `source = memory` gives `memoryMode`.

Let `savedMode(source, setting, tempMode, memoryMode)` be the final mode after
the `FileSystemStorage._save()` final permission step:

- if `setting = mode(M)`, then `savedMode(...) = M`, regardless of `source`;
- if `setting = none`, then `savedMode(...) = initialMode(source, tempMode, memoryMode)`.

The intended default setting is `mode(420)`, where decimal `420` is octal
`0o644`.

Therefore, under default settings:

- `savedMode(temporary, defaultUploadPermissions, tempMode, memoryMode) = 420`;
- `savedMode(memory, defaultUploadPermissions, tempMode, memoryMode) = 420`.

Explicitly setting `FILE_UPLOAD_PERMISSIONS = None` restores the previous
path-dependent behavior and is not a default behavior after this fix.

## Formal Artifacts

- `fvk/mini-upload-permissions.k`: minimal K semantics for the permission-mode
  transition.
- `fvk/upload-permissions-spec.k`: reachability claims for the default setting,
  both upload paths, and explicit `None`.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of each K claim.
- `fvk/SPEC_AUDIT.md`: adequacy comparison between the formal claims and this
  public intent spec.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: public API/callsite compatibility audit.
