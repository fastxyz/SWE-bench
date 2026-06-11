#!/usr/bin/env python
"""gen_prompts.py <preset>

Offline, two-stage AI generation of a per-instance augmented dataset for a `mode: per-instance`
preset. Run this BEFORE run.sh.

  Stage 1  select : an AI picks the k most relevant solved issues from the subset pool
                    (the whole config subset MINUS the test slice, to avoid grading-set leakage).
  Stage 2  generate: an AI folds those examples (issue + gold patch) into the methodology
                    skeleton and writes a tailored guidance prompt for each task.
  Assemble        : each task's generated prompt is appended to its problem_statement and the
                    result is written as a local HF dataset that run.sh feeds to the agent.

Outputs (all under experiments/data/<preset>/, gitignored):
  references.yaml        what the selector picked per task (inspect / hand-edit / rerun)
  prompts/<id>.md        the generated guidance per task (inspect / hand-edit)
  test.parquet           the augmented dataset (load_dataset(dir, split="test"))

The API key is read the same way run.sh reads it and is passed to litellm in memory only —
never written into any output file.
"""

import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import litellm
import yaml
from datasets import Dataset, load_dataset

HERE = Path(__file__).resolve().parent  # .../experiments
SWE = HERE.parent  # repo root

DATASET_MAPPING = {
    "verified": "princeton-nlp/SWE-bench_Verified",
    "lite": "princeton-nlp/SWE-bench_Lite",
    "full": "princeton-nlp/SWE-bench",
}

ISSUE_TRIM_CHARS = 1500
PATCH_TRIM_LINES = 80
SUMMARY_CHARS = 200

SELECT_SYSTEM = (
    "You select demonstration examples for a program-repair system. Given a target GitHub issue "
    "and a numbered list of candidate solved issues, choose the {k} candidates whose root cause, "
    "subsystem, or fix shape most plausibly transfers to the target. Respond with ONLY a JSON "
    "array of the chosen candidate instance_ids, most relevant first, no prose."
)

GEN_SYSTEM = (
    "You prepare guidance for an autonomous program-repair agent that will fix a GitHub issue. "
    "You are given a methodology skeleton, the target issue, and several solved examples "
    "(issue + the exact gold patch that fixed each). Produce the guidance text that will be "
    "appended to the agent's task. It must: (1) briefly state how to use the examples, grounded "
    "in the skeleton; (2) for each example, analyze how it relates to the target and what fix "
    "shape transfers; (3) include each example's issue summary and its gold patch verbatim in a "
    "```diff block. Do NOT solve the target issue yourself and do NOT propose a patch for it — "
    "the agent does that. Output only the guidance text (Markdown), nothing else."
)


def fail(msg: str) -> None:
    print(f"gen_prompts: {msg}", file=sys.stderr)
    sys.exit(1)


def resolve_key(ref: str) -> str:
    """Mirror run.sh: api_key: env:NAME -> $NAME, falling back to experiments/.env. Literal -> as-is."""
    import os

    if not ref:
        return ""
    if not ref.startswith("env:"):
        return ref
    name = ref[len("env:") :]
    val = os.environ.get(name, "")
    if val:
        return val
    envfile = HERE / ".env"
    if envfile.exists():
        for line in envfile.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                if k.strip() == name:
                    return v.strip().strip('"').strip("'")
    fail(f"api_key references env:{name} but it is unset/empty (checked shell env and experiments/.env)")


def trim_issue(text: str) -> str:
    text = (text or "").strip()
    return text if len(text) <= ISSUE_TRIM_CHARS else text[:ISSUE_TRIM_CHARS] + "\n…(truncated)"


def trim_patch(patch: str) -> str:
    lines = (patch or "").splitlines()
    if len(lines) <= PATCH_TRIM_LINES:
        return "\n".join(lines)
    return "\n".join(lines[:PATCH_TRIM_LINES]) + f"\n…(truncated, {len(lines) - PATCH_TRIM_LINES} more lines)"


def summary(text: str) -> str:
    return " ".join((text or "").split())[:SUMMARY_CHARS]


def gold_files(patch: str) -> set[str]:
    return set(re.findall(r"^\+\+\+ b/(.+)$", patch or "", re.M))


