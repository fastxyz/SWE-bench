# FVK Findings

Status: constructed, not machine-checked.

## F-001: V1 Only Rejected Literal `//`

- Classification: code bug in V1; needed guard refinement.
- Evidence: O-001 requires rejecting every server-side authority-form protocol-relative request target before `new URL(fullPath, 'http://localhost')`.
- V1 observed behavior by source inspection: `isProtocolRelativeURL = /^\s*\/\//` rejected `//host` but not paired slash/backslash variants such as `/\host`, `\/host`, or `\\host`, nor all leading C0 controls the URL parser may trim before interpreting authority form.
- Expected behavior: all strings whose parser-trimmed prefix is two authority separators (`/` or `\`) reject with `ERR_INVALID_URL`.
- V2 action: changed the predicate in both Node adapter copies to `/^[\u0000-\u0020]*[\\/]{2}/`.
- Proof obligation: O-001.

## F-002: Bundle Parity Is Required

- Classification: compatibility and packaging obligation.
- Evidence: O-005 and `package.json` route CommonJS consumers to `dist/node/axios.cjs`.
- Observed risk: patching only `lib/adapters/http.js` would leave `require('axios')` on the vulnerable checked-in bundle in this workspace.
- V2 action: kept the source adapter and `dist/node/axios.cjs` predicates and rejection branches identical.
- Proof obligation: O-005.

## F-003: Browser Protocol-Relative Behavior Is Out Of Scope

- Classification: scope finding.
- Evidence: the issue is specifically server-side SSRF and says protocol-relative URLs lack a server-side ambient protocol.
- Decision: do not change `isAbsoluteURL`, browser bundles, XHR adapter, or fetch adapter.
- Proof obligations: O-001, O-002, O-004.

## F-004: Proof Is Constructed, Not Machine-Checked

- Classification: proof status and test guidance.
- Evidence: benchmark instructions forbid running K tooling, tests, Python, or project code.
- Decision: no tests were run and no tests were modified. The emitted `kompile`, `kast`, and `kprove` commands are recorded for later use.

