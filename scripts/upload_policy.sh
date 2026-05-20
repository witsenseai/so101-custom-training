#!/bin/bash
# upload_policy.sh
source ~/lerobot-env/bin/activate
source .env

huggingface-cli upload ${POLICY_REPO} \
  outputs/train/${JOB_NAME}/checkpoints/last/pretrained_model