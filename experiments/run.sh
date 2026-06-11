#!/usr/bin/env bash
# Run one SWE-bench prompt experiment.
#
#   ./run.sh <preset>
#
# A preset is a folder under experiments/presets/<preset>/ containing:
#   prompt.md    - the system prompt injected into the agent
#   config.yaml  - model + run params (model / subset / split / slice / workers)
#
# Runs the agent with that prompt, grades the patches, and writes everything to
# experiments/results/<preset>/. Heavy step — run it yourself.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"     # .../SWE-bench/experiments
SWE="$(cd "$HERE/.." && pwd)"             # .../SWE-bench
PY="$SWE/.venv/bin/python"
cd "$SWE"

PRESET="${1:-}"
if [[ -z "$PRESET" ]]; then
  echo "usage: ./run.sh <preset>   (available: $(ls "$HERE/presets" 2>/dev/null | tr '\n' ' '))"
  exit 1
fi
PDIR="$HERE/presets/$PRESET"
[[ -f "$PDIR/config.yaml" ]] || { echo "missing $PDIR/config.yaml"; exit 1; }
# prompt.md is required only for inject/replace; per-instance presets use a pre-generated
# dataset instead — checked after MODE is read below.

# --- read config.yaml ---
eval "$("$PY" - "$PDIR/config.yaml" <<'PYEOF'
import sys, yaml
c = yaml.safe_load(open(sys.argv[1])) or {}
print(f"MODEL={c.get('model','deepseek/deepseek-v4-pro')}")
print(f"SUBSET={c.get('subset','verified')}")
print(f"SPLIT={c.get('split','test')}")
print(f"SLICE={c.get('slice','0:10')}")
print(f"WORKERS={c.get('workers',4)}")
print(f"MODE={c.get('mode','inject')}")
print(f"API_BASE={c.get('api_base','')}")
print(f"API_KEY_REF={c.get('api_key','')}")
PYEOF
)"

# jointembed presets read/write their augmented dataset here (relative to repo root = agent cwd)
DATADIR="experiments/data/$PRESET"

# --- per-mode preconditions ---
#   inject/replace -> need prompt.md
#   jointembed     -> need the pre-generated augmented dataset (run gen_prompts.py first)
if [[ "$MODE" == "jointembed" ]]; then
  [[ -f "$SWE/$DATADIR/test.parquet" ]] || {
    echo "augmented dataset missing at $DATADIR — run first:  experiments/gen_prompts.py $PRESET"; exit 1; }
else
  [[ -f "$PDIR/prompt.md" ]] || { echo "missing $PDIR/prompt.md"; exit 1; }
fi

# --- resolve API key without ever writing it to disk ---
#   config api_key: env:NAME  -> read $NAME (shell env, falling back to experiments/.env)
#   config api_key: <literal> -> used as-is (not recommended; keep secrets out of files)
#   omitted                   -> rely on litellm's provider default env var (e.g. DEEPSEEK_API_KEY)
APIKEY=""
if [[ -n "$API_KEY_REF" ]]; then
  if [[ "$API_KEY_REF" == env:* ]]; then
    VARNAME="${API_KEY_REF#env:}"
    APIKEY="${!VARNAME:-}"
    if [[ -z "$APIKEY" && -f "$HERE/.env" ]]; then
      APIKEY="$("$PY" - "$VARNAME" "$HERE/.env" <<'PYEOF'
import sys
name, envpath = sys.argv[1], sys.argv[2]
val = ""
for line in open(envpath):
    line = line.strip()
    if line and not line.startswith("#") and "=" in line:
        k, v = line.split("=", 1)
        if k.strip() == name:
            val = v.strip().strip('"').strip("'")
print(val)
PYEOF
)"
    fi
    [[ -n "$APIKEY" ]] || { echo "api_key references env:$VARNAME but it is unset/empty (checked shell env and experiments/.env)"; exit 1; }
  else
    APIKEY="$API_KEY_REF"
  fi
fi

