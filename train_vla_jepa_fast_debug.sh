#!/bin/bash
set -euo pipefail

HF_TOKEN="${1:-${HF_TOKEN:-}}"
VRAM_GB="${2:-16}"
export WANDB_API_KEY="${WANDB_API_KEY:-}"
LOG_FILE="/workspace/vla_jepa_training.log"
VENV="/workspace/vla_jepa_env"
export HF_HOME="/workspace/.hf_home"

exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

if [ -z "$HF_TOKEN" ]; then
    echo "ERROR: HF_TOKEN not set. Usage: bash train_vla_jepa_fast_debug.sh <HF_TOKEN> [vram_gb]"
    exit 1
fi

# freeze_qwen only if VRAM < 40GB — world model is ALWAYS on (it's why 13 eps works)
if [ "$VRAM_GB" -ge 80 ]; then
    FREEZE_QWEN=false
    BATCH_SIZE=8
elif [ "$VRAM_GB" -ge 40 ]; then
    FREEZE_QWEN=false
    BATCH_SIZE=4
else
    FREEZE_QWEN=true
    BATCH_SIZE=4
fi

echo "=== VLA-JEPA Training ==="
echo "Started: $(date) | VRAM: ${VRAM_GB}GB | freeze_qwen=$FREEZE_QWEN | world_model=ON"
echo ""

if ! python3 -c "import lerobot, transformers, datasets, av" 2>/dev/null; then
    apt-get update -qq 2>&1 | tail -1
    apt-get install -y -qq git ffmpeg python3-venv python3-pip 2>&1 | tail -1
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

    rm -rf "$VENV"
    uv venv "$VENV" --python 3.12
    source "$VENV/bin/activate"
    uv pip install -q "lerobot[dataset,training,vla_jepa] @ git+https://github.com/huggingface/lerobot.git@main" huggingface-hub \
        > /workspace/lerobot_install.log 2>&1 || { cat /workspace/lerobot_install.log; exit 1; }
    python3 -c "import torch; print(f'✓ PyTorch {torch.__version__} CUDA={torch.cuda.is_available()}')"
else
    echo "✓ LeRobot already installed"
    [ -f "$VENV/bin/activate" ] && source "$VENV/bin/activate"
fi

python3 -c "from huggingface_hub import login; login(token='$HF_TOKEN'); print('✓ HF login OK')"

DATASET_CACHE="$HF_HOME/hub/datasets--witsense-ai--so101_pick_and_place_ring/snapshots"
LEROBOT_DATASET="$HF_HOME/lerobot/witsense-ai/so101_pick_and_place_ring"

python3 << EOF
from huggingface_hub import snapshot_download, HfApi
api = HfApi(token="$HF_TOKEN")
refs = api.list_repo_refs("witsense-ai/so101_pick_and_place_ring", repo_type="dataset")
if "v3.0" not in [t.name for t in refs.tags]:
    api.create_tag("witsense-ai/so101_pick_and_place_ring", tag="v3.0", repo_type="dataset")
    print("✓ Tag v3.0 created")
else:
    print("✓ Tag v3.0 exists")
snapshot_download("witsense-ai/so101_pick_and_place_ring", repo_type="dataset", token="$HF_TOKEN")
print("✓ Dataset downloaded")
EOF

SNAPSHOT=$(ls "$DATASET_CACHE" | head -1)
mkdir -p "$HF_HOME/lerobot/witsense-ai"
rm -f "$LEROBOT_DATASET"
ln -sf "$DATASET_CACHE/$SNAPSHOT" "$LEROBOT_DATASET"
echo "✓ Dataset ready"
echo ""

lerobot-train \
  --dataset.repo_id=witsense-ai/so101_pick_and_place_ring \
  --policy.path=lerobot/VLA-JEPA-Pretrain \
  --policy.freeze_qwen=$FREEZE_QWEN \
  --policy.enable_world_model=true \
  --policy.reinit_modules='["model.action_model.action_encoder", "model.action_model.action_decoder", "model.action_model.state_encoder"]' \
  --policy.device=cuda \
  --policy.repo_id=witsense-ai/so101_vla_jepa_v3 \
  --output_dir=/workspace/vla_jepa_training_v3 \
  --job_name=vla_jepa_so101_v3 \
  --wandb.enable=true \
  --wandb.project=so101_vla_jepa \
  --steps=15000 \
  --batch_size=$BATCH_SIZE \
  --num_workers=4 \
  --save_freq=5000 \
  --log_freq=100 \
  --eval_freq=2000 \
  --rename_map='{"observation.images.top": "observation.images.exterior_1_left", "observation.images.wrist": "observation.images.exterior_2_left"}'

echo ""
echo "=== Done at $(date) ==="
echo "Model: https://huggingface.co/witsense-ai/so101_vla_jepa_v3"
