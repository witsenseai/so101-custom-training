#!/usr/bin/env bash
set -euo pipefail

# upload_policy.sh
# Push the latest policy model checkpoint to the Hugging Face Hub.
# Requires HF_TOKEN in the environment or in .env.
# Usage: ./upload_policy.sh [JOB_NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
elif [ -f "$SCRIPT_DIR/set_env.sh" ]; then
  source "$SCRIPT_DIR/set_env.sh"
elif [ -f "$SCRIPT_DIR/env" ]; then
  source "$SCRIPT_DIR/env"
else
  echo "ERROR: No env file found. Expected $SCRIPT_DIR/.env or $SCRIPT_DIR/set_env.sh." >&2
  exit 1
fi

JOB_NAME="${1:-${JOB_NAME:-}}"
POLICY_REPO="${POLICY_REPO:-}"

if [ -z "${HF_TOKEN:-}" ] && [ -z "${HF_HUB_TOKEN:-}" ]; then
  echo "ERROR: HF_TOKEN or HF_HUB_TOKEN is required." >&2
  exit 1
fi

if [ -z "$JOB_NAME" ]; then
  echo "ERROR: JOB_NAME is not set. Set JOB_NAME in env or pass it as the first argument." >&2
  exit 1
fi

if [ -z "$POLICY_REPO" ]; then
  echo "ERROR: POLICY_REPO is not set in env." >&2
  exit 1
fi

MODEL_DIR="$SCRIPT_DIR/../outputs/train/${JOB_NAME}/checkpoints/last/pretrained_model"
PY_SCRIPT="$ROOT_DIR/scripts/push_model_to_hf.py"

if [ ! -d "$MODEL_DIR" ]; then
  echo "ERROR: Model directory not found: $MODEL_DIR" >&2
  exit 2
fi

python "$PY_SCRIPT" \
  --path "$MODEL_DIR" \
  --repo-id "$POLICY_REPO" \
  --token "${HF_TOKEN:-${HF_HUB_TOKEN}}" \
  --message "Upload policy model checkpoint"
