# FVK Notes

## Source Changes After V1

`repo/pylint/lint/pylinter.py`

- Changed `_discover_files()` package handling based on Finding F2 and Proof
  Obligation O5. V1 kept the old `skip_subtrees` prefix list, which could skip a
  sibling package such as `pkg2` after discovering `pkg`. V2 now clears
  `directories[:]` when a package root is yielded, preventing descent into that
  package without comparing future roots by string prefix.

## V1 Decisions Confirmed

- Kept `_is_ignored_file()` because Findings F1 and F4 plus Obligations O1-O4
  support applying configured ignores before recursive discovery yields paths.
- Kept directory pruning instead of final-output filtering because F1/O3 require
  descendants of ignored directories to be unreachable from the recursive walk.
- Kept raw-path plus normalized-path matching for `ignore-paths` because F4/O1
  cover paths discovered as `./.a` while public intent expects `--ignore-paths=.a`
  to ignore `.a/foo.py`.
- Kept `_discover_files()` as a static helper with an optional predicate because
  O7 and the compatibility audit in `fvk/SPEC.md` show this preserves the
  previous one-argument private call behavior.

## Decisions Not to Change

- Did not change the default `ignore-patterns` value. Finding F3 and Adequacy
  Obligation A1 identify contradictory public evidence: the issue prose says the
  default is `"^\."`, while the quoted help text and repository source show
  `^\.#`.
- Did not alter `expand_modules()`. `fvk/SPEC.md` scopes this pass to recursive
  pre-expansion discovery, and `fvk/ITERATION_GUIDANCE.md` records non-recursive
  path-ignore normalization as outside this proof's compatibility audit.
- Did not modify tests or run test/code/formal commands, as required by the
  benchmark instructions. `fvk/PROOF.md` records the `kompile`, `kast`, and
  `kprove` commands for later machine-checking.

## Artifact Trace

- `fvk/SPEC.md` contains the intent ledger, formal-spec English, adequacy audit,
  and public compatibility audit.
- `fvk/FINDINGS.md` records the confirmed V1 behavior, the V2 package-prefix
  issue, the default-pattern ambiguity, and proof-derived residual risks.
- `fvk/PROOF_OBLIGATIONS.md` enumerates O1-O7 plus adequacy obligations A1-A3.
- `fvk/PROOF.md` gives the constructed proof and exact commands, labeled
  constructed and not machine-checked.
- `fvk/ITERATION_GUIDANCE.md` explains the applied V2 change, retained V1
  decisions, rejected/deferred changes, and suggested future tests.
- `fvk/mini-pylint-discovery.k` and
  `fvk/pylinter-recursive-discovery-spec.k` provide the constructed K core used
  by the proof narrative.
