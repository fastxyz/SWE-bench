# Intent Specification

The public intent requires Pylint to stop using a normal user's home directory as the default parent for `.pylint.d` persistent stats. `PYLINTHOME` must remain an exact user override. When no override exists, regenerable `.stats` data should go under an XDG cache program directory: absolute `XDG_CACHE_HOME/pylint` when available, otherwise `$HOME/.cache/pylint`. The legacy `.pylint.d` current-directory fallback is retained only when the home directory is not discoverable. Public help and FAQ documentation must describe the same behavior.

