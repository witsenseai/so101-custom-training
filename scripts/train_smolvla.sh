#!/bin/bash
source ~/ws/lerobot/.venv/bin/activate
set -e

export HF_TOKEN=your_token_here
export HF_USER=witsense-ai

# Find local dataset
DATASET_ROOT=$(find ~/ws/lerobot/so101-custom-training/witsense-ai -name "info.json" -type f | head -1 | xargs dirname | xargs dirname)

if [ ! -d "$DATASET_ROOT" ]; then
  echo "Error: Dataset not found in witsense-ai folder"
  exit 1
fi

echo "Training XVLA on dataset: $DATASET_ROOT"

lerobot-train \
  --dataset.repo_id=local_dataset \
  --dataset.root="$DATASET_ROOT" \
  --policy.type=smolvla \
  --output_dir=outputs/train/smolvla \
  --job_name=smolvla_so101 \
  --policy.device=cuda \
  --wandb.enable=false \
  --policy.repo_id=${HF_USER}/so101_policy_smolvla

echo "✓ Done: outputs/train/smolvla"
