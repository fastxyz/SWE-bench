# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent mapping | Verdict |
| --- | --- | --- |
| SPAN-HORIZONTAL-INTERACTIVE | Matches I1-I4: construction of horizontal interactive selector must preserve plotted-data limits while adding UI helper artists. | Pass |
| SPAN-VERTICAL-INTERACTIVE | Matches I5 and public `direction` API symmetry. The issue is horizontal, but the same helper-artist frame condition applies to the selected data axis. | Pass |
| SPAN-HORIZONTAL-NONINTERACTIVE | Matches I4/I6: the fix should not make noninteractive construction pollute data limits or lose its rectangle helper. | Pass |
| SPAN-V0-BUG-LOCALIZATION | Matches E7/E8 as a root-cause witness for the old behavior. It is explicitly marked as undesired legacy behavior. | Pass |

## Candidate-derived checks

The proof does not accept the V1 implementation as the spec. The public issue
sets the frame condition: selector construction must not add `0` to plotted
data limits. V1 is then checked against that condition by the obligations in
`PROOF_OBLIGATIONS.md`.

## Adequacy conclusion

The formal claims cover the reported construction-time failure, the helper
artist preservation needed for interaction, and the relevant horizontal/vertical
constructor modes. No claim preserves the legacy behavior where helper artists
affect `dataLim`; that behavior is isolated as a bug witness.
