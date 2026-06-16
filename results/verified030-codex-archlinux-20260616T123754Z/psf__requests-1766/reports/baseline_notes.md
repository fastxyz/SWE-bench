# Baseline Notes

## Root cause

`HTTPDigestAuth.build_digest_header` parsed the server's `qop` challenge correctly and used the `auth` quality-of-protection token when calculating the digest response, but serialized the outgoing Authorization header as `qop=auth`. The issue reports that some digest-auth servers require the `qop` directive value to be a quoted string, so the unquoted field can cause otherwise valid digest authentication to be rejected.

## Changed files

`repo/requests/auth.py`

Changed the Digest Authorization header formatting from `qop=auth` to `qop="auth"`. The digest input still uses the bare `auth` token through the existing `qop` value, so nonce counting, cnonce generation, algorithm handling, and response digest calculation are unchanged.

`reports/baseline_notes.md`

Added this required implementation note covering the diagnosis, changed files, assumptions, and rejected alternatives.

## Assumptions and alternatives considered

I treated the issue as a client Authorization-header formatting problem because Requests is acting as the digest client here, and the only local `qop` emission point is in `HTTPDigestAuth.build_digest_header`.

I left `parse_dict_header` unchanged because it already accepts quoted challenge values and strips the quotes for internal use. Changing parsing would not affect the outgoing header form that the issue identifies.

I did not quote `nc` or alter `cnonce`, `nonce`, `realm`, `opaque`, or `algorithm` handling because the issue only identifies `qop`, and those fields already follow the existing formatter's conventions.

I kept the selected qop value as `auth` because this implementation already supports only `auth` and explicitly returns `None` for other qop values such as `auth-int`.
