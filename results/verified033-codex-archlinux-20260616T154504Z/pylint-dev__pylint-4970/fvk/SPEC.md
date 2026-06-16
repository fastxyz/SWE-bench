# FVK Spec

This audit targets the duplicate-code disable path introduced for
`min-similarity-lines=0` in `repo/pylint/checkers/similar.py`.

Constructed, not machine-checked.

## Intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the full ledger. The critical entries
are:

- E1: `min-similarity-lines=0` should stop duplicate-code checking.
- E3: the buggy behavior is duplicate-code messages being raised with `0`.
- E4: the desired behavior is disabling the check, not lowering the threshold.
- E7: the checker documentation identifies similarity work as memory / CPU
  intensive, supporting a no-collection disabled path.

## Contracts

### C1: disabled computation

For any `Similar` instance and any collected `linesets`, if `min_lines <= 0`,
`_compute_sims()` returns `[]`.

This is the shared behavioral backstop for direct `Similar` use, standalone
`symilar`, serial pylint, and the reduce side of parallel pylint.

### C2: disabled pylint module processing

For any `SimilarChecker` instance, if `min_lines <= 0`, `process_module(node)`
returns before opening `node.stream()` and before calling `append_stream()`.
`self.linesets` is unchanged.

### C3: no duplicate-code messages

For any `SimilarChecker.close()` execution where `_compute_sims()` returns `[]`,
the loop over similarities has zero iterations. Therefore `add_message("R0801",
...)` is not called, `nb_duplicated_lines` is set to `0`, and
`percent_duplicated_lines` is set to `0`.

### C4: positive-threshold preservation

For `min_lines > 0`, the new guards are false. The previous module collection
and similarity computation bodies execute unchanged.

### C5: parallel preservation

`reduce_map_data()` copies `self.min_lines` into the recombined checker before
calling `close()`. Therefore C1 and C3 apply in the parallel reduction path.

## Domain and side conditions

- The public issue requires `0`; the implementation covers `<= 0`.
- Positive thresholds remain in domain and preserve existing behavior.
- Negative thresholds are treated as disabled by default-domain assumption. A
  stricter future design could reject negatives, but that is outside this issue.

## Formal core

The abstract K files are:

- `fvk/mini-python-similar.k`
- `fvk/similar-spec.k`

They model only the property-carrying state needed here: `min_lines`,
`linesets`, similarity results, emitted duplicate messages, and duplicate
statistics. They do not attempt to model full Python or Pylint.
