"""Agent-runner seam: lets the 3-arm benchmark drive a second agent (Codex)
alongside Claude without :mod:`fvk_bench.arms` ever touching a CLI directly.

:class:`AgentRunner` is the interface every backend implements;
:func:`get_runner` maps an agent name to its concrete runner;
:data:`AgentResult` is the shared per-session outcome (the ``ClaudeResult``
dataclass, re-exported so both backends speak one shape).

A runner owns three agent-specific facts the orchestrator must not know:
- whether a session id can be chosen up front (``new_session_id`` returns a
  pre-known id for Claude's ``--session-id``; ``None`` for Codex, which assigns
  its own and reveals it only in the result),
- how a fresh session and a fork-from-baseline are launched, and
- where the session transcript lands and how to audit it.
"""

from __future__ import annotations

from pathlib import Path
from typing import Protocol, runtime_checkable

from fvk_bench import config
from fvk_bench.claude_runner import ClaudeResult as AgentResult  # one shared shape

__all__ = ["AgentRunner", "AgentResult", "get_runner"]


@runtime_checkable
class AgentRunner(Protocol):
    """What :mod:`fvk_bench.arms` needs from any agent backend."""

    name: str

    def new_session_id(self) -> str | None:
        """A pre-known session id, or ``None`` if the agent assigns its own."""

    def run_fresh(
        self,
        ws: Path,
        arm: str,
        prompt: str,
        *,
        session_id: str | None = None,
        timeout: int = config.ARM_TIMEOUT_SECONDS,
        max_turns: int | None = None,
    ) -> AgentResult:
        """Run a fresh (baseline) session."""

    def run_fork(
        self,
        ws: Path,
        arm: str,
        prompt: str,
        baseline_session_id: str,
        *,
        timeout: int = config.ARM_TIMEOUT_SECONDS,
        max_turns: int | None = None,
    ) -> AgentResult:
        """Run a session that forks from the frozen baseline session.

        Both review arms call this with the same ``baseline_session_id`` and
        must each start from an *unmodified* baseline context — independence is
        the backend's responsibility (Claude: ``--fork-session``; Codex: see
        :mod:`fvk_bench.codex_runner`)."""

    def transcript_path(self, ws: Path, session_id: str) -> Path | None:
        """Locate the session transcript for ``session_id`` (or ``None``)."""

    def audit_transcript(self, path: Path) -> dict:
        """Audit a transcript for tool-surface / execution cleanliness."""

    def version(self) -> str | None:
        """The agent CLI version string (``None`` if it can't be determined)."""


def get_runner(agent: str = config.DEFAULT_AGENT, **kwargs) -> AgentRunner:
    """Return the concrete runner for ``agent``.

    Backends are imported lazily so selecting ``claude`` never imports the
    codex backend and vice versa. ``model=None`` resolves to the agent's pinned
    default. Recognised kwargs: ``claude_bin``/``codex_bin``, ``model``.

    Raises:
        ValueError: if ``agent`` is not one of :data:`fvk_bench.config.AGENTS`.
    """
    model = kwargs.get("model")
    if agent == "claude":
        from fvk_bench.claude_runner import ClaudeRunner

        return ClaudeRunner(
            claude_bin=kwargs.get("claude_bin", "claude"),
            model=model or config.MODEL,
        )
    if agent == "codex":
        from fvk_bench.codex_runner import CodexRunner

        return CodexRunner(
            codex_bin=kwargs.get("codex_bin", "codex"),
            model=model or config.CODEX_MODEL,
        )
    raise ValueError(f"unknown agent {agent!r}; expected one of {config.AGENTS}")
