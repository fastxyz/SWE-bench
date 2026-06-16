# Formal Spec English

Status: English paraphrase of the K claims; constructed, not machine-checked.

## Claim PACKAGE_MAIN

If `get_child_arguments()` observes a non-empty `__main__.__spec__.parent == P`,
then it returns:

`[sys.executable] + ["-W" + option for option in sys.warnoptions] + ["-m", P] + sys.argv[1:]`

This branch does not inspect whether `sys.argv[0]` exists and does not compare
it with `django.__main__.__file__`.

## Claim SCRIPT_EXISTS

If there is no non-empty package parent and `sys.argv[0]` exists as a script or
path entry, then the function returns:

`[sys.executable] + ["-W" + option for option in sys.warnoptions] + sys.argv`

## Claim EXE_FALLBACK

If there is no non-empty package parent, `sys.argv[0]` does not exist, and the
corresponding `.exe` entrypoint exists, then the function returns:

`[exe_entrypoint] + sys.argv[1:]`

## Claim SCRIPT_FALLBACK

If there is no non-empty package parent, `sys.argv[0]` does not exist, no `.exe`
entrypoint exists, and the corresponding `-script.py` entrypoint exists, then
the function returns:

`[sys.executable] + ["-W" + option for option in sys.warnoptions] + [script_entrypoint] + sys.argv[1:]`

## Claim MISSING_SCRIPT

If there is no non-empty package parent, `sys.argv[0]` does not exist, and
neither fallback entrypoint exists, then the function raises `RuntimeError` with
the existing message shape.

## Loop Claims

There are no loop circularities for `get_child_arguments()`. The
`restart_with_reloader()` loop is outside the changed decision logic; its
compatibility obligation is that it consumes the argument vector returned by
`get_child_arguments()` unchanged.
