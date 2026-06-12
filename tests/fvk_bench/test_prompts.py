"""Tests for the three versioned prompt templates and fvk_bench.prompting.

The fvk/control parity test is the scientific core: the two review-arm
templates must be byte-identical outside the explicitly methodology-bearing
sections, so the benchmark comparison isolates the FVK method itself.
"""

import hashlib
import re

import pytest

from fvk_bench import config
from fvk_bench.prompting import render_prompt, template_hashes

#: Sections allowed to differ between fvk.md and control.md (methodology only).
METHODOLOGY_SECTIONS = {"intro-task", "inputs-extra", "no-exec", "tasks", "finish"}

#: Sections that must be byte-identical between fvk.md and control.md.
SHARED_SECTIONS = ("header", "allowed", "forbidden")

#: Instance fields whose values must appear in each arm's rendered prompt.
EXPECTED_FIELDS = {
    "baseline": ("repo", "base_commit"),
    "fvk": ("instance_id", "base_commit"),
    "control": ("instance_id", "base_commit"),
}


def _template_text(arm: str) -> str:
    return (config.PROMPTS_DIR / f"{arm}.md").read_text(encoding="utf-8")


def _parse_sections(text: str) -> dict[str, str]:
    """Split template text into an ordered {section_name: body} dict.

    Sections are delimited by ``<!-- SECTION: name -->`` marker lines; the
    marker line itself is not part of any body. Duplicate names are rejected
    so a later section can never silently shadow an earlier one.
    """
    marker = re.compile(r"<!-- SECTION: ([a-z-]+) -->\n?")
    sections: dict[str, str] = {}
    name: str | None = None
    buf: list[str] = []
    n_markers = 0
    for line in text.splitlines(keepends=True):
        m = marker.fullmatch(line)
        if m:
            n_markers += 1
            if name is not None:
                sections[name] = "".join(buf)
            name = m.group(1)
            buf = []
        else:
            buf.append(line)
    if name is not None:
        sections[name] = "".join(buf)
    assert n_markers == len(sections), "duplicate section names in template"
    return sections


@pytest.mark.parametrize("arm", config.ARMS)
def test_render_substitutes_all_placeholders(arm, fixture_instance):
    out = render_prompt(arm, fixture_instance)
    for field in EXPECTED_FIELDS[arm]:
        assert getattr(fixture_instance, field) in out
    assert re.search(r"\{[a-z_]+\}", out) is None


def test_fvk_control_parity():
    fvk = _parse_sections(_template_text("fvk"))
    control = _parse_sections(_template_text("control"))

    assert list(fvk) == list(control), "section-name sequences differ"
    assert set(SHARED_SECTIONS) <= set(fvk)

    for name in fvk:
        if name not in METHODOLOGY_SECTIONS:
            assert fvk[name] == control[name], f"non-methodology section {name!r} differs"
    for name in SHARED_SECTIONS:
        assert fvk[name] == control[name], f"shared section {name!r} differs"


@pytest.mark.parametrize("arm", config.ARMS)
def test_no_leakage_terms(arm):
    text = _template_text(arm).lower()
    for term in ("fail_to_pass", "pass_to_pass", "resolved", "gold", "test_patch", "score"):
        assert term not in text, f"leakage term {term!r} found in {arm}.md"


def test_baseline_mentions_no_review_arms():
    text = _template_text("baseline").lower()
    for term in ("fvk", "review/", "findings", "control"):
        assert term not in text, f"baseline.md anticipates review arms via {term!r}"


def test_template_hashes_stable():
    hashes = template_hashes()
    assert set(hashes) == {"baseline", "fvk", "control"}
    for arm, digest in hashes.items():
        assert re.fullmatch(r"[0-9a-f]{64}", digest)
        expected = hashlib.sha256(
            (config.PROMPTS_DIR / f"{arm}.md").read_bytes()
        ).hexdigest()
        assert digest == expected, f"hash for {arm} is not sha256 of file bytes"
    assert template_hashes() == hashes


def test_render_rejects_unknown_arm(fixture_instance):
    with pytest.raises((KeyError, FileNotFoundError)):
        render_prompt("nonexistent", fixture_instance)
