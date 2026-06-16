# FINDINGS

Status: FVK audit findings, constructed without executing tests or tooling.

## F-01: V1 Localizes the Reported False Positive

- Evidence: PO-01, PO-02, PO-03; ledger E-01, E-02, E-03, E-06.
- Input family: `type MyType = Annotated[..., pydantic.Field(min_length=4)]` where the alias has no explicit type parameters.
- V0 observed behavior: after `type MyType = Annotated[`, the state machine could still be in `BeforeTypeParams`; the RHS `[` was then classified as type parameters, causing `definition_state.in_type_params()` to be true at `min_length=4`.
- Expected behavior: the alias assignment `=` proves there is no type-parameter list, so the RHS `[` must not classify later keyword-argument equals signs as type-parameter defaults.
- V1 audit result: the new `TokenKind::Equal` transition for `InTypeAlias(BeforeTypeParams)` discharges the obligation. No additional code change is justified.

## F-02: Deduplicating E252 Diagnostics Is Not the Correct Repair

- Evidence: PO-03, PO-04; ledger E-03, E-05.
- Input family: real annotated parameter or type-parameter default with no whitespace on either side of `=`.
- Observed existing behavior: the rule may emit one diagnostic for the missing space before `=` and one for the missing space after `=`.
- Expected behavior for this issue: prevent the false-positive path for keyword arguments in alias values, while preserving actual annotated-parameter and type-parameter diagnostics.
- V1 audit result: deduplication would alter legitimate diagnostics and is not required once the false-positive classification is removed.

## F-03: Actual Type-Parameter Defaults Are Preserved

- Evidence: PO-04, PO-05; ledger E-05.
- Input family: `type Alias[T=int] = int` or analogous class/function type parameters.
- Expected behavior: a `[` before the definition's parameter list or alias assignment remains the start of type parameters, and defaults inside that bracket remain eligible for E25 diagnostics.
- V1 audit result: the new `=` transition only fires while still `BeforeTypeParams`, so once a real type-parameter `[` has been seen, equals tokens inside type parameters remain classified as type-parameter defaults.

## F-04: Public Compatibility Risk Is Low

- Evidence: PO-07; `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Input family: public API consumers and diagnostic-code mappings.
- Expected behavior: no public signature, rule code, CLI option, or test fixture changes.
- V1 audit result: only a private state-machine transition changed. No compatibility repair is needed.

## F-05: Proof Is Constructed, Not Machine-Checked

- Evidence: FVK command constraints and `PROOF_OBLIGATIONS.md` machine-check commands.
- Input family: all claims in `fvk/definition-state-spec.k`.
- Observed limitation: this benchmark session forbids running `kompile`, `kast`, or `kprove`.
- Expected follow-up outside this session: run the recorded K commands and require `#Top` before treating the proof as machine-checked.
- V1 audit result: this is a verification caveat, not a code bug.
