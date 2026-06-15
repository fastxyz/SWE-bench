# Public Compatibility Audit

Status: static compatibility audit; no code or tests executed.

## Changed Public Setting Value

- Symbol: `settings.FILE_UPLOAD_PERMISSIONS`
- Change: default value changes from `None` to `0o644`.
- Compatibility status: intentionally backwards-incompatible per public hint and
  documented in `repo/docs/releases/3.0.txt`.
- Restoration path: projects can set `FILE_UPLOAD_PERMISSIONS = None` to restore
  previous OS-dependent behavior.

## Setting Name and API Shape

- Setting name remains `FILE_UPLOAD_PERMISSIONS`.
- No singular `FILE_UPLOAD_PERMISSION` setting exists in the checkout; the
  issue title is interpreted as referring to the existing plural setting.
- No public method or constructor signature changed.

## `FileSystemStorage` Constructor

- Signature remains `FileSystemStorage(location=None, base_url=None,
  file_permissions_mode=None, directory_permissions_mode=None)`.
- Existing concrete overrides such as `file_permissions_mode=0o640` continue to
  bypass the global setting.
- Passing `file_permissions_mode=None` continues to mean "use the setting",
  which is pre-existing behavior. Restoring the old default behavior is done via
  `FILE_UPLOAD_PERMISSIONS = None`, as documented.

## Directory Permissions

- `FILE_UPLOAD_DIRECTORY_PERMISSIONS` remains `None`.
- No directory permission API or behavior is changed.

## Staticfiles Consumer

- `StaticFilesStorage` inherits the default file permission mode through
  `FileSystemStorage`.
- This is a public behavior consequence of changing
  `FILE_UPLOAD_PERMISSIONS`, and docs already say static files receive
  permissions from that setting.
- The release note documents the default setting change.

## Compatibility Result

No unhandled public callsite, override, dispatch shape, or signature change was
found. The behavior change is limited to the accepted default-setting change and
its documented consumers.
