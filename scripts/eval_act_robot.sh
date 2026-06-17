#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
source "$ROOT_DIR/../.venv/bin/activate"
source "$ROOT_DIR/env"

POLICY_PATH="${1:-witsense-ai/so101_act_fewshot}"
EVAL_DATASET=witsense-ai/rollout_eval_act
ROBOT_CAMERAS='{top: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video4, width: 640, height: 480, fps: 30}}'

echo "Policy:  $POLICY_PATH"
echo "Dataset: $EVAL_DATASET"
echo ""

lerobot-rollout \
  --strategy.type=sentry \
  --policy.path="$POLICY_PATH" \
  --inference.type=sync \
  --robot.type=so101_follower \
  --robot.port="$ROBOT_FOLLOWER_PORT" \
  --robot.id=left_follower \
  --robot.cameras="$ROBOT_CAMERAS" \
  --fps=30 \
  --dataset.repo_id="$EVAL_DATASET" \
  --dataset.single_task="pickup the ring and place it on the toy" \
  --dataset.num_episodes=10 \
  --dataset.episode_time_s=25 \
  --dataset.push_to_hub=false \
  --dataset.camera_encoder.vcodec=h264 \
  --dataset.camera_encoder.preset=fast \
  --dataset.streaming_encoding=true \
  --play_sounds=true

echo ""
echo "✓ Done: $EVAL_DATASET"
