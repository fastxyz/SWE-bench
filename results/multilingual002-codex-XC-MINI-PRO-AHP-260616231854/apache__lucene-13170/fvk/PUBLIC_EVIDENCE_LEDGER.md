# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | problem | "`preceding` ... may raise an `ArrayIndexOutOfBoundsException`" | In-domain `preceding` calls must not throw that exception from the search helper. | Encoded by PO-001, PO-002, PO-003 and K claims `PRECEDING_V1_SAFE`, `MOVE_SAFE`. |
| E-002 | problem | "`currentSentence = sentenceStarts.length / 2` ... should be instead ... `(sentenceStarts.length -1) / 2`" | The initial midpoint for `preceding` is the lower middle of the inclusive range. | Implemented in V1; encoded by PO-002 and K claim `PRECEDING_V1_SAFE`. |
| E-003 | problem | "`sentenceStarts.length == 2` ... `currentSentence` equals `1` ... `moveToSentenceAt`" | The length-two path must be explicitly covered. | Covered by finding F-001 and proof step for `N = 2`. |
| E-004 | source | `following` already uses `(sentenceStarts.length - 1) / 2` before calling `moveToSentenceAt`. | The analogous caller uses lower-middle initialization to keep the helper's search frame safe. | Supporting implementation evidence, not the sole spec source. |
| E-005 | source/tests | Public local tests assert existing `preceding` return values for one- and three-sentence cases. | Preserve public API and existing return behavior; only repair the exception-triggering midpoint. | Compatibility audited; no return semantics changed. |
