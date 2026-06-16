// Constructed, not machine-checked.

requires "mini-python-contour-set.k"

module CONTOUR-SET-SET-PATHS-SPEC
  imports MINI-CONTOUR-SET
  imports MAP

  // SPEC-PROVENANCE:
  // - E1/E2/E3: public issue proposes cs.set_paths(transformed_paths) as the
  //   replacement for mutating cs.get_paths()[:] = transformed_paths.
  // - E4: public hint suggests copying PathCollection.set_paths, which assigns
  //   _paths and marks the artist stale.
  // - E6: contour.py already invalidates _old_style_split_collections before
  //   another path mutation; this cache is derived from _paths.
  claim
    <k> set_paths(NEW:PathSeq) => .K ... </k>
    <paths> OLD:PathSeq => NEW </paths>
    <stale> OLDSTALE:Bool => true </stale>
    <cache> OLDCACHE:CacheState => cacheAbsent </cache>
    <other> OTHER:Map </other>
    [all-path]
endmodule

