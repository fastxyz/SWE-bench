# Baseline Notes

## Root cause

`FILE_UPLOAD_PERMISSIONS` defaulted to `None` in `django/conf/global_settings.py`.
`FileSystemStorage._save()` only applies `os.chmod()` when
`file_permissions_mode` is not `None`, so the default left final uploaded file
permissions to the mechanics of the save path:

- uploads saved from a temporary upload file could keep the temporary file mode,
  commonly `0o600`;
- uploads streamed from memory were created with `os.open(..., 0o666)` and then
  constrained by the process umask.

Because the upload handler path depends on the uploaded file size, the same
project configuration could produce different final file permissions for small
and large uploads.

## Changed files

- `repo/django/conf/global_settings.py`: changed the default
  `FILE_UPLOAD_PERMISSIONS` value from `None` to `0o644`, causing the existing
  `FileSystemStorage._save()` chmod path to normalize permissions for uploaded
  files.
- `repo/docs/ref/settings.txt`: updated the documented default and clarified
  that setting `FILE_UPLOAD_PERMISSIONS = None` restores operating-system
  dependent final uploaded file permissions.
- `repo/docs/howto/deployment/checklist.txt`: replaced the old warning about
  default inconsistent permissions with guidance to customize
  `FILE_UPLOAD_PERMISSIONS` only when `0o644` is unsuitable.
- `repo/docs/releases/3.0.txt`: added a backwards-incompatible change note,
  including how to restore the previous behavior by setting the value to `None`.

## Assumptions and rejected alternatives

- I assumed the setting named in the issue title is the existing plural
  `FILE_UPLOAD_PERMISSIONS` setting; Django has no singular
  `FILE_UPLOAD_PERMISSION` setting in this checkout.
- I did not change `FILE_UPLOAD_DIRECTORY_PERMISSIONS`. The issue discussion
  distinguishes directory permissions from file permissions because the reported
  inconsistency is caused by the two file upload save paths, not by directory
  creation.
- I did not alter `FileSystemStorage._save()`. Its existing behavior already
  applies `os.chmod()` to the final saved file when `FILE_UPLOAD_PERMISSIONS`
  has a concrete value, so changing the default is sufficient and more targeted.
- I did not modify tests, and I did not run tests or project code, in accordance
  with the benchmark constraints.
