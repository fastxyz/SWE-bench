# Spec Audit

| Claim | Intent Coverage | Status |
|---|---|---|
| C1 | Matches I2 and E2/E3: explicitly topocentric ITRS to AltAz is direct and time-invariant for no refraction. | PASS |
| C2 | Matches I2 and E2/E3 for HADec. | PASS |
| C3 | Matches I4 and E4/E6: differing origins preserve existing ITRS self-transform semantics. | PASS |
| C4 | Matches I3 for inverse no-refraction observed-to-topocentric-ITRS conversion. | PASS |
| C5 | Matches I3/I4: requested non-matching ITRS output location delegates to self-transform. | PASS |
| C6 | Matches I5/E5: refraction is not ignored and requires `obstime`. | PASS |
| C7 | Matches I6: intermediate transforms must preserve ITRS `location`. | PASS |
| C8 | Matches I1/E7: `earth_location` must account for ITRS `location`. | PASS |

## Adequacy Notes

The formal model deliberately abstracts numerical trigonometry, ERFA
refraction, and the existing ITRS self-transform. That abstraction is adequate
for the audited defect because the defect is about transform selection,
location/origin handling, and whether a topocentric ITRS vector can avoid the
SSB-oriented ITRS self-transform. It is not a proof of numerical astronomy
accuracy.

No formal-English claim is derived only from V1 implementation behavior. The
decision to preserve geocentric ITRS behavior is supported by public issue
discussion and existing public docs/tests, not by the candidate patch alone.
