requires "mini-backend.k"

module BACKEND-RCPARAMS-SPEC
  imports MINI-BACKEND

  // SPEC-PROVENANCE:
  // - from_prompt: "get_backend() clears figures from Gcf.figs if they were
  //   created under rc_context" => get_backend must preserve Gcf.figs after
  //   rc_context restores the auto sentinel while pyplot already has a loaded
  //   backend.
  // - from_prompt: "The figure should not be missing from Gcf" => frame
  //   condition on the Gcf figure-manager collection.
  // - from_code: V1 RcParams.__getitem__ branch repairs global rcParams from
  //   the already loaded pyplot backend instead of calling switch_backend(auto).
  claim
    <k> getBackend => B ... </k>
    <globalRc> true </globalRc>
    <rcBackend> auto => B </rcBackend>
    <pyplotImported> true </pyplotImported>
    <backendLoaded> true </backendLoaded>
    <selectedBackend> B:Backend </selectedBackend>
    <gcfFigs> FS:Figs => FS </gcfFigs>
    requires B =/=K auto
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs/code: matplotlib.get_backend returns rcParams["backend"], and
  //   global rcParams lazily resolves the auto sentinel when no backend has
  //   been selected yet.
  // - from_code: pyplot.switch_backend closes figures during an actual switch.
  // - default-domain-assumption: before pyplot has loaded a backend, no
  //   pyplot-managed FigureManager can exist, so Gcf.figs is empty.
  claim
    <k> getBackend => B ... </k>
    <globalRc> true </globalRc>
    <rcBackend> auto => B </rcBackend>
    <pyplotImported> false </pyplotImported>
    <backendLoaded> false => true </backendLoaded>
    <selectedBackend> _ => B </selectedBackend>
    <autoChoice> B:Backend </autoChoice>
    <gcfFigs> .Figs => .Figs </gcfFigs>
    requires B =/=K auto
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs/code: reading an already concrete backend should return that
  //   backend and has no reason to call switch_backend.
  claim
    <k> getBackend => B ... </k>
    <globalRc> true </globalRc>
    <rcBackend> B:Backend </rcBackend>
    <gcfFigs> FS:Figs => FS </gcfFigs>
    requires B =/=K auto
    [all-path]
endmodule
