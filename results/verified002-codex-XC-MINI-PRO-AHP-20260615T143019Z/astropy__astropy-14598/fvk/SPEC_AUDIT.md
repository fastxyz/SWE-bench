# Spec Audit

Status: adequacy comparison between `INTENT_SPEC.md` and
`FORMAL_SPEC_ENGLISH.md`.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| C1 round-trip value preservation | Intent 1 | Pass | Directly states the issue's expected `Card.fromstring(str(card))` equality. |
| C1/C4 doubled quote preservation | Intent 2 | Pass | Preserving escaped chunks until one final unescape prevents `''` -> `'`. |
| C2 full-field parsing | Intent 3 | Pass | Rejects prefix parses that can drop text after `'' ` at a boundary. |
| C3 continuation marker stripping | Intent 4 | Pass | Models `&` as representation-only and not part of the logical value. |
| C1/C3 logical-card reassembly | Intent 5 | Pass | Physical chunks reassemble before producing the caller-visible value. |
| Frame condition | Intent 6 | Pass | No public API, grouping, comment assembly, or test-file change is specified. |

No formal item is candidate-derived without public intent support. No required
public behavior is marked fail or ambiguous.
