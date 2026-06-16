requires "mini-python-paths.k"

module LOADDATA-FIXTURE-DIRS-SPEC
  imports MINI-PYTHON-PATHS
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2: Path instances must not bypass duplicate detection.
  // - E5/E6: duplicate FIXTURE_DIRS raises the existing duplicate error.
  // Claim C1: mixed string and path-like duplicate.
  claim
    <k>
      fixtureDirs(
        Entry(StrPath(P:String), Entry(PathObj(P), REST:Entries)),
        APPDIRS:Strs
      )
      => DuplicateError
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: same obligation with the mixed representations reversed.
  // - This avoids depending on candidate list order.
  // Claim C2: mixed path-like and string duplicate.
  claim
    <k>
      fixtureDirs(
        Entry(PathObj(P:String), Entry(StrPath(P), REST:Entries)),
        APPDIRS:Strs
      )
      => DuplicateError
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: default app fixture directory paths are forbidden in FIXTURE_DIRS.
  // - E1/E2: a Path object with the same filesystem string must be detected.
  // Claim C3: path-like entry conflicts with an app default fixture dir.
  claim
    <k>
      fixtureDirs(
        Entry(PathObj(D:String), REST:Entries),
        SCons(D, APPREST:Strs)
      )
      => DefaultFixtureDirError(D)
    </k>
    requires hasDuplicate(SCons(D, fspaths(REST))) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: nonduplicate Path fixture dirs remain valid.
  // - Frame condition: V1 must not reject Path entries merely because they
  //   are path-like.
  // Claim C4: valid path-like entry is accepted after conversion.
  claim
    <k>
      fixtureDirs(
        Entry(PathObj(P:String), REST:Entries),
        APPDIRS:Strs
      )
      => Ok(SCons(P, fspaths(REST)))
    </k>
    requires hasDuplicate(SCons(P, fspaths(REST))) ==Bool false
     andBool hasIntersection(APPDIRS, SCons(P, fspaths(REST))) ==Bool false
    [all-path]
endmodule
