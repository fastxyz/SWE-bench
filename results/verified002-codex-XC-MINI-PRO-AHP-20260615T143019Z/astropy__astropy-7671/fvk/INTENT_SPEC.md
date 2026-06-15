# Intent Specification

Status: intent-only public requirements.

1. `minversion` must not raise the reported `TypeError` for numeric package
   versions where one side has a development suffix, such as installed
   `1.14.3` and required `1.14dev`.
2. The reported case must return `True` in inclusive mode.
3. The repair should keep using `LooseVersion` with regex normalization and
   should not restore `pkg_resources.parse_version`.
4. `inclusive=True` means the installed version may equal or exceed the
   required version; `inclusive=False` means it must strictly exceed it.
5. Public module handling remains the same: imported module objects and import
   names are accepted, missing imports return `False`, and invalid module
   arguments raise `ValueError`.
6. The issue-derived domain is numeric package version strings with optional
   suffixes; full PEP 440 behavior is not required by the public evidence.

