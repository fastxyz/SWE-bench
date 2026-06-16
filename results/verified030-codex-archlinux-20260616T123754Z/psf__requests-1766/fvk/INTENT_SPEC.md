# Intent Spec

Status: constructed from public evidence; not machine-checked.

## Target

This FVK pass audits the digest-qop behavior of `requests.auth.HTTPDigestAuth.build_digest_header` and its callers in `handle_401` and `__call__`. Other digest fields are treated as frame conditions unless they interact with the qop directive.

## Intent-Only Obligations

I-1. When Digest Auth emits a qop directive for the supported `auth` quality of protection, the outgoing Authorization header must serialize that directive with a quoted value: `qop="auth"`.

I-2. The qop challenge value is a set/list of one or more server-supported tokens. If the options include `auth`, Requests' current implementation selects `auth`; the selected token used in the response digest input and the selected token advertised in the header must be the same token.

I-3. If the challenge has no qop directive, the existing no-qop digest path remains in scope and must not emit a qop header fragment.

I-4. A challenge whose qop options do not contain `auth` is outside the currently implemented qop-auth path. The existing source explicitly marks `auth-int` as not implemented; this audit must not claim full `auth-int` support.

I-5. The repair must not change the public `HTTPDigestAuth` construction pattern, the `build_digest_header(method, url)` signature, or the internal callsites that install the `Authorization` header.

