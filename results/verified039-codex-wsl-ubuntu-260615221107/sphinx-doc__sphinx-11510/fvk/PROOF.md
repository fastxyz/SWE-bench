# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test commands were run.

## Formal artifacts

- Semantics fragment: `fvk/mini-sphinx-include.k`
- Claims: `fvk/sphinx-include-spec.k`
- Intent and adequacy files: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
  `PUBLIC_COMPATIBILITY_AUDIT.md`

Machine-check commands to run later:

```sh
kompile fvk/mini-sphinx-include.k --backend haskell
kast --backend haskell fvk/sphinx-include-spec.k
kprove fvk/sphinx-include-spec.k
```

Expected result after the K artifacts are made executable against a full
semantics: `#Top`.

## Proof sketch

### CLAIM-MANAGED-INCLUDE

Start in a state where `Include.run()` receives a non-standard include target
`FILE`, the file map contains `FILE |-> SRC`, and `pathdocs` maps `FILE` to
`DOC`. The Sphinx include path first computes the absolute filename and records
the include dependency, which are frame conditions in the model.

The helper stores the original module-level `docutils.io.FileInput`, optionally
stores the original direct `FileInput` global from `BaseInclude.run`, and
replaces both applicable lookup channels with `SphinxIncludeFileInput`. When
`BaseInclude.run()` reads the include file, the read dispatches to the wrapper.
The wrapper obtains raw `SRC`, forms `[SRC]`, emits `source-read(DOC, [SRC])`,
and returns `arg[0]`, modeled as `sourceRead(DOC, SRC)`.

By transitivity, `BaseInclude.run()` inserts the returned text, so the final
observable inserted source is `sourceRead(DOC, SRC)`. The `finally` block
restores both modeled lookup channels, discharging PO-1, PO-2, and PO-4.

### CLAIM-MANAGED-INCLUDE-FALLBACK-DOC

The same reasoning applies when `pathdocs` has no mapping for `FILE`, except the
helper computes `DOC = CUR`. The event and inserted text therefore use
`sourceRead(CUR, SRC)`.

### CLAIM-STANDARD-INCLUDE-FRAME

For an argument beginning with `<` and ending with `>`, `Include.run()` returns
`super().run()` before `env.relfn2path`, `env.note_included`, or the helper is
entered. The include-side event list and FileInput bindings are unchanged by
Sphinx, discharging PO-5.

### CLAIM-DIRECT-FILEINPUT-COVERAGE

Case split on whether `BaseInclude.run.__globals__['FileInput']` exists and is
the original docutils input class.

- If false, there is no direct-global channel to patch; the module-level
  `docutils.io.FileInput` channel is sufficient.
- If true, V2 also replaces that direct global with `SphinxIncludeFileInput`.
  A direct `FileInput(...)` lookup in `BaseInclude.run()` therefore dispatches
  to the wrapper and returns `sourceRead(DOC, SRC)`.

In both branches, the `finally` block restores the original binding.

### CLAIM-DURATION-FIRST-SOURCE-READ

Case split on `started_at in app.env.temp_data`.

- If absent, `duration.on_source_read()` records `time.monotonic()`.
- If present, the V2 guard leaves it unchanged.

Thus later include-triggered source-read events in the same document read cannot
reset the start time.

## Residual risk

The proof is partial and abstract. It does not prove termination, and it does
not model every docutils include option. Those are preserved by source-level
delegation to `super().run()` and remain integration-test obligations.

## Test guidance

No tests were removed or edited. After machine-checking, unit tests that only
restate CLAIM-MANAGED-INCLUDE for individual replacement strings would be
logically subsumed by the proof, but integration tests for docutils options,
standard includes, and builder output should be kept.
