#!/bin/bash
# train.sh
source ~/lerobot-env/bin/activate
source .env

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