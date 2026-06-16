requires "mini-pytest-visit.k"

module PYTEST-VISIT-SPEC
  imports MINI-PYTEST-VISIT
  imports BOOL
  imports LIST
  imports MAP
  imports K-EQUAL

  syntax Bool ::= finiteAcyclic(Map, Path, RecursePolicy) [function]
  syntax List ::= expectedVisit(Map, Path, RecursePolicy) [function]
  syntax Bool ::= symlinkToDir(Map, Entry) [function]
  syntax Bool ::= brokenSymlink(Map, Entry) [function]
  syntax Map ::= singletonChildren(Path, Entry) [function]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: symlinked directories should be followed and collected.
  // - E4: V1 implements default is_dir() followed by recurse(entry).
  // - E5: recursion filters must remain in force.
  // - D1: partial correctness assumes finite acyclic traversal.
  claim [VISIT]:
    <k> visit(P:Path, R:RecursePolicy) => .K ... </k>
    <fs> FS:Map </fs>
    <out> .List => expectedVisit(FS, P, R) </out>
    requires finiteAcyclic(FS, P, R)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: "a symlink to a directory ... should be followed".
  // - E3: follow_symlinks=False should be removed.
  // - E6/E7: recurse through entry.path, preserving symlink spelling.
  claim [VISIT-SYMLINK-DIR]:
    <k> visit(P:Path, R:RecursePolicy) => .K ... </k>
    <fs> singletonChildren(P, E:Entry) </fs>
    <out> .List => ListItem(E) expectedVisit(singletonChildren(P, E), entryPath(E), R) </out>
    requires symlinkToDir(singletonChildren(P, E), E)
     andBool recurseAllows(R, E)
     andBool finiteAcyclic(singletonChildren(P, E), P, R)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: norecursedirs and pytest_ignore_collect must still gate descent.
  claim [VISIT-RECURSE-FILTER]:
    <k> visit(P:Path, R:RecursePolicy) => .K ... </k>
    <fs> singletonChildren(P, E:Entry) </fs>
    <out> .List => ListItem(E) </out>
    requires isDirFollow(singletonChildren(P, E), E)
     andBool notBool recurseAllows(R, E)
     andBool finiteAcyclic(singletonChildren(P, E), P, R)
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: broken symlinks/non-directories are not traversal roots.
  claim [VISIT-BROKEN-SYMLINK]:
    <k> visit(P:Path, R:RecursePolicy) => .K ... </k>
    <fs> singletonChildren(P, E:Entry) </fs>
    <out> .List => ListItem(E) </out>
    requires brokenSymlink(singletonChildren(P, E), E)
     andBool notBool isDirFollow(singletonChildren(P, E), E)
     andBool finiteAcyclic(singletonChildren(P, E), P, R)
    [all-path]
endmodule