def llm(model: str, api_base: str, api_key: str, system: str, user: str) -> str:
    kwargs = {"model": model, "temperature": 0.0, "drop_params": True,
              "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]}
    if api_base:
        kwargs["api_base"] = api_base
    if api_key:
        kwargs["api_key"] = api_key
    resp = litellm.completion(**kwargs)
    return resp.choices[0].message.content or ""


def parse_ids(raw: str, valid: set[str], k: int) -> list[str]:
    m = re.search(r"\[.*\]", raw, re.S)
    ids = []
    if m:
        try:
            ids = [str(x) for x in json.loads(m.group(0))]
        except json.JSONDecodeError:
            ids = []
    if not ids:  # fallback: scrape any known id mentioned in the reply
        ids = [c for c in valid if c in raw]
    seen, out = set(), []
    for i in ids:
        if i in valid and i not in seen:  # valid drops test-slice ids -> leakage backstop
            seen.add(i)
            out.append(i)
    return out[:k]


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: gen_prompts.py <preset>")
    preset = sys.argv[1]
    pdir = HERE / "presets" / preset
    cfg_path = pdir / "config.yaml"
    skel_path = pdir / "skeleton.md"
    if not cfg_path.exists():
        fail(f"missing {cfg_path}")
    if not skel_path.exists():
        fail(f"missing {skel_path}")

    cfg = yaml.safe_load(cfg_path.read_text()) or {}
    if cfg.get("mode") != "jointembed":
        fail(f"preset {preset} is mode={cfg.get('mode')!r}, gen_prompts only applies to mode: jointembed")
    model = cfg.get("model", "deepseek/deepseek-v4-pro")
    api_base = cfg.get("api_base", "")
    api_key = resolve_key(cfg.get("api_key", ""))
    subset = cfg.get("subset", "verified")
    split = cfg.get("split", "test")
    slice_spec = str(cfg.get("slice", "0:10"))
    k = int(cfg.get("k", 3))
    workers = int(cfg.get("workers", 4))
    out_dir = HERE / "data" / preset  # always experiments/data/<preset>/; run.sh reads the same
    skeleton = skel_path.read_text().strip()

    dataset_name = DATASET_MAPPING.get(subset, subset)
    print(f"▶ gen preset={preset} model={model} dataset={dataset_name} slice={slice_spec} k={k}")
    instances = list(load_dataset(dataset_name, split=split))  # original order, mirrors runner (shuffle=False)
    sl = [int(x) if x else None for x in slice_spec.split(":")]
    test = instances[slice(*sl)]
    test_ids = {t["instance_id"] for t in test}
    corpus = [i for i in instances if i["instance_id"] not in test_ids]  # subset minus the whole test slice
    corpus_by_id = {c["instance_id"]: c for c in corpus}
    valid_ids = set(corpus_by_id)
    print(f"  test={len(test)} instances, candidate pool={len(corpus)} (subset minus test slice)")

    catalog = "\n".join(
        f"{n}. {c['instance_id']} [{c['repo']}] {summary(c['problem_statement'])}"
        for n, c in enumerate(corpus, 1)
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    prompts_dir = out_dir / "prompts"
    prompts_dir.mkdir(exist_ok=True)

    def process_one(t: dict) -> tuple[str, list[str], str]:
        """Stage 1+2 for one task. Pure (no shared writes) so it parallelizes safely."""
        tid = t["instance_id"]
        target_issue = trim_issue(t["problem_statement"])
        sel_user = (
            f"TARGET ISSUE ({tid}):\n{target_issue}\n\n"
            f"CANDIDATES:\n{catalog}\n\n"
            f"Choose the {k} most relevant candidate instance_ids as a JSON array."
        )
        chosen = parse_ids(llm(model, api_base, api_key, SELECT_SYSTEM.format(k=k), sel_user), valid_ids, k)
        examples = "\n\n".join(
            f"### Example {n}: {cid} [{corpus_by_id[cid]['repo']}]\n"
            f"Issue:\n{trim_issue(corpus_by_id[cid]['problem_statement'])}\n\n"
            f"Gold patch:\n```diff\n{trim_patch(corpus_by_id[cid]['patch'])}\n```"
            for n, cid in enumerate(chosen, 1)
        )
        gen_user = (
            f"METHODOLOGY SKELETON:\n{skeleton}\n\n"
            f"TARGET ISSUE ({tid}):\n{target_issue}\n\n"
            f"SOLVED EXAMPLES:\n{examples}"
        )
        guidance = llm(model, api_base, api_key, GEN_SYSTEM, gen_user).strip()
        return tid, chosen, guidance

    results = {}
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(process_one, t): t["instance_id"] for t in test}
        for fut in as_completed(futs):
            tid = futs[fut]
            try:
                tid, chosen, guidance = fut.result()
                results[tid] = (chosen, guidance)
                print(f"  {tid}: selected {chosen or '(none)'}")
            except Exception as e:  # one task failing shouldn't waste the others' calls
                print(f"  {tid}: FAILED ({type(e).__name__}: {e}) — skipped, rerun to fill")

    references, augmented, sentinel_hits = {}, [], []
    for t in test:  # assemble in test order; skip any task that failed
        tid = t["instance_id"]
        if tid not in results:
            continue
        chosen, guidance = results[tid]
        references[tid] = chosen
        (prompts_dir / f"{tid}.md").write_text(guidance + "\n")
        rec = dict(t)
        rec["problem_statement"] = t["problem_statement"].rstrip() + "\n\n---\n\n" + guidance
        augmented.append(rec)
        tgt_files = gold_files(t["patch"])
        for cid in chosen:
            shared = tgt_files & gold_files(corpus_by_id[cid]["patch"])
            if shared:
                sentinel_hits.append((tid, cid, sorted(shared)))

    if not augmented:
        fail("no tasks succeeded — nothing written; check API key/endpoint and rerun")
    (out_dir / "references.yaml").write_text(yaml.safe_dump(references, sort_keys=False, allow_unicode=True))
    Dataset.from_list(augmented).to_parquet(str(out_dir / "test.parquet"))

    print(f"\n✓ wrote {out_dir.relative_to(SWE)}/ : references.yaml, prompts/, test.parquet ({len(augmented)} instances)")
    print("\n── leakage sentinel (selected example shares a gold-patch file with its target) ──")
    if not sentinel_hits:
        print("  clean: no selected example shares a gold file with its target")
    else:
        for tid, cid, files in sentinel_hits:
            print(f"  ‼️ {tid} ← {cid} share gold file(s): {files}")
        print("  → these targets carry a same-file-gold asterisk; inspect references.yaml / prompts before trusting them")


if __name__ == "__main__":
    main()
