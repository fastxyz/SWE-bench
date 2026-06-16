# FVK Specification for astral-sh__ruff-15543

Status: constructed, not machine-checked. This is a focused FVK model of the UP028 replacement-text construction relevant to the reported bug, not a proof of the entire Ruff linter.

## Intent spec

1. For a UP028-applicable loop, Ruff should produce a `yield from` replacement instead of a `for` loop containing only `yield` of the loop target.
2. If the iterable expression is an unparenthesized tuple, the replacement must preserve the tuple expression by placing it in a valid `yield from` operand context.
3. The concrete reported input `for e in x,: yield e` must not produce invalid `yield from x,`; the required replacement operand form is `(x,)`.
4. Iterable source that is already safe in `yield from` operand context should continue through the existing source-preserving path.

## Public evidence ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "UP028 fix fails on unparenthesized tuple" | The defect class is bare tuple iterable syntax. | Encoded in O1, O2. |
| E2 | prompt | `for e in x,:` followed by a syntax-error rollback | Bare tuple source `x,` must not appear bare after `yield from`. | Encoded in O1. |
| E3 | prompt | Rule help: "Replace with `yield from`" | UP028 should still fix the loop when a correct replacement exists. | Encoded in O1, O2. |
| E4 | source | `ExprTuple` records `parenthesized: bool`; V1 matches `parenthesized: false` | Implementation can distinguish bare tuple iterables from already parenthesized tuple/non-tuple iterables. | Used as model input classification, not intent. |
| E5 | source | V1 leaves the original `locator().slice(...)` path intact | Non-bare iterable source preservation remains a frame condition. | Encoded in O3. |

## Formal model

The machine-oriented artifacts are:

- `fvk/mini-up028-fix.k`: a minimal K fragment with the observable `fix(iter(kind, source))`.
- `fvk/up028-fix-spec.k`: K reachability claims for the singleton reported case, the general bare tuple family, and the preserved path.

The abstraction is property-complete for the issue because it keeps the manipulated observable: the emitted replacement string. A passing instance (`bareTuple, "x," -> "yield from (x,)"`) and the pre-fix failing instance (`bareTuple, "x," -> "yield from x,"`) map to different strings.

## Formal spec in English

O1. `fix(iter(bareTuple, "x,"))` reaches exactly `yield from (x,)`.

O2. For any source slice `S` classified as an unparenthesized tuple iterable, `fix(iter(bareTuple, S))` reaches exactly `yield from (` + `S` + `)`.

O3. For any source slice `S` classified as preserved, meaning not an unparenthesized tuple iterable in this focused model, `fix(iter(preserved, S))` reaches exactly `yield from ` + `S`.

## Adequacy audit

| Obligation | Public-intent match | Verdict |
| --- | --- | --- |
| O1 | Directly matches the reported singleton tuple case. | Pass |
| O2 | Generalizes the named defect class "unparenthesized tuple"; wrapping preserves Python tuple expression syntax in `yield from`. | Pass |
| O3 | The prompt only identifies bare tuple iterables as defective; preserving all other existing behavior is the narrow frame condition. | Pass |

## Compatibility audit

The V1 source change is internal to `yield_in_for_loop`; it does not change public Rust APIs, rule codes, settings, signatures, diagnostics, or fix safety classification. No public caller, subclass, or virtual dispatch compatibility issue is introduced.

## Scope boundary

This FVK pass does not prove parser correctness, `parenthesized_range` internals, or the full semantic safety of UP028, which remains marked unsafe by the project. It proves the replacement-text shape required by the issue under the existing UP028 applicability checks and the AST classification available in source.
