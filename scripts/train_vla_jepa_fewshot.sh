#!/bin/bash
# VLA-JEPA Few-Shot Fine-tuning for SO-101
# Optimized for training with limited data (10-50 episodes)
# Key: Freeze Qwen backbone, fine-tune action head only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
source "$ROOT_DIR/../.venv/bin/activate"
source "$ROOT_DIR/env"

# Use the training dataset from HuggingFace Hub
DATASET_REPO="witsense-ai/so101_pick_and_place_ring"
echo "✓ Using training dataset from HF Hub: $DATASET_REPO"
echo ""

# For few-shot learning with <50 episodes:
# - Use pretrained checkpoint (VLA-JEPA-Pretrain)
# - Freeze Qwen backbone (freeze_qwen=true)
# - Only train action head for 5-10k steps
# - Use lower learning rate and longer warmup

echo "🚀 Starting VLA-JEPA Few-Shot Fine-tuning..."
echo "   Epochs: 3 (one pass per ~30 episodes)"
echo "   Learning rate: 1e-4 (conservative)"
echo "   Frozen: Qwen3-VL backbone"
echo "   Training: Action head only"
echo ""

lerobot-train \
  --dataset.repo_id="$DATASET_REPO" \
  --policy.path=lerobot/VLA-JEPA-Pretrain \
  --policy.freeze_qwen=true \
  --policy.reinit_modules='["model.action_model.action_encoder", "model.action_model.action_decoder", "model.action_model.state_encoder"]' \
  --policy.device=cuda \
  --policy.repo_id=${HF_USER}/so101_vla_jepa_fewshot \
  --output_dir="$ROOT_DIR/outputs/train/vla_jepa_fewshot" \
  --job_name=vla_jepa_so101_fewshot \
  --wandb.enable=false \
  --steps=10000 \
  --batch_size=2 \
  --num_workers=2 \
  --save_freq=500 \
  --log_freq=50 \
  --eval_freq=1000 \
  --rename_map='{"observation.images.top": "observation.images.exterior_1_left", "observation.images.wrist": "observation.images.exterior_2_left"}'

echo ""
echo "✓ Training complete!"
echo "   Checkpoint: $ROOT_DIR/outputs/train/vla_jepa_fewshot"
echo ""
echo "Next: Evaluate with:"
echo "  ./scripts/eval_vla_jepa_robot.sh"
