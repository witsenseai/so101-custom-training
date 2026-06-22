#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
source "$ROOT_DIR/../.venv/bin/activate"
source "$ROOT_DIR/env"

POLICY_PATH="${1:-witsense-ai/so101_vla_jepa_fewshot_2000}"
EVAL_DATASET=witsense-ai/rollout_eval_vla_jepa
ROBOT_CAMERAS='{exterior_1_left: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30}, exterior_2_left: {type: opencv, index_or_path: /dev/video4, width: 640, height: 480, fps: 30}}'

echo "Evaluating VLA-JEPA on SO-101"
echo "   Policy: $POLICY_PATH"
echo "   Dataset: $EVAL_DATASET"
echo ""

lerobot-rollout \
  --strategy.type=episodic \
  --policy.path="$POLICY_PATH" \
  --policy.resize_images_to='[224,224]' \
  --policy.torch_dtype=float16 \
  --inference.type=sync \
  --robot.type=so101_follower \
  --robot.port="$ROBOT_FOLLOWER_PORT" \
  --robot.id=left_follower \
  --robot.cameras="$ROBOT_CAMERAS" \
  --fps=1 \
  --dataset.repo_id="$EVAL_DATASET" \
  --dataset.single_task="pickup the ring and place it on the toy" \
  --dataset.num_episodes=10 \
  --dataset.episode_time_s=30 \
  --dataset.push_to_hub=false \
  --dataset.camera_encoder.vcodec=h264 \
  --dataset.camera_encoder.preset=ultrafast \
  --dataset.streaming_encoding=false \
  --play_sounds=false

echo ""
echo "✓ Evaluation complete: $EVAL_DATASET"
