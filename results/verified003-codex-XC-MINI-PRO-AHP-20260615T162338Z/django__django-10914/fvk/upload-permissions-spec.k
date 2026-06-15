requires "mini-upload-permissions.k"

module UPLOAD-PERMISSIONS-SPEC
  imports MINI-UPLOAD-PERMISSIONS
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "Set default FILE_UPLOAD_PERMISSION to 0o644."
  // - from_public_hint: "Adjust the default."
  // - from_code: repo/django/conf/global_settings.py has FILE_UPLOAD_PERMISSIONS = 0o644.
  // - obligation: the default setting is mode(420), decimal for octal 0o644.
  claim
    <k> defaultUploadPermissions => mode(420) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: uploaded file permissions must not depend on TemporaryUploadedFile.
  // - from_code: _save() applies os.chmod(full_path, mode) when file_permissions_mode is non-None.
  // - obligation: the temporary-file path reaches final mode 0o644 under the default.
  claim
    <k> savedMode(temporary, defaultUploadPermissions, TMP:Int, MEM:Int) => 420 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: uploaded file permissions must not depend on MemoryUploadedFile.
  // - from_code: _save() applies os.chmod(full_path, mode) when file_permissions_mode is non-None.
  // - obligation: the memory path reaches final mode 0o644 under the default.
  claim
    <k> savedMode(memory, defaultUploadPermissions, TMP:Int, MEM:Int) => 420 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: setting FILE_UPLOAD_PERMISSIONS to None restores previous behavior.
  // - from_code: _save() skips os.chmod() when file_permissions_mode is None.
  // - obligation: explicit None leaves temporary-path mode path-dependent.
  claim
    <k> savedMode(temporary, none, TMP:Int, MEM:Int) => TMP </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: setting FILE_UPLOAD_PERMISSIONS to None restores previous behavior.
  // - from_code: _save() skips os.chmod() when file_permissions_mode is None.
  // - obligation: explicit None leaves memory-path mode path-dependent.
  claim
    <k> savedMode(memory, none, TMP:Int, MEM:Int) => MEM </k>
    [all-path]
endmodule
