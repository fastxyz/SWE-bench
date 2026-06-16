# Proof Obligations

Status: constructed, not machine-checked.

The obligations below are the contract for `get_child_arguments()` over the
abstract state defined in `fvk/SPEC.md`.

## PO1: Ordinary `python -m` modules use the full spec name

Evidence: E1, E2, E3.

Formal claim: `MODULE-SPEC-FULL-NAME` in `fvk/get-child-arguments-spec.k`.

Precondition:

- `Spec = moduleSpec(NAME)`
- `NAME` is non-empty.

Postcondition:

- Result is `args(BASE + ["-m", NAME] + TAIL)`.

V1 discharge:

- `repo/django/utils/autoreload.py` lines 226 through 235: when the spec name is
  neither exact `__main__` nor suffixed `.__main__`, `module_name = spec.name`;
  a truthy `module_name` returns `args + ["-m", module_name] + sys.argv[1:]`.

## PO2: Package `__main__` specs use the package parent

Evidence: E3, E4.

Formal claim: `PACKAGE-MAIN-USES-PARENT`.

Precondition:

- `Spec = packageMainSpec(PARENT)`
- `PARENT` is non-empty.

Postcondition:

- Result is `args(BASE + ["-m", PARENT] + TAIL)`.

V1 discharge:

- Lines 228 through 235 set `module_name = spec.parent` only for exact
  `__main__` or suffix `.__main__`, then return through `-m`.

## PO3: Empty module-name specs fall through to existing script fallback

Evidence: E5, E6.

Formal claim: `EMPTY-SPEC-SCRIPT-FALLBACK`.

Precondition:

- `Spec = emptyMainSpec`
- `PathState = scriptExists`

Postcondition:

- Result is `args(BASE + FULL)`.

V1 discharge:

- The `if module_name:` guard at lines 232 through 235 is not taken for an empty
  name, and the script-exists fallback at lines 236 through 250 appends
  `sys.argv`.

## PO4: No spec and existing script path uses `BASE + FULL`

Evidence: E5, E6.

Formal claim: `NO-SPEC-SCRIPT-FALLBACK`.

Precondition:

- `Spec = noSpec`
- `PathState = scriptExists`

Postcondition:

- Result is `args(BASE + FULL)`.

V1 discharge:

- With no spec, control reaches lines 236 through 250 and the script-exists
  branch appends `sys.argv`.

## PO5: Missing script with `.exe` entry point returns the executable entry point

Evidence: E5.

Formal claims: `EXE-FALLBACK` and `EMPTY-SPEC-EXE-FALLBACK`.

Precondition:

- `Spec = noSpec` or an empty-name spec.
- `PathState = exeEntry(EXE)`.

Postcondition:

- Result is `args([EXE] + TAIL)`.

V1 discharge:

- Lines 239 through 242 return `[exe_entrypoint, *sys.argv[1:]]`.

## PO6: Missing script with `-script.py` entry point keeps `BASE`

Evidence: E5.

Formal claims: `SCRIPT-ENTRY-FALLBACK` and `EMPTY-SPEC-SCRIPT-ENTRY-FALLBACK`.

Precondition:

- `Spec = noSpec` or an empty-name spec.
- `PathState = scriptEntry(SCRIPT)`.

Postcondition:

- Result is `args(BASE + [SCRIPT] + TAIL)`.

V1 discharge:

- Lines 243 through 246 return `[*args, script_entrypoint, *sys.argv[1:]]`.

## PO7: Missing script with no fallback raises the same error

Evidence: E5.

Formal claims: `MISSING-SCRIPT-ERROR` and `EMPTY-SPEC-MISSING-SCRIPT-ERROR`.

Precondition:

- `Spec = noSpec` or an empty-name spec.
- `PathState = missingScript(ARG0)`.

Postcondition:

- Result is `runtimeError(ARG0)`, representing the same RuntimeError message.

V1 discharge:

- Line 247 raises `RuntimeError('Script %s does not exist.' % py_script)`.

## PO8: Public compatibility

Evidence: E7.

Formal claim: covered by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Postcondition:

- `get_child_arguments()` remains a zero-argument helper returning a command list
  or raising the existing missing-script RuntimeError.

V1 discharge:

- The signature is unchanged, `restart_with_reloader()` still calls it without
  arguments, and the returned shape is a list in every non-error branch.
