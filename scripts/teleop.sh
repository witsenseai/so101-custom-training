#!/bin/bash
source ~/lerobot-env/bin/activate
source .env

echo "Teleoperation mode. Use Ctrl+C to stop."

lerobot-teleoperate   --robot.type=so101_follower   --robot.port=$ROBOT_FOLLOWER_PORT   --robot.id=left_follower   --teleop.type=so101_leader   --teleop.port=  --teleop.port=$ROBOT_LEADER_PORT   --teleop.id=right_leader   --robot.cameras="{top: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30}, wrist: {type: opencv, index_or_path: /dev/video3, width: 640, height: 480, fps: 30}}"   --display_data=false
