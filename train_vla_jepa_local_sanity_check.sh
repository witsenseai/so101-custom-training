#!/bin/bash
# VLA-JEPA Local Sanity Check for RTX 4070 (8-12GB VRAM)
# This is a MINIMAL test to verify training code works before running on VM
set -euo pipefail

HF_TOKEN="${1:-${HF_TOKEN:-}}"
BATCH_SIZE="${2:-1}"  # Default batch_size=1 for 8GB VRAM (can try 2 if you have 12GB)

echo "=== VLA-JEPA Local Sanity Check ==="
echo "GPU VRAM: 8-12GB"
echo "Batch Size: $BATCH_SIZE"
echo "Steps: 10 (just to verify setup works)"
echo "Dataset: SO-101 (will download from HF Hub)"
echo ""

if [ -z "$HF_TOKEN" ]; then
    echo "ERROR: HF_TOKEN not set"
    echo "Usage: export HF_TOKEN=your_token && bash train_vla_jepa_local_sanity_check.sh [batch_size]"
    exit 1
fi

# Check GPU
echo "[1/4] Checking GPU..."
python3 << 'EOF'
import torch
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
print(f"Available: {torch.cuda.mem_get_info()[0] / 1e9:.1f} GB / {torch.cuda.mem_get_info()[1] / 1e9:.1f} GB")
EOF

# Install dependencies
echo ""
echo "[2/4] Installing dependencies..."
pip install -q -U pip setuptools wheel 2>&1 | grep -E "Successfully|ERROR" || true
pip install -q "torch>=2.0" "lerobot" "huggingface-hub" 2>&1 | grep -E "Successfully|ERROR" || true

# Login to HF
echo ""
echo "[3/4] Logging into HuggingFace..."
python3 << EOF
from huggingface_hub import login
login(token="$HF_TOKEN")
print("✓ HuggingFace login complete")
EOF

# Sanity check training
echo ""
echo "[4/4] Running sanity check training (10 steps)..."
echo "This will download the pretrained model and SO-101 dataset (~1-2 GB)"
echo ""

lerobot-train \
  --dataset.repo_id=/home/suva/ws/lerobot/so101-custom-training/witsense-ai/so101_pick_and_place_ring_20260613_182839 \
  --policy.path=lerobot/VLA-JEPA-Pretrain \
  --policy.freeze_qwen=true \
  --policy.enable_world_model=false \
  --policy.reinit_modules='["model.action_model.action_encoder", "model.action_model.action_decoder", "model.action_model.state_encoder"]' \
  --policy.device=cuda \
  --policy.repo_id=witsense-ai/so101_vla_jepa_sanity_check \
  --output_dir=/tmp/vla_jepa_local_sanity_check \
  --job_name=vla_jepa_sanity_check \
  --wandb.enable=false \
  --steps=10 \
  --batch_size=$BATCH_SIZE \
  --num_workers=0 \
  --save_freq=5 \
  --log_freq=2 \
  --eval_freq=100 \
  --rename_map='{"observation.images.top": "observation.images.exterior_1_left", "observation.images.wrist": "observation.images.exterior_2_left"}' || {
    echo ""
    echo "❌ Training failed. Check error above."
    echo "If CUDA out of memory: try reducing batch_size (use batch_size=1)"
    echo "If download issues: check HF_TOKEN or internet connection"
    exit 1
  }

echo ""
echo "✅ Sanity check passed!"
echo "Checkpoint saved to: /tmp/vla_jepa_local_sanity_check"
echo ""
echo "Next steps:"
echo "1. Check memory usage above - if you hit OOM, reduce batch_size further"
echo "2. If this works, you can run on the VM with batch_size=4-8"
echo "3. Final training on VM: batch_size=8, steps=10000, enable_world_model=true"
