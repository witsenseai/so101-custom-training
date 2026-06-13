#!/bin/bash
# train.sh
source ~/ws/lerobot/.venv/bin/activate
export HF_TOKEN=your_token_here
export HF_USER=witsense-ai
export ROBOT_LEADER_PORT=/dev/ttyACM0
export ROBOT_FOLLOWER_PORT=/dev/ttyACM1
export TASK_NAME=pick_and_place_ring
export TASK_DESC="pickup the ring and place it on the toy"
export DATASET_REPO=${HF_USER}/so101_${TASK_NAME}
export HF_LEROBOT_HOME=/home/suva/ws/lerobot/so101-custom-training
export POLICY_REPO=${HF_USER}/so101_${TASK_NAME}_policy
export PRETRAINED_CKPT=${HF_USER}/so101_${TASK_NAME}_pi_fast
export TRAIN_OUTPUT_DIR=${HF_USER}/so101_${TASK_NAME}_train
export HF_LEROBOT_HOME=/home/suva/ws/lerobot/so101-custom-training
export JOB_NAME=act_so101_${TASK_NAME}
DISPLAY=:1
echo "Downloading dataset: ${DATASET_REPO}"
huggingface-cli download ${DATASET_REPO} \
  --repo-type dataset \
  --local-dir ~/.cache/huggingface/lerobot/${DATASET_REPO}

echo "Training policy for: ${DATASET_REPO}"
echo "Output dir: outputs/train/${JOB_NAME}"

lerobot-train \
  --dataset.repo_id=${DATASET_REPO} \
  --policy.type=act \
  --output_dir=outputs/train/${JOB_NAME} \
  --job_name=${JOB_NAME} \
  --policy.device=cuda \
  --wandb.enable=false \
  --policy.repo_id=${POLICY_REPO}