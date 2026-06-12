import sys
from pathlib import Path

# Ensure the repo root is first on sys.path so that `fvk_bench/` (the source
# package) is resolved before `tests/fvk_bench/` (the test sub-package).
_repo_root = str(Path(__file__).resolve().parent)
if _repo_root not in sys.path:
    sys.path.insert(0, _repo_root)
