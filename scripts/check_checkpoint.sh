#!/bin/bash
# Check checkpoint integrity
# Usage: bash scripts/check_checkpoint.sh [checkpoint_dir]

CHECKPOINT_DIR="${1:-outputs/train/smolvla/checkpoints}"

if [ ! -d "$CHECKPOINT_DIR" ]; then
  echo "❌ Checkpoint directory not found: $CHECKPOINT_DIR"
  exit 1
fi

echo "Checking checkpoints in: $CHECKPOINT_DIR"
echo ""

TOTAL=0
VALID=0
INCOMPLETE=0

for checkpoint in "$CHECKPOINT_DIR"/*/; do
  if [ ! -d "$checkpoint" ]; then
    continue
  fi

  TOTAL=$((TOTAL + 1))
  STEP=$(basename "$checkpoint")

  # Check for required files
  MODEL_FILE="$checkpoint/pretrained_model/model.safetensors"
  CONFIG_FILE="$checkpoint/pretrained_model/config.json"
  TRAIN_CONFIG="$checkpoint/pretrained_model/train_config.json"
  TRAINING_STEP="$checkpoint/training_state/training_step.json"

  if [ -f "$MODEL_FILE" ] && [ -f "$CONFIG_FILE" ] && [ -f "$TRAIN_CONFIG" ] && [ -f "$TRAINING_STEP" ]; then
    VALID=$((VALID + 1))

    # Get model size
    MODEL_SIZE=$(ls -lh "$MODEL_FILE" | awk '{print $5}')

    # Extract step info
    STEP_NUM=$(grep -o '"step": [0-9]*' "$TRAINING_STEP" | grep -o '[0-9]*' || echo "unknown")

    echo "✓ Step $STEP (step=$STEP_NUM) - Size: $MODEL_SIZE"
  else
    INCOMPLETE=$((INCOMPLETE + 1))
    echo "❌ Step $STEP - INCOMPLETE"

    if [ ! -f "$MODEL_FILE" ]; then
      echo "   Missing: model.safetensors"
    fi
    if [ ! -f "$TRAIN_CONFIG" ]; then
      echo "   Missing: train_config.json"
    fi
    if [ ! -f "$TRAINING_STEP" ]; then
      echo "   Missing: training_step.json"
    fi
  fi
done

echo ""
echo "Summary:"
echo "  Total: $TOTAL"
echo "  Valid: $VALID"
echo "  Incomplete: $INCOMPLETE"

if [ $INCOMPLETE -gt 0 ]; then
  echo ""
  echo "⚠️  Warning: Some checkpoints are incomplete!"
  exit 1
fi

if [ $VALID -eq 0 ]; then
  echo ""
  echo "❌ No valid checkpoints found!"
  exit 1
fi

echo ""
echo "✓ All checkpoints are valid!"
exit 0
