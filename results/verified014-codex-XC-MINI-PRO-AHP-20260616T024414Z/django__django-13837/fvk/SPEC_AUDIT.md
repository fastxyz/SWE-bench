# Spec Adequacy Audit

Status: constructed, not machine-checked.

## PACKAGE_MAIN

Formal English: non-empty `__main__.__spec__.parent == P` returns
`[python, warnings..., "-m", P, argv-tail...]`.

Intent mapping: I1, I2, I3, E1, E2, E3, E4.

Verdict: pass. The claim matches the issue's requested algorithm and removes
the Django-specific path comparison.

## SCRIPT_EXISTS

Formal English: without package parent, an existing script/path restarts as
`[python, warnings..., argv...]`.

Intent mapping: I4, I5, E5, E6.

Verdict: pass. This preserves the existing non-package behavior and avoids
turning directory/zip execution's empty parent into `-m`.

## EXE_FALLBACK

Formal English: without package parent and with a `.exe` entrypoint fallback,
return `[exe_entrypoint, argv-tail...]`.

Intent mapping: I5, E6.

Verdict: pass. This frame condition is unchanged by the fix.

## SCRIPT_FALLBACK

Formal English: without package parent and with a `-script.py` fallback, return
`[python, warnings..., script_entrypoint, argv-tail...]`.

Intent mapping: I5, E6.

Verdict: pass. This frame condition is unchanged by the fix.

## MISSING_SCRIPT

Formal English: without package parent and without any fallback, raise the
existing missing-script `RuntimeError`.

Intent mapping: I5, E6.

Verdict: pass. This error behavior is outside the reported bug and is preserved.

## Suspect Legacy Mechanism

The old public test that simulates `python -m django` by only patching
`sys.argv[0]` to `django.__main__.__file__` is marked suspect for mechanism
because the issue specifically rejects `__file__` as the detection source. The
positive obligation it still supports is that real `python -m django`, where
`__main__.__spec__.parent == "django"`, remains covered by `PACKAGE_MAIN`.
