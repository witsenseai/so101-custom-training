#!/bin/bash
source ~/ws/lerobot/.venv/bin/activate
set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTDIR=outputs/comparison_$TIMESTAMP

mkdir -p $OUTDIR

echo "Training both models for comparison ($TIMESTAMP)"
echo ""

# Train SmolVLA
echo "=== Training SmolVLA ==="
time bash scripts/train_smolvla.sh 2>&1 | tee $OUTDIR/smolvla_train.log
SMOLVLA_TIME=$(grep real $OUTDIR/smolvla_train.log | tail -1)

# Train VLA-JEPA
echo ""
echo "=== Training VLA-JEPA ==="
time bash scripts/train_vla_jepa.sh 2>&1 | tee $OUTDIR/vla_jepa_train.log
VJEPA_TIME=$(grep real $OUTDIR/vla_jepa_train.log | tail -1)

# Eval both
echo ""
echo "=== Evaluating SmolVLA ==="
bash scripts/eval_smolvla.sh 2>&1 | tee $OUTDIR/smolvla_eval.log

echo ""
echo "=== Evaluating VLA-JEPA ==="
bash scripts/eval_vla_jepa.sh 2>&1 | tee $OUTDIR/vla_jepa_eval.log

# Summary
cat > $OUTDIR/SUMMARY.txt << EOF
Comparison Results ($TIMESTAMP)
================================

SmolVLA Training:
  $SMOLVLA_TIME
  Output: outputs/train/smolvla

VLA-JEPA Training:
  $VJEPA_TIME
  Output: outputs/train/vla_jepa

Evaluations:
  SmolVLA: outputs/eval/smolvla
  VLA-JEPA: outputs/eval/vla_jepa

Full logs in: $OUTDIR/
EOF

echo ""
cat $OUTDIR/SUMMARY.txt
