#!/bin/bash
# Setup and validate robot environment configuration
# This script sources the env file and validates that robots are on correct ports

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

# Source the environment file
if [ ! -f "$ROOT_DIR/env" ]; then
  echo "ERROR: $ROOT_DIR/env not found" >&2
  exit 1
fi

source "$ROOT_DIR/env"

echo "=========================================="
echo "Robot Environment Setup"
echo "=========================================="
echo ""

# Check ports exist
echo "Checking USB ports..."
if [ ! -e "$ROBOT_LEADER_PORT" ]; then
  echo "❌ ERROR: Leader port not found: $ROBOT_LEADER_PORT" >&2
  exit 1
else
  echo "✓ Leader port available: $ROBOT_LEADER_PORT"
fi

if [ ! -e "$ROBOT_FOLLOWER_PORT" ]; then
  echo "❌ ERROR: Follower port not found: $ROBOT_FOLLOWER_PORT" >&2
  exit 1
else
  echo "✓ Follower port available: $ROBOT_FOLLOWER_PORT"
fi

echo ""
echo "=========================================="
echo "Environment Configuration Summary"
echo "=========================================="
echo "ROBOT_LEADER_PORT=$ROBOT_LEADER_PORT"
echo "ROBOT_FOLLOWER_PORT=$ROBOT_FOLLOWER_PORT"
echo "HF_USER=$HF_USER"
echo "TASK_NAME=$TASK_NAME"
echo ""
echo "✓ Environment is ready!"
echo ""
echo "Next steps:"
echo "  - Run training:  make train"
echo "  - Run eval:      ./scripts/eval_smolvla_robot.sh"
echo "  - Run rollout:   lerobot-rollout --robot.port=\$ROBOT_FOLLOWER_PORT ..."
echo ""
