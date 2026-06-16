# Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: V1 Satisfies the Public Failure Mechanism

- Classification: confirmation, no source change required.
- Evidence: PO-1 and PO-2.
- Input: pandas-mode auto wrapping of `DataFrame(output_rows=4,
  index=daily_index)` with `original_input.index` length 96.
- V0 observed: `_wrap_in_pandas_container` assigned the 96-row input index to
  the 4-row output `DataFrame`, producing pandas' length mismatch error.
- V1 expected/observed by static reasoning: existing `DataFrame` branch updates
  columns if available and returns without assigning `index`, so the output
  keeps `daily_index` and avoids this error source.
- Recommendation: keep V1 source unchanged for this obligation.

## F2: Legacy Helper Test Is Suspect Evidence

- Classification: suspect legacy test, not a code bug in V1.
- Evidence: E7 and PO-7.
- Input: existing `DataFrame` plus a different `index` argument.
- Legacy expected: helper overwrites the DataFrame's index.
- Public-intent expected: helper preserves an existing DataFrame index because
  the issue identifies index restoration as too restrictive.
- Recommendation: do not modify tests in this task. Maintainers should update
  that test to assert column update plus index preservation.

## F3: Direct Series Wrapping Is Ambiguous and Outside This Fix

- Classification: underspecified intent / possible future test gap.
- Evidence: `INTENT_SPEC.md` domain assumption and `SPEC_AUDIT.md`.
- Input: a transformer directly returns a pandas `Series` and is itself
  auto-wrapped by `_SetOutputMixin`.
- Current source behavior by inspection: `Series` is not a `DataFrame`, so it
  takes the pandas-constructor path with the supplied index.
- Public-intent status: the helper docstring specifies `{ndarray, dataframe}`;
  the reported FeatureUnion path concatenates Series-like child outputs into a
  `DataFrame` before the final wrapper runs.
- Recommendation: no source change for this issue. If direct Series output is
  declared in scope later, add a separate explicit branch and tests.

## F4: Proof Capability Boundary

- Classification: proof capability gap, not a code bug.
- Evidence: PO-7 and `PROOF.md`.
- Input: real pandas internals, callable side effects, and pandas constructor
  alignment semantics.
- FVK model: abstracts these to object kind, index identity/length, column
  resolution result, and sparse-vs-dense status.
- Recommendation: run the emitted `kompile`/`kprove` commands in an environment
  with K to machine-check the abstract proof; keep integration tests for real
  pandas behavior.
