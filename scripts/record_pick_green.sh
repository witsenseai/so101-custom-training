#!/bin/bash
source ~/ws/lerobot/.venv/bin/activate
export HF_TOKEN=your_token_here
export HF_USER=witsense-ai
export ROBOT_LEADER_PORT=/dev/ttyACM0
export ROBOT_FOLLOWER_PORT=/dev/ttyACM1
export TASK_NAME=pick_and_place_ring
export TASK_DESC="pickup the ring and place it on the toy"
export DATASET_REPO=${HF_USER}/so101_${TASK_NAME}
export HF_LEROBOT_HOME=/home/suva/ws/lerobot/so101-custom-training
export DISPLAY=:1
echo "Starting recording for task: $TASK_NAME"
lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$ROBOT_FOLLOWER_PORT \
  --robot.id=left_follower \
  --robot.cameras="{top: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video4, width: 640, height: 480, fps: 30}}" \
  --teleop.type=so101_leader \
  --teleop.port=$ROBOT_LEADER_PORT \
  --teleop.id=right_leader \
  --dataset.repo_id=${DATASET_REPO} \
  --dataset.single_task="${TASK_DESC}" \
  --dataset.num_episodes=15 \
  --dataset.episode_time_s=30 \
  --dataset.reset_time_s=10 \
  --dataset.push_to_hub=false \
  --dataset.camera_encoder.vcodec=h264 \
  --dataset.streaming_encoding=true \
  --display_data=false 