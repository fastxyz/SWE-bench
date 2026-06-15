# Public Evidence Ledger

| ID | Source | Quote | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` title | "Set default FILE_UPLOAD_PERMISSION to 0o644." | Default the existing plural setting to `0o644`. |
| E2 | `benchmark/PROBLEM.md` description | "permissions for a file uploaded to FileSystemStorage might not be consistent depending on whether a MemoryUploadedFile or a TemporaryUploadedFile was used" | Normalize final file permissions across both upload paths. |
| E3 | `benchmark/PROBLEM.md` description | "with the default FILE_UPLOAD_HANDLERS, in turn depends on the uploaded data size" | Audit both default handler paths. |
| E4 | public hint | "Adjust the default." | The source change should be the setting default. |
| E5 | public hint | "set to None to restore previous behaviour" | Preserve explicit `None` behavior and document it. |
| E6 | public hint | "Adjust the references in the settings docs and deployment checklist." | Update docs that describe the default and deployment checklist guidance. |
| E7 | public hint | "There is no such inconsistency with directory permissions." | Do not change directory-permission defaults for this issue. |
| E8 | source implementation | `_save()` reaches `os.chmod(full_path, self.file_permissions_mode)` when mode is not `None`. | A concrete default setting is enough to normalize final modes. |
