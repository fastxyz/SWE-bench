# Formal Spec English

Status: constructed, not machine-checked.

1. Claim `GET-NO-BODY`: if the method is `GET`, the request body is absent, and
   the headers initially do not contain `Content-Length`, then preparing content
   length leaves `Content-Length` absent.
2. Claim `GET-NONE-DATA`: if a public `Request` is built with method `GET` and
   `data=None`, `data` normalizes to empty dict/no body, and preparation leaves
   `Content-Length` absent.
3. Claim `GET-BODY`: if the method is `GET` and the prepared body has known
   length `N >= 0`, preparing content length leaves `Content-Length` present.
4. Claim `OTHER-NO-BODY`: if the method is not `GET`, the body is absent, and
   `Content-Length` was not already present, preparing content length leaves
   `Content-Length` present.
5. Claim `GET-EXPLICIT-CL`: if the method is `GET`, the body is absent, and
   `Content-Length` was already present, preparation preserves it.
6. Auth recomputation frame condition: if auth handling does not introduce a
   body, calling `prepare_content_length` again on a bodyless `GET` does not add
   `Content-Length`.
7. No loop circularity is required for this code slice because the audited
   functions contain no loops.
