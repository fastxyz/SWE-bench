# Formal Spec In English

Status: paraphrase of the constructed K-style claims and proof obligations.

## Claim C1: Round-Trip Value Preservation

For every in-domain string `V` and comment `C`, the abstract command
`roundTrip(V, C)` rewrites to `observedValue(V)`.

Plain English: formatting a long FITS card by escaping quotes and chunking the
escaped text, then parsing it back through the long-card split path and final
string parser, returns the same logical value the original `Card.value` exposes.

## Claim C2: Prefix-Ambiguous Fields Are Rejected

For every escaped text `E`, `fullMatchValueComment(prefixAmbiguousField(E))`
rewrites to `false`.

Plain English: a field whose only successful parse would consume a prefix while
leaving continuation suffix text behind is not accepted by the long-card string
parser.

## Claim C3: Escaped Chunks Reassemble Before Unescape

The simplification `collectEscaped(chunks(E)) => E` states that valid physical
chunks preserve order and reassemble to the escaped source text.

Plain English: splitting long escaped text into physical cards and then joining
the raw payloads recovers the original escaped text.

## Claim C4: Final Unescape Is Single And Last

The simplification `unescape(escape(V)) => observedValue(V)` states that final
parsing decodes FITS quote escaping exactly once.

Plain English: doubled quote escaping is inverted only after all continued
payload chunks have been joined.

## Frame Condition

The proof does not change public signatures, header `CONTINUE` grouping,
formatting, test files, or existing comment assembly.
