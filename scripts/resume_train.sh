#!/bin/bash
# resume_train.sh
source ~/lerobot-env/bin/activate
source .env

lerobot-train \
  --config_path=outputs/train/${JOB_NAME}/checkpoints/last/pretrained_model/train_config.json \
  --resume=true