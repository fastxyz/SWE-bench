# Spec Audit

Status: adequacy comparison, constructed and not machine-checked.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| DEPS-INFO-INCLUDES-JOBLIB | Matches E1-E4: `joblib` must be in the `show_versions()` dependency listing for scikit-learn 0.22. | Pass |
| DEPS-INFO-PRESERVES-EXISTING-DEPS | Matches the frame condition implied by adding one dependency without removing existing reported dependencies. | Pass |
| SHOW-VERSIONS-PRINTS-DEPS-INFO | Matches E1 and E5: the user-visible artifact is `show_versions()` output. | Pass |
| LEGACY-LIST-OMITS-JOBLIB | Used only as root-cause localization, not as desired behavior. It conflicts with E1 and is recorded as a pre-V1 finding. | Pass as diagnostic |
| No ordering claim | The public issue requires inclusion of `joblib`, not a specific dependency row order. | Pass |
| Issue-template unchanged | E2 permits either adding to `show_versions()` dependencies or adding to the template; E5 shows the template already invokes `show_versions()` for this version range. | Pass |

No formal-English claim is weaker than the public intent. No formal-English
claim adds an unsupported ordering, API, or error-behavior requirement.
