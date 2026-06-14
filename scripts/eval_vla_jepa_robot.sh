#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
source "$ROOT_DIR/../.venv/bin/activate"
source "$ROOT_DIR/env"

# Use the model trained by train_vla_jepa_fewshot.sh
CHECKPOINT_PATH="${1:-$ROOT_DIR/outputs/train/vla_jepa_fewshot/checkpoints/last/pretrained_model}"
EVAL_DATASET=witsense-ai/eval_vla_jepa_fewshot
ROBOT_CAMERAS='{top: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video4, width: 640, height: 480, fps: 30}}'

if [ ! -d "$CHECKPOINT_PATH" ]; then
  echo "❌ ERROR: Checkpoint path not found: $CHECKPOINT_PATH" >&2
  echo "   Did you run: ./scripts/train_vla_jepa_fewshot.sh" >&2
  exit 1
fi

echo "📊 Evaluating VLA-JEPA Few-Shot on SO-101"
echo "   Policy: $CHECKPOINT_PATH"
echo "   Dataset: $EVAL_DATASET"
echo ""

lerobot-rollout \
  --strategy.type=sentry \
  --policy.path="$CHECKPOINT_PATH" \
  --robot.type=so101_follower \
  --robot.port="$ROBOT_FOLLOWER_PORT" \
  --robot.id=left_follower \
  --robot.calibration_dir="$ROOT_DIR/calibration/robots/so_follower" \
  --robot.cameras="$ROBOT_CAMERAS" \
  --dataset.repo_id="$EVAL_DATASET" \
  --dataset.single_task="pickup the ring and place it on the toy" \
  --dataset.num_episodes=5 \
  --dataset.episode_time_s=30 \
  --dataset.push_to_hub=true \
  --play_sounds=false

echo ""
echo "✓ Evaluation complete: $EVAL_DATASET"
