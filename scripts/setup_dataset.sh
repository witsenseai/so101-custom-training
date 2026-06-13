#!/bin/bash
# setup_dataset.sh - Setup local dataset for LeRoBot training
# This script prepares the dataset in the proper location for training scripts

source ~/ws/lerobot/.venv/bin/activate

export HF_USER=witsense-ai
export TASK_NAME=pick_and_place_ring
export DATASET_REPO=${HF_USER}/so101_${TASK_NAME}
export HF_HOME=${HOME}/.cache/huggingface

echo "=========================================="
echo "LeRoBot Dataset Setup"
echo "=========================================="
echo "Task: ${TASK_NAME}"
echo "Dataset Repo: ${DATASET_REPO}"
echo "HF Home: ${HF_HOME}"
echo "=========================================="
echo ""

# Find local dataset
LOCAL_DATASET=$(find /home/suva/ws/lerobot/so101-custom-training/witsense-ai -maxdepth 2 -name "info.json" -type f | head -1 | xargs dirname)

if [ -z "$LOCAL_DATASET" ]; then
  echo "Error: Could not find local dataset with meta/info.json"
  echo "Expected: /home/suva/ws/lerobot/so101-custom-training/witsense-ai/*/meta/info.json"
  exit 1
fi

LOCAL_DATASET_ROOT=$(dirname "$LOCAL_DATASET")
echo "Found local dataset at: ${LOCAL_DATASET_ROOT}"
echo ""

# Create HuggingFace datasets cache directory
CACHE_DATASET_DIR="${HF_HOME}/datasets/${DATASET_REPO}"
mkdir -p "${CACHE_DATASET_DIR}"

echo "Setting up dataset cache..."
echo "  Source: ${LOCAL_DATASET_ROOT}"
echo "  Target: ${CACHE_DATASET_DIR}"
echo ""

# Copy or symlink the dataset
if [ -d "${CACHE_DATASET_DIR}/meta" ]; then
  echo "✓ Dataset already exists in cache"
else
  echo "Copying dataset to HuggingFace cache..."
  cp -r "${LOCAL_DATASET_ROOT}"/* "${CACHE_DATASET_DIR}/"
  if [ $? -eq 0 ]; then
    echo "✓ Dataset copied successfully"
  else
    echo "✗ Failed to copy dataset"
    exit 1
  fi
fi

echo ""
echo "Verifying dataset setup..."
if [ -f "${CACHE_DATASET_DIR}/meta/info.json" ]; then
  echo "✓ Dataset metadata found"
  echo ""
  echo "Dataset info:"
  python -c "import json; info = json.load(open('${CACHE_DATASET_DIR}/meta/info.json')); print('  Episodes:', info.get('num_episodes', 'unknown')); print('  Fps:', info.get('fps', 'unknown')); print('  Duration:', info.get('total_steps', 'unknown'), 'steps')"
else
  echo "✗ Dataset metadata not found"
  exit 1
fi

echo ""
echo "=========================================="
echo "✓ Dataset setup complete!"
echo "=========================================="
echo ""
echo "Ready to train:"
echo "  bash scripts/train_xvla.sh"
echo "  bash scripts/train_vla_jepa.sh"
echo ""