# api_base is not secret -> fine via model_kwargs. The API key must NOT go through model_kwargs:
# mini serializes the whole model config into every trajectory file, which would leak the key.
# Export it as the provider's env var instead; litellm reads it from the environment and never logs it.
MK_ARGS=()
[[ -n "$API_BASE" ]] && MK_ARGS+=(-c "model.model_kwargs.api_base=$API_BASE")
if [[ -n "$APIKEY" ]]; then
  PROVIDER_ENV="$(printf '%s' "${MODEL%%/*}" | tr '[:lower:]-' '[:upper:]_')_API_KEY"
  export "$PROVIDER_ENV"="$APIKEY"
fi

case "$SUBSET" in
  verified) DATASET="princeton-nlp/SWE-bench_Verified";;
  lite)     DATASET="princeton-nlp/SWE-bench_Lite";;
  *)        DATASET="princeton-nlp/SWE-bench";;
esac

OUT="$HERE/results/$PRESET"
mkdir -p "$OUT/trajectories"

# --- build the agent input + system prompt per mode ---
#   inject  (default) -> append prompt.md AFTER the default system prompt; agent reads $SUBSET
#   replace           -> prompt.md becomes the whole system prompt;        agent reads $SUBSET
#   jointembed        -> default system prompt; agent reads the augmented local dataset
#                        ($DATADIR) whose per-task problem_statement already carries the prompt
OVERLAY_ARGS=()
if [[ "$MODE" == "jointembed" ]]; then
  AGENT_SUBSET="$DATADIR"
else
  AGENT_SUBSET="$SUBSET"
  SWEBENCH_YAML="$(ls "$SWE"/.venv/lib/python*/site-packages/minisweagent/config/benchmarks/swebench.yaml 2>/dev/null | head -1)"
  OVERLAY="$OUT/_system.yaml"
  "$PY" - "$MODE" "$SWEBENCH_YAML" "$PDIR/prompt.md" "$OVERLAY" <<'PYEOF'
import sys, yaml
mode, base_yaml, prompt_md, out = sys.argv[1:5]
inj = open(prompt_md).read().strip()
if mode == "replace":
    final = inj
else:  # inject: default system prompt + your addition
    base = (yaml.safe_load(open(base_yaml)) or {}).get("agent", {}).get("system_template", "")
    final = base.rstrip() + ("\n\n" + inj if inj else "")
yaml.safe_dump({"agent": {"system_template": final}}, open(out, "w"),
               sort_keys=False, default_flow_style=False, allow_unicode=True)
PYEOF
  OVERLAY_ARGS=(-c "$OVERLAY")
fi

MODEL_FILE="${MODEL//\//__}"
echo "▶ preset=$PRESET  model=$MODEL  dataset=$DATASET  agent_input=$AGENT_SUBSET  slice=$SLICE  workers=$WORKERS  mode=$MODE"

# --- 1) agent run (always fresh for this preset) ---
MSWEA_COST_TRACKING=ignore_errors "$PY" -m minisweagent.run.benchmarks.swebench \
  -m "$MODEL" --subset "$AGENT_SUBSET" --split "$SPLIT" --slice "$SLICE" --redo-existing \
  -c swebench.yaml ${OVERLAY_ARGS[@]+"${OVERLAY_ARGS[@]}"} ${MK_ARGS[@]+"${MK_ARGS[@]}"} \
  -w "$WORKERS" -o "$OUT" || { echo "agent run failed"; exit 1; }

[[ -f "$OUT/preds.json" ]] || { echo "no preds.json produced"; exit 1; }
IDS=$("$PY" -c "import json;print(' '.join(json.load(open('$OUT/preds.json')).keys()))")

# --- 2) grade ---
"$PY" -m swebench.harness.run_evaluation \
  --dataset_name "$DATASET" --predictions_path "$OUT/preds.json" --instance_ids $IDS \
  --max_workers "$WORKERS" --run_id "$PRESET" --cache_level instance || { echo "grading failed"; exit 1; }

REPORT="$SWE/${MODEL_FILE}.${PRESET}.json"
[[ -f "$REPORT" ]] && cp "$REPORT" "$OUT/report.json"

# --- 3) tidy: collect trajectories, drop mini's per-instance dirs, write meta ---
mv "$OUT"/*/*.traj.json "$OUT/trajectories/" 2>/dev/null
find "$OUT" -mindepth 1 -maxdepth 1 -type d ! -name trajectories -exec rm -rf {} + 2>/dev/null

if [[ -f "$OUT/report.json" ]]; then
  "$PY" - "$OUT/report.json" "$PRESET" "$MODEL" "$DATASET" "$SLICE" "$OUT/meta.yaml" <<'PYEOF'
import sys, json, yaml
rep, preset, model, dataset, slc, outp = sys.argv[1:7]
r = json.load(open(rep))
yaml.safe_dump(dict(preset=preset, model=model, dataset=dataset, slice=slc,
                    resolved=r['resolved_instances'], total=r['total_instances'],
                    resolved_ids=r['resolved_ids'], unresolved_ids=r['unresolved_ids']),
               open(outp, 'w'), sort_keys=False)
print("──────────")
print(f"{preset}: {r['resolved_instances']}/{r['total_instances']} resolved")
print("  resolved:  ", *r['resolved_ids'])
print("  unresolved:", *r['unresolved_ids'])
PYEOF
fi
echo "results → experiments/results/$PRESET/"
