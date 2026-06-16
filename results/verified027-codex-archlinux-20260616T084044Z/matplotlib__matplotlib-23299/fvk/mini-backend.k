module MINI-BACKEND-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Backend ::= "auto" | backend(String)
  syntax Figs ::= ".Figs" | fig(Int) Figs
  syntax Command ::= "getBackend" | "switchBackend" "(" Backend ")"
  syntax KResult ::= Backend
endmodule

module MINI-BACKEND
  imports MINI-BACKEND-SYNTAX
  imports BOOL
  imports INT
  imports STRING
  imports K-EQUAL

  configuration
    <k> $PGM:Command </k>
    <globalRc> true </globalRc>
    <rcBackend> auto </rcBackend>
    <pyplotImported> false </pyplotImported>
    <backendLoaded> false </backendLoaded>
    <selectedBackend> backend("") </selectedBackend>
    <autoChoice> backend("agg") </autoChoice>
    <gcfFigs> .Figs </gcfFigs>

  // Reading a concrete backend is observational.
  rule
    <k> getBackend => B ... </k>
    <rcBackend> B:Backend </rcBackend>
    requires B =/=K auto

  // V2 behavior under audit: if pyplot has already loaded a backend, a stale
  // auto sentinel in global rcParams is repaired from that loaded backend. No
  // backend switch is performed, so the Gcf figure set is framed unchanged.
  rule
    <k> getBackend => B ... </k>
    <globalRc> true </globalRc>
    <rcBackend> auto => B </rcBackend>
    <pyplotImported> true </pyplotImported>
    <backendLoaded> true </backendLoaded>
    <selectedBackend> B:Backend </selectedBackend>
    requires B =/=K auto

  // Initial lazy resolution remains available when no backend is loaded.
  rule
    <k> getBackend => switchBackend(auto) ... </k>
    <globalRc> true </globalRc>
    <rcBackend> auto </rcBackend>
    <backendLoaded> false </backendLoaded>

  // Auto selection chooses the environment-compatible backend abstractly.
  rule
    <k> switchBackend(auto) => switchBackend(B) ... </k>
    <autoChoice> B:Backend </autoChoice>
    requires B =/=K auto

  // A real backend switch destroys pyplot-managed figures, matching
  // pyplot.switch_backend's close("all") behavior.
  rule
    <k> switchBackend(B:Backend) => B ... </k>
    <rcBackend> _ => B </rcBackend>
    <backendLoaded> _ => true </backendLoaded>
    <selectedBackend> _ => B </selectedBackend>
    <gcfFigs> _ => .Figs </gcfFigs>
    requires B =/=K auto
endmodule
