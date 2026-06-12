#!/usr/bin/env python3
"""Stand-in for the real `claude` CLI used by the fvk_bench test suite.

The test conftest copies this file into a temp bin directory as ``claude``.
Behavior is selected by environment variables so tests can exercise every
runner code path without a real CLI, network, or subscription:

``FAKE_CLAUDE_SCENARIO``
    ``ok`` (default)
        Writes ``fake_claude_capture.json`` into the CWD (argv, env, cwd —
        lets tests assert exactly what the runner passed), optionally exec()s
        the python file named by ``FAKE_CLAUDE_EDITS`` (workspace edits for
        later task suites), then prints a success result envelope.
    ``slow``
        Sleeps 30s then exits 0 (for timeout/kill tests).
    ``badjson``
        Prints a non-JSON line and exits 0.
    ``exit2``
        Prints an error result envelope to stdout, "boom" to stderr, exits 2.

``FAKE_CLAUDE_SESSION_ID``
    Session id to echo in the ``ok`` envelope when no ``--session-id`` is in
    argv. Like the real CLI, an argv ``--session-id`` value always wins; with
    neither, a random ``fake-<8 hex>`` id is invented.

In ALL scenarios a marker line ``FAKE_CLAUDE_INVOKED <argv>`` is appended to
``fake_claude_invocations.log`` in the CWD so tests can count invocations.
"""

import json
import os
import sys
import time
import uuid


def main() -> int:
    with open("fake_claude_invocations.log", "a", encoding="utf-8") as log:
        log.write(f"FAKE_CLAUDE_INVOKED {json.dumps(sys.argv)}\n")

    scenario = os.environ.get("FAKE_CLAUDE_SCENARIO", "ok")

    if scenario == "slow":
        time.sleep(30)
        return 0

    if scenario == "badjson":
        print("this is not json")
        return 0

    if scenario == "exit2":
        print(json.dumps({"type": "result", "subtype": "error", "is_error": True}))
        print("boom", file=sys.stderr)
        return 2

    # Default scenario: "ok".
    with open("fake_claude_capture.json", "w", encoding="utf-8") as fh:
        json.dump(
            {"argv": sys.argv, "env": dict(os.environ), "cwd": os.getcwd()},
            fh,
            indent=2,
        )

    edits = os.environ.get("FAKE_CLAUDE_EDITS")
    if edits:
        with open(edits, encoding="utf-8") as fh:
            code = fh.read()
        exec(
            compile(code, edits, "exec"),
            {"__name__": "__fake_claude_edits__", "__file__": edits},
        )

    if "--session-id" in sys.argv:
        session_id = sys.argv[sys.argv.index("--session-id") + 1]
    else:
        session_id = os.environ.get("FAKE_CLAUDE_SESSION_ID") or (
            "fake-" + uuid.uuid4().hex[:8]
        )

    print(
        json.dumps(
            {
                "type": "result",
                "subtype": "success",
                "is_error": False,
                "session_id": session_id,
                "num_turns": 7,
                "usage": {},
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
