#!/bin/bash
source ~/lerobot-env/bin/activate
source .env

echo "Dataset: ${DATASET_REPO}"
echo "Task: ${TASK_DESC}"

sudo ip addr add 192.168.10.3/24 dev enP8p1s0 2>/dev/null || true

# lerobot-find-cameras opencv

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$ROBOT_FOLLOWER_PORT \
  --robot.id=left_follower \
  --robot.cameras="{top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video3, width: 640, height: 480, fps: 30}}" \
  --teleop.type=so101_leader \
  --teleop.port=$ROBOT_LEADER_PORT \
  --teleop.id=right_leader \
  --dataset.repo_id=${DATASET_REPO} \
  --dataset.single_task="${TASK_DESC}" \
  --dataset.num_episodes=1 \
  --dataset.episode_time_s=30 \
  --dataset.reset_time_s=10 \
  --dataset.push_to_hub=true \
  --dataset.vcodec=h264 \
  --dataset.streaming_encoding=true \
  --display_data=false \
  --play_sounds=false \
  --resume=true

  