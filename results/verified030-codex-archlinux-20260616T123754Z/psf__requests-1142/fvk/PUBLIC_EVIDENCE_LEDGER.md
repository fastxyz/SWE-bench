# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "requests.get is ALWAYS sending content length" | The bug concerns automatic `Content-Length` on `requests.get`. | Encoded by PO1 and K claim GET-NO-BODY. |
| E2 | `benchmark/PROBLEM.md` | "the right behavior is not to add this header automatically in GET requests" | Bodyless/default `GET` should not get automatic `Content-Length`. | Encoded by PO1, PO5. |
| E3 | `benchmark/PROBLEM.md` | "There's nothing stopping you from sending data in a GET request." | `GET` with an actual body remains allowed and should retain a length header. | Encoded by PO2. |
| E4 | `benchmark/PROBLEM.md` | "most UAs do not send the Content-Length header for GET requests" | Conventional default behavior supports omission for bodyless `GET`. | Encoded by PO1. |
| E5 | `repo/requests/models.py` `Request` docstring | "`data`: the body to attach the request" | `data=None` is a public no-body spelling, not stream body data. | V1 gap, fixed by PO5. |
| E6 | `reports/baseline_notes.md` | V1 assumed bodyless `GET` has `body is None`. | Audit must check all paths that should produce `body is None`. | V1 gap in FINDING F1. |
| E7 | implementation | `prepare_auth` recomputes `Content-Length` after auth. | Bodyless `GET` must remain no-auto-length after auth recomputation. | Covered by PO6. |
| E8 | implementation | Non-`GET` behavior came from issue #957 context. | Preserve non-`GET` zero-length behavior unless public intent says otherwise. | Encoded by PO3. |
