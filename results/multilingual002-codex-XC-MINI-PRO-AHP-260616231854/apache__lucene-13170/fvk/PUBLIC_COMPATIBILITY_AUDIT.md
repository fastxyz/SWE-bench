# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`OpenNLPSentenceBreakIterator.preceding(int pos)`

- Signature changed: no.
- Visibility changed: no.
- Return type changed: no.
- Exceptions declared changed: no.
- Field layout changed: no.
- Caller protocol changed: no.

## Callers And Overrides

`OpenNLPSentenceBreakIterator` is `final`, so there are no subclass overrides of
`preceding` in this class. The class extends `BreakIterator` and keeps the same override
signature.

Local source search found the constructor used by `OpenNLPTokenizer`; no caller protocol
changes are required. Public local tests call `preceding` through the `BreakIterator`
interface and require no signature updates.

## Compatibility Finding

No compatibility blocker. V1 changes only an internal midpoint expression before a
private helper call.

