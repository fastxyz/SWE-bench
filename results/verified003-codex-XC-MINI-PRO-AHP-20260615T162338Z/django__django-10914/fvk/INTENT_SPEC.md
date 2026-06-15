# Intent Spec

This file records public intent before accepting the candidate implementation
as correct.

## Required Behavior

1. The Django setting `FILE_UPLOAD_PERMISSIONS` defaults to `0o644`.
2. With default upload handlers and default settings, final uploaded file
   permissions do not vary by whether the file was handled as a
   `MemoryUploadedFile` or a `TemporaryUploadedFile`.
3. The actual file stored in the media location is the subject of the
   permission guarantee, not only the intermediate temporary file.
4. Setting `FILE_UPLOAD_PERMISSIONS = None` remains a supported way to restore
   the previous operating-system dependent behavior.
5. The settings docs, deployment checklist, and Django 3.0 release notes reflect
   the new default and the explicit-`None` restoration path.
6. `FILE_UPLOAD_DIRECTORY_PERMISSIONS` remains unchanged because the issue
   states that directory permissions do not have the same inconsistency.

## Out of Scope

- Changing the `FileSystemStorage` public constructor signature.
- Changing `FILE_UPLOAD_DIRECTORY_PERMISSIONS`.
- Proving OS syscall behavior, lock behavior, file contents, filename collision
  retry, or staticfiles integration end to end.
