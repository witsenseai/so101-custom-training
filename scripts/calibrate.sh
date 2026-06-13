#!/bin/bash
source ~/ws/lerobot/.venv/bin/activate
export HF_TOKEN=your_token_here
export HF_USER=witsense-ai
export ROBOT_LEADER_PORT=/dev/ttyACM0
export ROBOT_FOLLOWER_PORT=/dev/ttyACM1
export TASK_NAME=tidyup-place
export TASK_DESC="pickup the object and place it in the cup"
export DATASET_REPO=${HF_USER}/so101_${TASK_NAME}
export POLICY_REPO=${HF_USER}/so101_${TASK_NAME}_policy
export PRETRAINED_CKPT=${HF_USER}/so101_${TASK_NAME}_pi_fast
export TRAIN_OUTPUT_DIR=${HF_USER}/so101_${TASK_NAME}_train
export HF_LEROBOT_HOME=/home/suva/ws/lerobot/so101-custom-training
export JOB_NAME=act_so101_${TASK_NAME}
export DISPLAY=localhost:0.0
echo "Starting calibration for task: $TASK_NAME"
echo "Task description: $TASK_DESC"
echo "Using dataset repo: $DATASET_REPO"
echo "Using policy repo: $POLICY_REPO"
echo "Using pretrained checkpoint: $PRETRAINED_CKPT"    
echo "Using leader port: $ROBOT_LEADER_PORT"
echo "Using follower port: $ROBOT_FOLLOWER_PORT"
echo "Calibrating leader arm (right_leader) on $ROBOT_LEADER_PORT..."
lerobot-calibrate \
  --teleop.type=so101_leader \
  --teleop.port=$ROBOT_LEADER_PORT \
  --teleop.id=right_leader

echo "Calibrating follower arm (left_follower) on $ROBOT_FOLLOWER_PORT..."
lerobot-calibrate \
  --robot.type=so101_follower \
  --robot.port=$ROBOT_FOLLOWER_PORT \
  --robot.id=left_follower

echo "Backing up calibration..."
cp -r ~/.cache/huggingface/lerobot/ ~/lerobot-calibration-backup/
echo "Backup saved to ~/lerobot-calibration-backup/"