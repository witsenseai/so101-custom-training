#!/bin/bash
# eval.sh
source ~/lerobot-env/bin/activate
source .env

sudo ip addr add 192.168.10.3/24 dev enP8p1s0 2>/dev/null || true

echo "Running policy: ${POLICY_REPO}"
echo "Saving eval dataset to: ${HF_USER}/eval_${TASK_NAME}"

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$ROBOT_FOLLOWER_PORT \
  --robot.id=left_follower \
  --robot.cameras="{top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video3, width: 640, height: 480, fps: 30}}" \
  --display_data=false \
  --dataset.repo_id=${HF_USER}/eval_${TASK_NAME} \
  --dataset.single_task="${TASK_DESC}" \
  --dataset.num_episodes=10 \
  --dataset.episode_time_s=30 \
  --dataset.push_to_hub=true \
  --dataset.vcodec=h264 \
  --dataset.streaming_encoding=true \
  --play_sounds=false \
  --policy.path=${POLICY_REPO}