# Formal Spec English

Status: paraphrase of `fvk/axios-formdata-spec.k`, constructed but not machine-checked.

1. For any nonnegative abstract multipart length `N`, if the adapter receives spec-compliant Node `FormData` with initial `Content-Type: multipart/form-data`, it reaches a state with stream request data and headers whose content type is `multipart/form-data; boundary=<generated>` and whose content length is `N`.
2. For any nonnegative legacy length `L`, if the adapter receives legacy `form-data` package data, it keeps that data on the legacy branch and applies the legacy package headers. The new spec-compliant branch does not preempt this behavior.
3. For unrelated unsupported objects, the adapter still rejects with `Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream`.

The formal model abstracts over concrete multipart bytes, socket behavior, redirects, cancellation, and network I/O. Those details are outside this issue's intended behavior; the modeled observable is adapter request-body classification plus multipart headers.
