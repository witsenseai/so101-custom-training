#!/bin/bash
set -euo pipefail

source ~/ws/lerobot/.venv/bin/activate

HF_TOKEN="${HF_TOKEN:-}"
HF_USER=witsense-ai
ROBOT_LEADER_PORT="${ROBOT_LEADER_PORT:-/dev/ttyACM0}"
ROBOT_FOLLOWER_PORT="${ROBOT_FOLLOWER_PORT:-/dev/ttyACM1}"
TASK_NAME=pick_and_place_ring
TASK_DESC="pickup the ring and place it on the toy"
DATASET_REPO=${HF_USER}/so101_${TASK_NAME}
export HF_LEROBOT_HOME=/home/suva/ws/lerobot/so101-custom-training
export DISPLAY=:1

EPISODES="${1:-50}"

echo "Task:     $TASK_DESC"
echo "Dataset:  $DATASET_REPO"
echo "Episodes: $EPISODES"
echo ""

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$ROBOT_FOLLOWER_PORT \
  --robot.id=left_follower \
  --robot.cameras="{
    top:   {type: opencv, index_or_path: /dev/video2, width: 1280, height: 720, fps: 30},
    wrist: {type: opencv, index_or_path: /dev/video4, width: 640,  height: 480, fps: 30}
  }" \
  --teleop.type=so101_leader \
  --teleop.port=$ROBOT_LEADER_PORT \
  --teleop.id=right_leader \
  --dataset.repo_id=${DATASET_REPO} \
  --dataset.single_task="${TASK_DESC}" \
  --dataset.num_episodes=$EPISODES \
  --dataset.episode_time_s=25 \
  --dataset.reset_time_s=15 \
  --dataset.push_to_hub=false \
  --dataset.camera_encoder.vcodec=h264 \
  --dataset.camera_encoder.crf=23 \
  --dataset.camera_encoder.preset=fast \
  --dataset.streaming_encoding=true \
  --display_data=true \
  --play_sounds=true

echo ""
echo "Done. Episodes saved to $HF_LEROBOT_HOME/$DATASET_REPO"
echo "Push to Hub: HF_TOKEN=\$HF_TOKEN lerobot-push-dataset --repo-id $DATASET_REPO"
