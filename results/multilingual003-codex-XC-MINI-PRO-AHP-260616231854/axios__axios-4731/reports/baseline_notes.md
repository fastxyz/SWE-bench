# Baseline Notes

## Root cause

Axios uses `maxBodyLength: -1` as its default "unlimited request body" sentinel. The Node HTTP adapter enforces that sentinel correctly for buffered request data before sending, but it only forwarded `options.maxBodyLength` to the selected transport when `config.maxBodyLength > -1`.

When redirects are enabled, axios uses `follow-redirects` as the transport. If axios omits `maxBodyLength`, `follow-redirects` applies its own default limit instead of axios' unlimited default. That makes default redirect-capable requests fail around the transport's default body limit, while `maxRedirects: 0` requests go through Node's native transport without that limit.

## Files changed

- `repo/lib/adapters/http.js`: always populate `options.maxBodyLength`. Explicit finite limits are still forwarded unchanged. Values that axios treats as unlimited are forwarded as `Infinity`, which is the unlimited value understood by `follow-redirects`.

## Assumptions and alternatives considered

- I assumed the fix belongs in the HTTP adapter because the inconsistency only appears in Node requests when the adapter delegates to `follow-redirects`.
- I did not change tests because the task forbids modifying test files.
- I did not update generated `dist/` bundles. The package entry point loads `lib/axios`, and this issue is specific to the Node HTTP adapter under `lib/`. The browser bundles do not contain the Node `follow-redirects` path.
- I considered setting `Infinity` only inside the `follow-redirects` branch. I rejected that because the existing code already attaches explicit `maxBodyLength` values after transport selection, so keeping one assignment preserves the adapter's existing option flow while fixing the omitted unlimited case.
- I considered changing axios' default from `-1` to `Infinity`. I rejected that as broader than necessary because the rest of the adapter and configuration merging already use `-1` as the sentinel.

No tests or project code were run, per the task instructions.
