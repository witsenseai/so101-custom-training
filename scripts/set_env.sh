# .env.example — copy to .env and fill in values
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