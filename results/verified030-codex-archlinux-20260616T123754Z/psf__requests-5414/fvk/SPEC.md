# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

The audited unit is the HTTP URL host-validation portion of
`PreparedRequest.prepare_url` in `repo/requests/models.py`, specifically the
ASCII-host branch after `parse_url` has produced a non-empty host. This is the
branch that V1 changed and the branch that can allow `http://.example.com` to
reach lower IDNA/networking code.

The model abstracts away URL parsing, query parameter encoding, path
reconstruction, and request sending. Those behaviors are outside the reported
failure mechanism and are represented as frame conditions: once a host is valid
for this branch, the pre-existing preparation path continues.

## Intent-Only Requirements

I-1. `requests.get("http://.example.com")` must not leak `UnicodeError`.

I-2. The reported invalid host must be rejected as a Requests `InvalidURL`.

I-3. The error message for the reported invalid host should follow the existing
Requests invalid-label path: `URL has an invalid label.`

I-4. The non-ASCII IDNA path should remain unchanged; the issue is an ASCII host
that skipped IDNA validation.

I-5. ASCII hosts that do not have the issue-derived invalid-label shape should
not be subjected to full IDNA validation merely because of this fix.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | `Getting http://.example.com raises UnicodeError` | The concrete URL is in scope and the raw `UnicodeError` is the bug symptom, not behavior to preserve. | Encoded by PO-1. |
| E-2 | `benchmark/PROBLEM.md` | `Expected Result ... InvalidUrl: URL has an invalid label.` | The replacement observable is `InvalidURL` with the invalid-label message. | Encoded by PO-1, PO-2, PO-3. |
| E-3 | `benchmark/PROBLEM.md` | `label empty or too long` in the actual error text | The concrete failure is caused by an empty label; leading and interior non-final empty ASCII labels are the justified family. | Encoded by PO-2 and PO-3. |
| E-4 | `repo/requests/models.py` existing code | Non-ASCII hosts call `_get_idna_encoded_host`; `UnicodeError` is already converted to `InvalidURL`. | Preserve the non-ASCII branch. | Encoded by PO-5. |
| E-5 | `repo/requests/models.py` existing comment/code | ASCII hosts were intentionally allowed unencoded except for wildcard rejection. | Do not replace the ASCII branch with full IDNA validation without stronger intent evidence. | Encoded by PO-4 and PO-6. |

## Formal Spec Summary

The formal core is in:

- `fvk/mini-python.k`
- `fvk/requests-url-spec.k`

The reduced K model defines one observable operation:

`prepareAsciiHost(H) -> validHost(H) | invalidURL("URL has an invalid label.")`

`BadAsciiHost(H)` is true exactly when the ASCII host starts with `*`, starts
with `.`, or contains `..`. This captures the existing wildcard guard plus the
issue-derived leading/interior empty-label guard. A single trailing dot, such as
`example.com.`, is not `BadAsciiHost` in this model unless another bad predicate
also holds.

## Formal Spec English

FE-1. For the concrete host `.example.com`, ASCII host preparation reaches
`InvalidURL("URL has an invalid label.")`.

FE-2. For any ASCII host beginning with `.`, ASCII host preparation reaches
`InvalidURL("URL has an invalid label.")`.

FE-3. For any ASCII host containing `..`, ASCII host preparation reaches
`InvalidURL("URL has an invalid label.")`.

FE-4. For any ASCII host beginning with `*`, ASCII host preparation keeps the
existing `InvalidURL("URL has an invalid label.")` behavior.

FE-5. For ASCII hosts that do not start with `*` or `.` and do not contain `..`,
this fix does not reject the host on the ASCII validation branch.

## Adequacy Audit

| Formal item | Intent comparison | Result |
| --- | --- | --- |
| FE-1 | Directly matches E-1 and E-2. | Pass |
| FE-2 | Generalizes the concrete leading empty-label host from E-1 and E-3. | Pass |
| FE-3 | Uses the same empty-label mechanism from E-3 for interior empty labels. | Pass |
| FE-4 | Preserves existing wildcard behavior from E-5. | Pass |
| FE-5 | Preserves ASCII compatibility from E-5 and avoids overfitting the fix into full IDNA validation. | Pass |

No formal item is derived only from hidden tests, benchmark results, or upstream
patch knowledge.

## Public Compatibility Audit

The source change does not alter public function names, method signatures,
return shapes, subclass dispatch, import paths, or exception class hierarchy.
It only changes one branch in `PreparedRequest.prepare_url` so a previously
leaked lower-level `UnicodeError` becomes the existing public Requests
`InvalidURL` type for the issue-derived invalid host family.

## Machine-Check Commands

These commands are recorded for later use and were not executed:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/requests-url-spec.k
kprove fvk/requests-url-spec.k
```
