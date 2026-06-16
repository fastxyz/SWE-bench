# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`repo/sphinx/extension.py`

- `_is_version_requirement_satisfied(required: str, loaded: str) -> bool`
  - New private helper. No public callsites exist before V1.
  - Compatibility status: safe.

- `verify_needs_extensions(app: "Sphinx", config: Config) -> None`
  - Public-ish module function connected to the `config-inited` event.
  - Signature unchanged.
  - Return shape unchanged: returns `None` on success, raises
    `VersionRequirementError` on unmet loaded requirements, warns for missing
    extensions.
  - Compatibility status: safe.

## Dependency compatibility

`packaging.version.InvalidVersion` and `packaging.version.Version` are imported
from `packaging`, which is already listed in `repo/setup.py` `install_requires`
and is already used elsewhere in Sphinx.

## Storage and producer/consumer compatibility

`Extension.version` remains populated from extension `setup()` metadata key
`version`, with default `unknown version`. V1 does not change the `Extension`
constructor signature, metadata dictionary shape, registry loading path, or
extension setup protocol.

## Overrides and virtual dispatch

No virtual method signature or dispatch call was changed.
