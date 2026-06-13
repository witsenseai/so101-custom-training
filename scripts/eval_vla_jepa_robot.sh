#!/bin/bash
source ~/ws/lerobot/.venv/bin/activate
source ~/ws/lerobot/so101-custom-training/env
set -e

POLICY=witsense-ai/so101_policy_vla_jepa
EVAL_DATASET=witsense-ai/eval_vla_jepa

echo "Evaluating VLA-JEPA on SO-101 (10 episodes)"

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$ROBOT_FOLLOWER_PORT \
  --robot.id=left_follower \
  --robot.cameras="{top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video3, width: 640, height: 480, fps: 30}}" \
  --display_data=false \
  --dataset.repo_id=$EVAL_DATASET \
  --dataset.single_task="pickup the ring and place it on the toy" \
  --dataset.num_episodes=10 \
  --dataset.episode_time_s=30 \
  --dataset.push_to_hub=true \
  --dataset.vcodec=h264 \
  --play_sounds=false \
  --policy.path=$POLICY

echo "✓ Done: $EVAL_DATASET"
