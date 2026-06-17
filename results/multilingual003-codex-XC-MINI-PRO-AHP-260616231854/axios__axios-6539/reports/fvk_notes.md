# FVK Notes

## Decision Summary

The FVK audit did not confirm V1 unchanged. Finding F-001 showed that V1's `^\s*//` guard proved only the literal issue example and did not cover the full authority-form prefix required by proof obligation O-001. I revised the guard to reject leading C0/space characters followed by any two URL authority separators, `/` or `\`.

## Code Changes

- `repo/lib/adapters/http.js`: changed `isProtocolRelativeURL` from `/^\s*\/\//` to `/^[\u0000-\u0020]*[\\/]{2}/`. This directly addresses F-001 and discharges O-001, O-003, and O-006: the Node adapter now rejects every modeled server-side protocol-relative authority target with `AxiosError.ERR_INVALID_URL` before `new URL(fullPath, 'http://localhost')`.
- `repo/dist/node/axios.cjs`: applied the same regex change. This addresses F-002 and O-005 because CommonJS consumers load this checked-in bundle through the package export map.

## Decisions To Keep V1 Structure

- I kept the rejection point after `buildFullPath` and before `new URL(...)`. O-003 depends on this placement because `buildFullPath` is the step that can leave a protocol-relative requested URL untouched despite `baseURL`.
- I kept the existing `AxiosError('Invalid URL', AxiosError.ERR_INVALID_URL, config)` shape. O-006 requires an axios-classified invalid URL error, and no finding justified changing error construction.
- I did not change `isAbsoluteURL`, browser bundles, XHR, or fetch. F-003 and O-004 limit the fix to server-side behavior and preserve ordinary relative-path parsing.

## Verification Status

The FVK proof is constructed but not machine-checked. The exact `kompile`, `kast`, and `kprove` commands are recorded in `fvk/SPEC.md` and `fvk/PROOF.md`, but I did not run them, tests, Python, or project code per the benchmark instructions.
