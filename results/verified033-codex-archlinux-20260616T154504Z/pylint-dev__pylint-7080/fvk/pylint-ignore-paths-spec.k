// Constructed FVK claims for pylint recursive ignore-path filtering.
// These claims are intended for later machine checking; they were not run here.

requires "mini-pylint-ignore.k"

module PYLINT-IGNORE-PATHS-SPEC
  imports MINI-PYLINT-IGNORE

  // SPEC-PROVENANCE:
  // - from_prompt: "`--recursive=y` ignores `ignore-paths`" =>
  //   recursively discovered files matching ignore-paths must not be linted.
  // - from_docs: "regex matches against paths and can be in Posix or Windows format" =>
  //   mixed runtime separators must not prevent a configured path pattern from matching.
  claim pathRegexMatch(P, PATHS) => true
    requires regexMatch(normPath(P), PATHS) ==Bool true

  // SPEC-PROVENANCE:
  // - from_docs: ignore still respects raw basename and basename-regex behavior.
  claim ignoredFile(P, IGNORE, IGNORE_RE, IGNORE_PATHS) => true
    requires nameIn(basename(P), IGNORE) ==Bool true

  claim ignoredFile(P, IGNORE, IGNORE_RE, IGNORE_PATHS) => true
    requires regexMatch(basename(P), IGNORE_RE) ==Bool true

  claim ignoredFile(P, IGNORE, IGNORE_RE, IGNORE_PATHS) => true
    requires regexMatch(normPath(P), IGNORE_PATHS) ==Bool true

  // SPEC-PROVENANCE:
  // - from_prompt: matching files under src/gen must not emit lint messages.
  // - from_code: expand_modules creates module descriptions consumed by _check_file.
  claim emitResolved(false, true) => false

  // SPEC-PROVENANCE:
  // - from_findings: V1 skipped a package tree when only resolved __init__.py
  //   was ignored. V2 must preserve traversal and filter submodules independently.
  claim shouldTraverse(true, false, false) => true
endmodule
