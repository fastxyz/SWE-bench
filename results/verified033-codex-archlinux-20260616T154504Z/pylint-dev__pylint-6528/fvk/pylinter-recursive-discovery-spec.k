requires "mini-pylint-discovery.k"

module PYLINTER-RECURSIVE-DISCOVERY-SPEC
  imports MINI-PYLINT-DISCOVERY

  // SPEC-PROVENANCE:
  // - E1/E2: recursive mode must respect ignore settings.
  // - O2: ignored starting argument is not yielded.
  claim <k> discover(dir(".a", false, file(".a/foo.py", true) ; .FsList) ; .FsList,
                     ignoreName(".a"))
        => .PathList </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: ignored path directories prune descendants.
  // - O3/F4: raw "./.a" and normalized ".a" path spellings are equivalent for matching.
  claim <k> discover(dir("./.a", false, file("./.a/foo.py", true) ; .FsList) ; .FsList,
                     ignorePath(".a"))
        => .PathList </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E4: ignore-patterns match basenames, including files.
  // - O4: ignored Python files are not yielded.
  claim <k> discover(file(".#lock.py", true) ; file("bar.py", true) ; .FsList,
                     ignoreName(".#lock.py"))
        => cons("bar.py", .PathList) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: recursive discovery still yields unignored Python files.
  // - O4 complement: unignored .py files remain observable.
  claim <k> discover(file("bar.py", true) ; .FsList, noIgnore)
        => cons("bar.py", .PathList) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6/F2/O5: package roots are yielded once and sibling package names sharing
  //   a string prefix are not suppressed.
  claim <k> discover(
             dir("pkg", true, file("pkg/a.py", true) ; .FsList) ;
             dir("pkg2", true, file("pkg2/b.py", true) ; .FsList) ;
             .FsList,
             noIgnore)
        => cons("pkg", cons("pkg2", .PathList)) </k>
    [all-path]
endmodule
