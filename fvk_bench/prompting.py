"""Prompt rendering and content-hashing for the three benchmark arms.

Templates live as ``<arm>.md`` files in :data:`fvk_bench.config.PROMPTS_DIR` and
are part of the experiment specification: their sha256 hashes are recorded in
the run manifest so cross-machine runs can prove they used identical prompts.

Templates are rendered with :meth:`str.format`, so they must stay brace-safe:
the only ``{...}`` occurrences allowed are the three placeholders
``{instance_id}``, ``{repo}`` and ``{base_commit}`` — any literal brace (e.g.
an inline JSON example) would break rendering.
"""

import hashlib

from fvk_bench import config
from fvk_bench.instances import Instance


def _template_path(arm: str):
    """Return the template path for ``arm``, rejecting unknown arms.

    Raises:
        KeyError: if ``arm`` is not one of :data:`fvk_bench.config.ARMS`.
    """
    if arm not in config.ARMS:
        raise KeyError(f"Unknown arm {arm!r}; expected one of {config.ARMS}")
    return config.PROMPTS_DIR / f"{arm}.md"


def render_prompt(arm: str, inst: Instance) -> str:
    """Render the prompt for ``arm`` from ``inst``'s public metadata.

    Only public fields are substituted (instance_id, repo, base_commit) — never
    hidden benchmark data such as test names or counts.

    Raises:
        KeyError: if ``arm`` is not a known arm.
    """
    template = _template_path(arm).read_text(encoding="utf-8")
    return template.format(
        instance_id=inst.instance_id,
        repo=inst.repo,
        base_commit=inst.base_commit,
    )


def template_hashes() -> dict[str, str]:
    """Return ``{arm: sha256-hex of the template file BYTES}`` for all arms.

    Hashing raw bytes (not rendered text) pins the exact on-disk templates,
    independent of any instance.
    """
    return {
        arm: hashlib.sha256(_template_path(arm).read_bytes()).hexdigest()
        for arm in config.ARMS
    }
