#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
source "$ROOT_DIR/../.venv/bin/activate"
source "$ROOT_DIR/env"

CHECKPOINT_PATH="${1:-$ROOT_DIR/outputs/train/smolvla/checkpoints/075000/pretrained_model}"
if [ -d "$CHECKPOINT_PATH/pretrained_model" ]; then
  CHECKPOINT_PATH="$CHECKPOINT_PATH/pretrained_model"
fi

if [ ! -d "$CHECKPOINT_PATH" ]; then
  echo "ERROR: Checkpoint path not found: $CHECKPOINT_PATH" >&2
  exit 1
fi

EVAL_DATASET=witsense-ai/rollout_eval_smolvla
ROBOT_CAMERAS='{top: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video4, width: 640, height: 480, fps: 30}}'

echo "Recording SmolVLA rollout to $EVAL_DATASET using checkpoint: $CHECKPOINT_PATH"

lerobot-rollout \
  --strategy.type=sentry \
  --policy.path="$CHECKPOINT_PATH" \
  --inference.type=rtc \
  --inference.rtc.execution_horizon=10 \
  --inference.rtc.max_guidance_weight=10.0 \
  --robot.type=so101_follower \
  --robot.port="$ROBOT_FOLLOWER_PORT" \
  --robot.id=left_follower \
  --robot.cameras="$ROBOT_CAMERAS" \
  --dataset.repo_id="$EVAL_DATASET" \
  --dataset.single_task="pickup the ring and place it on the toy" \
  --dataset.num_episodes=10 \
  --dataset.episode_time_s=30 \
  --dataset.push_to_hub=true \
  --dataset.camera_encoder.vcodec=h264 \
  --dataset.camera_encoder.preset=fast \
  --dataset.streaming_encoding=true \
  --play_sounds=false

echo "✓ Done: $EVAL_DATASET"
