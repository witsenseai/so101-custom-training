#!/usr/bin/env python3
import os
import sys
from huggingface_hub import HfApi, login

if len(sys.argv) != 2:
    print("Usage: python3 push_checkpoint_to_hf.py <repo_id>")
    print("Example: python3 push_checkpoint_to_hf.py witsense-ai/so101_vla_jepa_fewshot")
    sys.exit(1)

repo_id = sys.argv[1]
token = os.environ.get("HF_TOKEN")

if not token:
    print("ERROR: HF_TOKEN not set")
    sys.exit(1)

checkpoint = os.environ.get("CHECKPOINT_PATH", "/workspace/vla_jepa_training/checkpoints/last/pretrained_model")

login(token=token)
api = HfApi(token=token)
api.create_repo(repo_id=repo_id, repo_type="model", private=True, exist_ok=True)
api.upload_folder(
    folder_path=checkpoint,
    repo_id=repo_id,
    repo_type="model",
    commit_message="Push checkpoint from training"
)
print(f"✓ Pushed to https://huggingface.co/{repo_id}")
