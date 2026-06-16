# Baseline Notes

## Root cause

`requests.utils.prepend_scheme_if_needed` was changed to parse proxy URLs with
`urllib3.util.parse_url`. That parser stores userinfo credentials in the
separate `auth` field, while its `netloc` property contains only the host and
optional port. The function rebuilt the URL with `urlunparse` using only
`parsed.netloc`, so proxy URLs like `user:pass@proxy.example:8080` were
normalized to `http://proxy.example:8080` and lost their credentials. Later
proxy setup then could not derive `Proxy-Authorization`, causing authenticated
proxies to return 407 responses.

## Files changed

`repo/requests/utils.py`

- Reattached the parsed `auth` component to the netloc before rebuilding the
  URL in `prepend_scheme_if_needed`.
- Left the existing netloc/path swap intact so scheme prepending keeps its
  previous compatibility behavior for URLs that stdlib parsing historically
  treated as lacking a netloc.

## Assumptions and alternatives considered

- Assumed the proxy credential loss described in the issue is caused by URL
  normalization before `HTTPAdapter.proxy_manager_for` and
  `HTTPAdapter.proxy_headers` inspect the proxy URL.
- Assumed `parse_url` returns the proxy userinfo in `auth` in its original
  escaped form, which is the correct representation to place back into a URL
  string before existing auth extraction later decodes it.
- Considered changing `HTTPAdapter` to recover credentials from the original
  proxy string, but rejected that because the normalized proxy URL itself is
  passed onward and used as the proxy manager key; it should preserve auth.
- Considered rebuilding from `parse_url`'s full URL representation, but rejected
  that to avoid changing the existing compatibility workaround that swaps
  netloc and path for scheme-less inputs.
