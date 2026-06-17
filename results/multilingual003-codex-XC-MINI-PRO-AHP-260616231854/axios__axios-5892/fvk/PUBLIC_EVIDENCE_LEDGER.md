# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Obligation |
|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "Header content-encoding isn't automatically convert to lower case." | Normalize case before dispatch. |
| E2 | `benchmark/PROBLEM.md` | "`Gzip`, `GZIP`, `GZip`" | Mixed-case gzip examples must decode. |
| E3 | `benchmark/PROBLEM.md` | "`GZIP` ... reason why axios don't decompress content" | `GZIP` must enter gzip decode path. |
| E4 | `repo/lib/adapters/http.js` | "if decompress disabled we should not decompress" | Preserve `decompress: false`. |
| E5 | `repo/lib/adapters/http.js` | "if no content ... remove the header" | Preserve `HEAD`/`204` delete-only behavior. |
| E6 | `repo/lib/adapters/http.js` | switch cases for gzip, x-gzip, compress, x-compress, deflate, br | Preserve existing supported encoding family. |
| E7 | `repo/package.json` | CommonJS export points to `./dist/node/axios.cjs` | Mirror the source change in the CJS build. |
| E8 | default-domain assumption | HTTP content-coding values are token-like | Trim optional surrounding whitespace before case comparison. |
