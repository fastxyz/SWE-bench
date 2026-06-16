# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent source | Result | Notes |
| --- | --- | --- | --- |
| Parser includes `--skip-checks`. | E1, E2 | Pass | Directly required by the issue. |
| `skip_checks=False` preserves system checks. | E2, E3 | Pass | A skip flag should not change default command-line behavior. |
| `skip_checks=True` skips `self.check(display_num_errors=True)`. | E1, E3, E4 | Pass | This is the reported development reload cost. |
| `skip_checks=True` still runs `check_migrations()`. | E6 | Pass | The prompt names system checks, not migration warnings. |
| Staticfiles runserver inherits the option. | E7 | Pass | Existing subclass calls `super().add_arguments(parser)`. |
| Programmatic `skip_checks` remains accepted. | E8 and `call_command()` source flow | Pass | Parser option makes `skip_checks` a valid option; `call_command()` already defaults absent `skip_checks` to true. |

No formal-English claim is stronger than the public intent. The main coverage limitation is that the mini semantics models only parser/check scheduling, not all of Django `runserver`.
