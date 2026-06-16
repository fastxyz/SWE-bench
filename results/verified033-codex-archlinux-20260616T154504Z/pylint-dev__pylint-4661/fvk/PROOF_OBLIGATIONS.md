# FVK Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Provenance | Formal claim | V2 status |
| --- | --- | --- | --- | --- |
| PO-1 | `PYLINTHOME` present implies `PYLINT_HOME == PYLINTHOME` exactly. | E3 | `PYLINTHOME-OVERRIDE` | Satisfied. |
| PO-2 | Without `PYLINTHOME`, known home plus valid absolute `XDG_CACHE_HOME` implies `PYLINT_HOME == XDG_CACHE_HOME/pylint`. | E1, E2, E5 | `DEFAULT-XDG-CACHE` | Satisfied. |
| PO-3 | Without `PYLINTHOME`, known home plus missing/empty/relative `XDG_CACHE_HOME` implies `PYLINT_HOME == HOME/.cache/pylint`. | E1, E2, E5 | `DEFAULT-HOME-CACHE` | Satisfied. |
| PO-4 | Without `PYLINTHOME`, unknown home implies `PYLINT_HOME == .pylint.d`. | E4 | `DEFAULT-NO-HOME` | Satisfied. |
| PO-5 | If the selected `PYLINT_HOME` does not exist, `save_results()` recursively creates it before writing stats. | E7 | `MAKEDIRS-MISSING` | Satisfied. |
| PO-6 | Stats paths remain under `PYLINT_HOME` and preserve basename sanitization. | E6 | prose frame obligation | Satisfied; unchanged from V1 except containing directory. |
| PO-7 | `ENV_HELP` describes the implementation's directory-selection order. | E8 | prose adequacy obligation | Satisfied by V1 and retained. |
| PO-8 | `doc/faq.rst` describes the implementation's directory-selection order. | E8 | prose compatibility obligation | Failed in V1; fixed in V2. |
| PO-9 | No public API signatures, stat filename format, or `PYLINTHOME` override behavior are changed. | E3, E6 | public compatibility audit | Satisfied. |

## Boundary Conditions

- Relative `XDG_CACHE_HOME` is outside the valid-XDG branch and is covered by PO-3.
- Empty `XDG_CACHE_HOME` is outside the valid-XDG branch and is covered by PO-3.
- Windows-specific app directory policy is not proven. The public issue asks for XDG compliance; the public hint raises Windows as a question, not as a specified contract.
- Termination is immediate for path selection and directory-effect modeling because there are no loops or recursion in the audited slice.

