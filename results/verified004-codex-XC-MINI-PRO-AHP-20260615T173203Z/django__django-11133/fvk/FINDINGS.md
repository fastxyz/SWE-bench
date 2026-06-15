# FVK Findings

Status: V1 confirmed. No source-code defect was found during the FVK audit.

## F-001: Original Memoryview Symptom Is Addressed

Classification: code bug fixed by V1.

Input: `HttpResponse(memoryview(b"My Content")).content`

Observed pre-fix behavior from issue: memoryview object representation or otherwise not `b"My Content"`.

Expected behavior from public intent: `b"My Content"`.

Proof obligations: PO-001 and PO-002.

Finding: V1 discharges both necessary obligations. `make_bytes()` now converts memoryview with `bytes(value)`, and the content setter now routes top-level memoryview through `make_bytes()` instead of the iterable chunk path.

Recommended action: keep V1 source unchanged.

## F-002: A `make_bytes()`-Only Patch Would Be Incomplete

Classification: proof-derived localization finding.

Input: `HttpResponse(memoryview(payload))`

Risk: a patch that only changes `make_bytes()` can still fail if the content setter consumes a top-level memoryview as an iterable before `make_bytes()` receives the original object.

Expected behavior: memoryview is scalar bytes-like content for regular `HttpResponse`.

Proof obligations: PO-001 and PO-002.

Finding: V1 includes the extra content-setter branch change required by PO-002, so this incompleteness risk is not present.

Recommended action: keep both V1 edits.

## F-003: Existing String, Bytes, and Ordinary Iterable Behavior Is Preserved

Classification: frame-condition finding.

Inputs: `HttpResponse("My Content")`, `HttpResponse(b"My Content")`, and ordinary iterable chunk content such as `["abc", "def"]`.

Expected behavior: preserve behavior marked correct by the issue and documented by the content setter comment.

Proof obligations: PO-003, PO-004, PO-005.

Finding: V1 does not alter the string branch, bytes branch, or ordinary iterable branch, except to remove memoryview from the iterable category because public intent classifies it as bytes-like scalar content.

Recommended action: no source change.

## F-004: `bytearray` Is Not Part of This Fix

Classification: scoped alternative rejected.

Input: `HttpResponse(bytearray(b"My Content"))`

Expected behavior from this issue: not specified. The public issue and hints specifically identify memoryview from PostgreSQL `BinaryField` retrieval and point to `memoryview` handling in `make_bytes()`.

Proof obligations: none for this FVK run.

Finding: broadening the change to `bytearray` would alter another iterable type without direct issue evidence. The audit does not use current behavior as proof that bytearray is correct; it only concludes that bytearray is outside the public intent for this task.

Recommended action: do not change bytearray behavior in this patch. A separate issue/spec should decide that behavior.

## F-005: Top-Level `StreamingHttpResponse(memoryview(...))` Is Outside Scope

Classification: residual risk and test guidance.

Input: `StreamingHttpResponse(memoryview(payload))`

Expected behavior from this issue: not specified. The issue demonstrates regular `HttpResponse`, while streaming responses publicly accept an iterable of chunks.

Proof obligations: PO-001 covers memoryview chunks yielded by a streaming iterator, but no proof obligation covers treating a top-level streaming memoryview as one chunk.

Finding: V1 improves streaming conversion for iterators that yield memoryview chunks because `streaming_content` maps each chunk through `make_bytes()`. It intentionally does not reinterpret a memoryview object itself as a single streaming chunk.

Recommended action: no source change for this issue.

## Proof-Derived Findings from `/verify`

No failed verification condition or adequacy mismatch was found. The only proof-derived risk was F-002, and V1 already contains the necessary content-setter edit.

The proof remains constructed, not machine-checked. No test removal is recommended.
