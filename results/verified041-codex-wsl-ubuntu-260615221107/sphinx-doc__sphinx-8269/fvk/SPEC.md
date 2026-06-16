# FVK Spec

Status: constructed, not machine-checked.

## Audited Unit

The audited unit is the anchor-enabled HTTP(S) branch of `CheckExternalLinksBuilder.check_thread.<locals>.check_uri()` in `repo/sphinx/builders/linkcheck.py`. This is the branch reached when a URI has a non-ignored fragment and `linkcheck_anchors` is true.

The proof model abstracts network I/O into a response status class and abstracts `check_anchor()` into `anchorFound` or `anchorMissing`. That is property-complete for this issue because the observable defect is whether HTTP errors are classified before the anchor parser can report a missing anchor.

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "Linkcheck should report HTTP errors instead of Anchor not found" | HTTP errors dominate missing-anchor errors. |
| E-2 | `benchmark/PROBLEM.md` | "e.g. 404, 500" | Ordinary HTTP error statuses are in scope as a family. |
| E-3 | `benchmark/PROBLEM.md` | "Same as when `linkcheck_anchors=False`" | Use existing non-anchor HTTPError classification for the base URL. |
| E-4 | `benchmark/PROBLEM.md` | Expected output omits the fragment in the `HTTPError` URL | Status validation applies to `req_url`, not the fragment-bearing URI. |
| E-5 | `repo/doc/usage/configuration.rst` | `linkcheck_anchors` checks validity of anchors when true | Successful responses still need anchor validation. |
| E-6 | `repo/sphinx/builders/linkcheck.py` | Non-anchor branch calls `response.raise_for_status()` | Existing implementation mechanism for HTTP status classification. |
| E-7 | `repo/sphinx/builders/linkcheck.py` | `HTTPError` handler special-cases 401 and 503 | Preserve existing status policy after moving anchor branch into that handler. |

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For an anchor-bearing HTTP(S) URI with `linkcheck_anchors = True`:

1. If the GET response has an ordinary HTTP error status, the result is `broken` with the existing `HTTPError` text, and `check_anchor()` is not consulted.
2. If the GET response has status 401, the result follows the existing policy: `working`, with unauthorized info.
3. If the GET response has status 503, the result follows the existing policy: `ignored`, with the `HTTPError` text.
4. If the GET response is successful and the requested anchor is missing, the result is `broken` with `Anchor '<anchor>' not found`.
5. If the GET response is successful and the requested anchor is found, the result remains `working` or `redirected` according to the existing final-URL comparison.

## Formal Artifacts

- `fvk/mini-python.k`: minimal K semantics for the reduced branch classifier.
- `fvk/linkcheck-spec.k`: K claims for HTTP-error precedence, preserved special HTTP policies, successful missing anchors, and successful found anchors.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of each claim.
- `fvk/SPEC_AUDIT.md`: adequacy check from intent to claims.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: API and callsite compatibility check.

## Scope Boundaries

- This proof does not formalize all of Sphinx or all of `check_uri()`.
- This proof does not prove HTML parser correctness inside `check_anchor()`.
- This proof does not prove network termination, retry termination, or request library behavior.
- These boundaries do not block the V1 fix because the issue's required observable is the precedence of HTTP status errors over anchor-not-found errors.
