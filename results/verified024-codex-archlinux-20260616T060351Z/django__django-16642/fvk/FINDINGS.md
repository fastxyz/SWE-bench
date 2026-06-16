# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## FVK-F1: `.br` FileResponse MIME Guessing

Classification: code bug in V0, resolved by V1.

Input:

```python
FileResponse(open("test.html.br", "rb"))
```

Observed before V1, per the public issue: `Content-Type: text/html`.

Expected by SPEC O1/O2: `Content-Type: application/x-brotli`.

Evidence: E1 and E2 identify `.br` as a final compressed suffix whose previous
`text/html` result was improper. E3/E4 establish the existing `FileResponse`
policy of serving compressed suffixes as compressed-file media types without
setting `Content-Encoding`.

V1 status: discharged by adding `"br": "application/x-brotli"` to the existing
encoding map.

## FVK-F2: `.Z` FileResponse MIME Guessing

Classification: code bug in V0, resolved by V1.

Input:

```python
FileResponse(open("test.html.Z", "rb"))
```

Observed before V1, per the public issue: `Content-Type: text/html`.

Expected by SPEC O1/O3: `Content-Type: application/x-compress`.

Evidence: E1 and E2 identify `.Z` as a final compressed suffix whose previous
`text/html` result was improper. E3/E4 establish the existing `FileResponse`
policy for compressed suffixes. `application/x-compress` is also consistent
with the in-repo public MIME evidence in `tests/test_client_regress/tests.py`.

V1 status: discharged by adding `"compress": "application/x-compress"` to the
existing encoding map.

## FVK-F3: Existing Compressed Cases Must Remain Stable

Classification: frame condition, satisfied by V1.

Inputs:

```text
*.gz  -> application/gzip
*.bz2 -> application/x-bzip
*.xz  -> application/x-xz
```

Observed public behavior: `tests/responses/test_fileresponse.py` asserts these
compressed-file media types and asserts no `Content-Encoding` header.

Expected by SPEC O4/O5: the existing mappings and absent `Content-Encoding`
behavior remain unchanged.

V1 status: discharged. The patch only adds `br` and `compress` keys and leaves
the existing keys and the no-encoding behavior untouched.

## FVK-F4: Static-File Serving Is a Distinct Contract

Classification: rejected alternative, no source change.

Input family:

```text
django.views.static.serve(..., path="*.gz" or another encoded filename)
```

Observed public behavior: `django.views.static.serve()` computes an explicit
content type, passes it to `FileResponse`, and then sets `Content-Encoding`
when `mimetypes.guess_type()` reports an encoding. Public tests assert that
relationship for static serving.

Expected by SPEC scope and O5: the `FileResponse(open(...))` bug fix must not
rewrite `django.views.static.serve()` into the download-oriented `FileResponse`
compressed-file policy.

V1 status: no change needed. Leaving `django/views/static.py` unchanged is
justified by SPEC E6 and PROOF_OBLIGATIONS PO-8.

## FVK-F5: Constructed Proof Is Not Machine-Checked

Classification: proof honesty / residual risk.

The FVK proof artifacts and K claims are constructed but not machine-checked.
The commands to check them are recorded in `PROOF.md`; they were intentionally
not executed because the task forbids running K tooling, Python, tests, or
project code.

Expected next step outside this benchmark: run the recorded `kompile`, `kast`,
and `kprove` commands and keep all tests until a real `kprove` run returns
`#Top`.

V1 status: this is not a source-code defect. It is a verification confidence
limit required by the task constraints.
