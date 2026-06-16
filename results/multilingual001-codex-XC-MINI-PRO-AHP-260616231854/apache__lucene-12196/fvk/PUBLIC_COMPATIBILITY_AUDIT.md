# Public Compatibility Audit

Status: pass.

Changed symbol: private helper `MultiFieldQueryParser.applySlop(Query q, int slop)`.

Signature change: none.

Visibility change: none.

Public constructors changed: none.

Protected parser override signatures changed: none.

Callsite shape changed: none. Existing callers still call `applySlop(q, slop)` from within
`MultiFieldQueryParser`.

Subclass or override impact: none found for the changed private helper because it is not visible to
subclasses.

Data shape impact: returned query trees still use Lucene `Query` subclasses. The fix only changes the
inner phrase-like query under an existing `BoostQuery` wrapper so that it carries the requested slop.

Test files modified: none.
