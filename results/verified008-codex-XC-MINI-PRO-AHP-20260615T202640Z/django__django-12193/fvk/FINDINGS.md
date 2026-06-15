# FINDINGS

Status: FVK audit findings; proof constructed, not machine-checked.

## F1 - Fixed Code Bug: Generated `checked` Leaked Across SplitArrayWidget Children

Evidence: E1, E2, E3, PO2, PO3, PO7.

Input shape: `SplitArrayWidget(CheckboxInput, size=3)` with no explicit `checked` attr and values `[False, True, False]`.

Pre-V1 observed behavior by source reasoning: first false renders unchecked, true renders checked and mutates shared `final_attrs`, final false receives the mutated attrs and renders checked. Observable checked flags: `[False, True, True]`.

Expected behavior: `[False, True, False]`.

V1 result by source reasoning: `CheckboxInput.get_context()` copies `attrs` before adding generated `checked`, so `final_attrs` remains unchanged for later split-array iterations. Observable checked flags: `[False, True, False]`.

Classification: code bug fixed by V1.

## F2 - Confirmed: Explicit Caller `checked` Attr Remains Preserved

Evidence: PO1, PO2, PO4.

Input shape: caller explicitly supplies attrs containing `checked`, and a checkbox value is false.

Expected behavior: the returned context can still be checked because the caller explicitly requested it. The no-leak rule blocks generated cross-iteration mutation; it does not erase explicit attrs.

V1 result by source reasoning: false values do not enter the copy-and-generate branch, and `Widget.get_context()` still merges original attrs into returned context. True values copy original attrs and preserve all keys while adding/generated overriding `checked` on the copy.

Classification: desired compatibility behavior confirmed.

## F3 - Rejected Alternative: Copying Per Iteration in SplitArrayWidget Is Not Required for This Issue

Evidence: E3, E5, E6, PO2, PO3.

Alternative considered: change `SplitArrayWidget.get_context()` to pass a fresh copy of `final_attrs` to every child widget.

Reason rejected: it would mask this issue for split arrays, but the public issue identifies `CheckboxInput.get_context()` mutating caller attrs as the root cause and notes it as the only widget with this behavior. Fixing the mutation at `CheckboxInput` discharges the split-array obligation and restores the general widget contract without changing split-array behavior for other child widgets.

Classification: no source change recommended.

## F4 - Residual Risk: Constructed Proof Is Not Machine-Checked

Evidence: FVK honesty gate, PO8.

The K semantics and claims were written but not run through `kompile` or `kprove`, per task constraints. The formal model abstracts Python dictionaries to the presence of the `checked` key plus source-level frame reasoning for all other keys.

Classification: proof capability/verification-process caveat, not an identified code bug.

## Open Code Findings

None. The FVK audit did not surface a source problem requiring changes beyond V1.
