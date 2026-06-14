#!/bin/bash
set -euo pipefail

HF_TOKEN="${1:-${HF_TOKEN:-}}"

if [ -z "$HF_TOKEN" ]; then
    echo "Usage: export HF_TOKEN=your_token && bash train_vla_jepa_vastai.sh"
    echo "   or: bash train_vla_jepa_vastai.sh your_token"
    exit 1
fi

DATASET_REPO="witsense-ai/so101_pick_and_place_ring"
MODEL_REPO="witsense-ai/so101_vla_jepa_fewshot"
JOB_NAME="vla_jepa_so101_fewshot"
OUTPUT_DIR="/tmp/vla_jepa_training"

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

echo "Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq \
    git \
    curl \
    wget \
    build-essential \
    python3-dev \
    python3-venv \
    python3-pip \
    ffmpeg > /dev/null 2>&1

echo "Checking CUDA availability..."
nvidia-smi --query-gpu=name --format=csv,noheader || {
    echo "Error: No GPU detected. Ensure NVIDIA drivers are installed."
    exit 1
}

echo "Setting up Python virtual environment..."
python3 -m venv /tmp/vla_jepa_env
source /tmp/vla_jepa_env/bin/activate

echo "Installing Python packages..."
pip install --quiet -U pip setuptools wheel
pip install --quiet "torch>=2.0" "torchvision>=0.15"
pip install --quiet "lerobot[vla_jepa]" "huggingface-hub"

mkdir -p "$OUTPUT_DIR"

huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential

echo "Starting VLA-JEPA training..."
echo "Dataset: $DATASET_REPO"
echo "Model: $MODEL_REPO"
echo ""

lerobot-train \
  --dataset.repo_id="$DATASET_REPO" \
  --policy.path=lerobot/VLA-JEPA-Pretrain \
  --policy.freeze_qwen=true \
  --policy.enable_world_model=false \
  --policy.reinit_modules='["model.action_model.action_encoder", "model.action_model.action_decoder", "model.action_model.state_encoder"]' \
  --policy.device=cuda \
  --policy.repo_id="$MODEL_REPO" \
  --output_dir="$OUTPUT_DIR" \
  --job_name="$JOB_NAME" \
  --wandb.enable=false \
  --steps=10000 \
  --batch_size=4 \
  --num_workers=4 \
  --save_freq=500 \
  --log_freq=50 \
  --eval_freq=1000 \
  --rename_map='{"observation.images.top": "observation.images.exterior_1_left", "observation.images.wrist": "observation.images.exterior_2_left"}'

echo ""
echo "Training complete!"
echo "Model saved to: https://huggingface.co/$MODEL_REPO"
