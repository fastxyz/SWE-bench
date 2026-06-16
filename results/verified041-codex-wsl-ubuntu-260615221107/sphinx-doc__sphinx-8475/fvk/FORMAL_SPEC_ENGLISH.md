# Formal Spec English

The formal model abstracts one non-anchor linkcheck decision as:

`checkNoAnchor(HEAD_OUTCOME, GET_OUTCOME) => result(STATUS, USED_GET)`

`HEAD_OUTCOME` and `GET_OUTCOME` are symbolic summaries of Requests behavior.
`USED_GET` records whether fallback GET was invoked.

## Claim Meanings

- If `HEAD_OUTCOME` is `tooManyRedirects` and `GET_OUTCOME` is a successful
  same-URL response, the result is `working` and `USED_GET` is true.
- If `HEAD_OUTCOME` is `tooManyRedirects` and `GET_OUTCOME` is a successful
  redirected response, the result is `redirected(CODE)` and `USED_GET` is true.
- If `HEAD_OUTCOME` is `tooManyRedirects` and `GET_OUTCOME` is `httpError(401)`,
  the result is the existing unauthorized-working classification and `USED_GET`
  is true.
- If `HEAD_OUTCOME` is `tooManyRedirects` and `GET_OUTCOME` is `httpError(503)`,
  the result is the existing ignored-503 classification and `USED_GET` is true.
- If `HEAD_OUTCOME` is `tooManyRedirects` and `GET_OUTCOME` is another
  `httpError`, another `tooManyRedirects`, or another exception, the result is
  broken and `USED_GET` is true.
- If `HEAD_OUTCOME` is successful, the result is classified from the HEAD
  response and `USED_GET` is false.
- If `HEAD_OUTCOME` is an HTTP error, the result is classified from GET and
  `USED_GET` is true.
