#!/bin/bash
source ~/ws/lerobot/.venv/bin/activate
set -e

export HF_TOKEN=your_token_here
export HF_USER=witsense-ai
POLICY=witsense-ai/so101_policy_vla_jepa

mkdir -p outputs/eval/vla_jepa

echo "Evaluating VLA-JEPA: $POLICY"

lerobot-eval \
  --policy.path=$POLICY \
  --eval.batch_size=1 \
  --eval.n_episodes=10 \
  --policy.device=cuda \
  --output_dir=outputs/eval/vla_jepa \
  --eval.save_videos=true

echo "✓ Done: outputs/eval/vla_jepa"
