// Constructed, not machine-checked.
requires "mini-python-path.k"

module UNIQUE-PATH-SPEC
  imports MINI-PYTHON-PATH
  imports BOOL
  imports MAP
  imports STRING

  // External filesystem/pathlib obligations for existing paths. These are the
  // boundary a real Python/Windows filesystem semantics would discharge.
  rule casePreserved(resolveCanon(S, FS), FS) => true
    requires existsPath(S, FS) ==Bool true
    [simplification]

  rule sameFile(resolveCanon(S, FS), S, FS) => true
    requires existsPath(S, FS) ==Bool true
    [simplification]

  rule sameCanonical(resolveCanon(S1, FS), resolveCanon(S2, FS), FS) => true
    requires existsPath(S1, FS) ==Bool true
     andBool existsPath(S2, FS) ==Bool true
     andBool sameFile(S1, S2, FS) ==Bool true
    [simplification]

  // SPEC-PROVENANCE:
  // - E1/E3/E7: avoid os.normcase and preserve filesystem casing.
  // - E9: preserve the caller's path object type.
  claim
    <k> uniquePath(path(T, S))
      => path(T, resolveCanon(S, FS)) ... </k>
    <fs> FS </fs>
    requires existsPath(S, FS) ==Bool true
    ensures casePreserved(resolveCanon(S, FS), FS) ==Bool true
     andBool sameFile(resolveCanon(S, FS), S, FS) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - E6/E8: symlink and case aliases of the same conftest must share a cache key.
  claim
    <k> uniquePath(path(T, S1))
      => path(T, resolveCanon(S1, FS)) ... </k>
    <fs> FS </fs>
    requires existsPath(S1, FS) ==Bool true
     andBool existsPath(S2, FS) ==Bool true
     andBool sameFile(S1, S2, FS) ==Bool true
    ensures sameCanonical(resolveCanon(S1, FS), resolveCanon(S2, FS), FS) ==Bool true
    [all-path]
endmodule
