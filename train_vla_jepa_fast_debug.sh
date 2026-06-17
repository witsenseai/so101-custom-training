#!/bin/bash
set -euo pipefail

HF_TOKEN="${1:-${HF_TOKEN:-}}"
LOG_FILE="/workspace/vla_jepa_training.log"
VENV="/workspace/vla_jepa_env"
export HF_HOME="/workspace/.hf_home"

exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== VLA-JEPA Training ===" | tee -a "$LOG_FILE"
echo "Started at: $(date)" | tee -a "$LOG_FILE"
echo ""

if [ -z "$HF_TOKEN" ]; then
    echo "ERROR: HF_TOKEN not set"
    exit 1
fi

if ! python3 -c "import lerobot, transformers, datasets, av" 2>/dev/null; then
    echo "[1/4] Installing system dependencies..."
    apt-get update -qq 2>&1 | tail -1
    apt-get install -y -qq git ffmpeg python3-venv python3-pip 2>&1 | tail -1
    echo "✓ System dependencies installed"

    echo "[2/4] Checking CUDA..."
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo "✓ GPU detected"

    echo "[3/4] Creating virtual environment and installing LeRobot..."
    rm -rf "$VENV"
    uv venv "$VENV" --python 3.12
    source "$VENV/bin/activate"
    uv pip install -q "lerobot[dataset,training,vla_jepa] @ git+https://github.com/huggingface/lerobot.git@main" huggingface-hub > /tmp/lerobot_install.log 2>&1 || { cat /tmp/lerobot_install.log; exit 1; }
    python3 -c "import torch; print(f'  ✓ PyTorch {torch.__version__} (CUDA: {torch.cuda.is_available()})')"
else
    echo "✓ LeRobot already installed, skipping setup"
    [ -f "$VENV/bin/activate" ] && source "$VENV/bin/activate"
fi

echo "[4/4] HuggingFace login..."
python3 -c "from huggingface_hub import login; login(token='$HF_TOKEN'); print('✓ Logged in')"

# Ensure dataset tag exists, download, and symlink to LeRobot expected path
HF_HOME="${HF_HOME:-/workspace/.hf_home}"
DATASET_CACHE="$HF_HOME/hub/datasets--witsense-ai--so101_pick_and_place_ring/snapshots"
LEROBOT_DATASET="$HF_HOME/lerobot/witsense-ai/so101_pick_and_place_ring"

echo "  Setting up dataset..."
python3 << EOF
from huggingface_hub import snapshot_download, HfApi

api = HfApi(token="$HF_TOKEN")

# Check existing tags
refs = api.list_repo_refs("witsense-ai/so101_pick_and_place_ring", repo_type="dataset")
existing_tags = [t.name for t in refs.tags]
print(f"  Existing tags: {existing_tags}")

if "v3.0" not in existing_tags:
    api.create_tag("witsense-ai/so101_pick_and_place_ring", tag="v3.0", repo_type="dataset")
    print("  ✓ Tag v3.0 created")
else:
    print("  ✓ Tag v3.0 already exists")

snapshot_download("witsense-ai/so101_pick_and_place_ring", repo_type="dataset", token="$HF_TOKEN")
print("  ✓ Dataset downloaded")
EOF

SNAPSHOT=$(ls "$DATASET_CACHE" | head -1)
mkdir -p "$HF_HOME/lerobot/witsense-ai"
rm -f "$LEROBOT_DATASET"
ln -sf "$DATASET_CACHE/$SNAPSHOT" "$LEROBOT_DATASET"
echo "✓ Dataset ready at $LEROBOT_DATASET → $SNAPSHOT"

echo ""
echo "=== Starting Training ===" | tee -a "$LOG_FILE"
echo "Dataset:    witsense-ai/so101_pick_and_place_ring"
echo "Output:     witsense-ai/so101_vla_jepa_fewshot"
echo "Batch size: 8 | Steps: 10000 | World model: on"
echo ""

lerobot-train \
  --dataset.repo_id=witsense-ai/so101_pick_and_place_ring \
  --policy.path=lerobot/VLA-JEPA-Pretrain \
  --policy.freeze_qwen=true \
  --policy.enable_world_model=true \
  --policy.reinit_modules='["model.action_model.action_encoder", "model.action_model.action_decoder", "model.action_model.state_encoder"]' \
  --policy.device=cuda \
  --policy.repo_id=witsense-ai/so101_vla_jepa_fewshot \
  --output_dir=/workspace/vla_jepa_training \
  --job_name=vla_jepa_so101_fewshot \
  --wandb.enable=false \
  --steps=10000 \
  --batch_size=8 \
  --num_workers=8 \
  --save_freq=500 \
  --log_freq=50 \
  --eval_freq=1000 \
  --rename_map='{"observation.images.top": "observation.images.exterior_1_left", "observation.images.wrist": "observation.images.exterior_2_left"}'

echo ""
echo "=== Training Complete ===" | tee -a "$LOG_FILE"
echo "Finished at: $(date)" | tee -a "$LOG_FILE"
echo "Model: https://huggingface.co/witsense-ai/so101_vla_jepa_fewshot"
