# Formal Spec In English

- `PYLINTHOME-OVERRIDE`: If the environment contains `PYLINTHOME`, resolving Pylint home returns that value exactly.
- `DEFAULT-XDG-CACHE`: If `PYLINTHOME` is absent, the home directory is known, and `XDG_CACHE_HOME` is valid and absolute, resolving Pylint home returns `XDG_CACHE_HOME/pylint`.
- `DEFAULT-HOME-CACHE`: If `PYLINTHOME` is absent, the home directory is known, and `XDG_CACHE_HOME` is not valid, resolving Pylint home returns `$HOME/.cache/pylint`.
- `DEFAULT-NO-HOME`: If `PYLINTHOME` is absent and the home directory is not known, resolving Pylint home returns `.pylint.d`.
- `MAKEDIRS-MISSING`: If the selected directory is missing, saving results recursively creates that selected directory before continuing.
- `NO-MAKEDIRS-EXISTING`: If the selected directory already exists, saving results does not need to create it again.

