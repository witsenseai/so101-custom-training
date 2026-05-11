#!/bin/bash
source ~/lerobot-env/bin/activate
source .env

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