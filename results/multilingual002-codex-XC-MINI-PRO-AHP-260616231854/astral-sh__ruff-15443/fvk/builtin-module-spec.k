requires "mini-ruff-calls.k"

module BUILTIN-MODULE-SPEC
  imports MINI-RUFF-CALLS

  // SPEC-PROVENANCE:
  // - from_prompt: "PTH123 and S102 check `builtin` instead of `builtins`" =>
  //   explicit standard-library module lookups use the segment "builtins".
  // - from_prompt: false negative example with `builtins.exec(...)` =>
  //   S102 must emit for `builtins.exec`.
  claim <k> check(S102, qname("builtins", "exec"), INFO:OpenInfo) => .K </k>
        <decision> noEmit => emit </decision>

  // SPEC-PROVENANCE:
  // - from_source: SemanticModel documents builtin bindings as the empty segment =>
  //   unqualified `exec()` remains in scope.
  claim <k> check(S102, qname("", "exec"), INFO:OpenInfo) => .K </k>
        <decision> noEmit => emit </decision>

  // SPEC-PROVENANCE:
  // - from_prompt: false positive example with `builtin.exec(...)` =>
  //   S102 must not emit for a non-standard `builtin` module.
  claim <k> check(S102, qname("builtin", "exec"), INFO:OpenInfo) => .K </k>
        <decision> noEmit => noEmit </decision>

  // SPEC-PROVENANCE:
  // - from_prompt: false negative example with `builtins.open(...)` =>
  //   PTH123 must emit for `builtins.open` when the existing pathlib-compatibility
  //   exclusions do not apply.
  claim <k> check(PTH123, qname("builtins", "open"), openInfo(false, false, false)) => .K </k>
        <decision> noEmit => emit </decision>

  // SPEC-PROVENANCE:
  // - from_source: SemanticModel documents builtin bindings as the empty segment =>
  //   unqualified `open()` remains in scope.
  claim <k> check(PTH123, qname("", "open"), openInfo(false, false, false)) => .K </k>
        <decision> noEmit => emit </decision>

  // SPEC-PROVENANCE:
  // - from_prompt: false positive example with `builtin.open(...)` =>
  //   PTH123 must not emit for a non-standard `builtin` module.
  claim <k> check(PTH123, qname("builtin", "open"), openInfo(false, false, false)) => .K </k>
        <decision> noEmit => noEmit </decision>

  // SPEC-PROVENANCE:
  // - from_source: existing PTH123 compatibility checks exclude unsupported
  //   `Path.open` arguments and file descriptors; V2 must preserve them.
  claim <k> check(PTH123, qname("builtins", "open"), openInfo(true, false, false)) => .K </k>
        <decision> noEmit => noEmit </decision>

  claim <k> check(PTH123, qname("builtins", "open"), openInfo(false, true, false)) => .K </k>
        <decision> noEmit => noEmit </decision>

  claim <k> check(PTH123, qname("builtins", "open"), openInfo(false, false, true)) => .K </k>
        <decision> noEmit => noEmit </decision>
endmodule
