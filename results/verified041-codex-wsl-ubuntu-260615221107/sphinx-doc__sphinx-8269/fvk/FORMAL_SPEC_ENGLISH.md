# Formal Spec In English

Status: constructed, not machine-checked.

The K artifacts are `mini-python.k` and `linkcheck-spec.k`.

## Model Vocabulary

- `statusOK`: the GET response has no HTTP error status.
- `statusHttpError`: the GET response has an ordinary HTTP error status, including examples like 404 and 500, excluding the existing special policies for 401 and 503.
- `statusUnauthorized`: a 401 response, preserved as working with unauthorized info.
- `statusUnavailable`: a 503 response, preserved as ignored.
- `anchorFound` / `anchorMissing`: the abstracted result that `check_anchor()` would return if it is reached.
- `sameUrl` / `redirectedUrl`: whether the final response URL equals the requested base URL after normalization.
- `anchorChecks`: an instrumentation cell counting whether anchor parsing was consulted.

## Claim Paraphrases

LC-HTTP-ERROR-FIRST: For any ordinary HTTP error status and any anchor parser result, the anchor-enabled branch returns `resultBrokenHttp` and leaves `anchorChecks` unchanged at zero. This means HTTP status is classified before anchor parsing.

LC-401-PRESERVED: For a 401 response, the anchor-enabled branch returns `resultWorkingUnauthorized` and leaves `anchorChecks` unchanged.

LC-503-PRESERVED: For a 503 response, the anchor-enabled branch returns `resultIgnoredHttp` and leaves `anchorChecks` unchanged.

LC-OK-MISSING-ANCHOR: For a successful response where the requested anchor is missing, the branch consults anchor parsing once and returns `resultBrokenAnchor`.

LC-OK-FOUND-SAME-URL: For a successful response where the requested anchor is found and the final URL is the requested URL, the branch consults anchor parsing once and returns `resultWorking`.

LC-OK-FOUND-REDIRECT: For a successful response where the requested anchor is found and the final URL differs, the branch consults anchor parsing once and returns `resultRedirected`.

There are no loops or recursive circularities in the reduced model. The HTML parser's chunk loop is outside this proof scope and is represented only by `anchorFound` or `anchorMissing`.
