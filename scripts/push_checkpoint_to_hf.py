#!/usr/bin/env python3
import os
import sys
from huggingface_hub import HfApi, login

if len(sys.argv) < 3:
    print("Usage: python3 push_checkpoint_to_hf.py <repo_id> <checkpoint_dir>")
    print("")
    print("Examples:")
    print("  python3 push_checkpoint_to_hf.py witsense-ai/so101_act_fewshot /workspace/act_training/checkpoints/last/pretrained_model")
    print("  python3 push_checkpoint_to_hf.py witsense-ai/so101_vla_jepa_v2  /workspace/vla_jepa_training_v2/checkpoints/last/pretrained_model")
    sys.exit(1)

repo_id = sys.argv[1]
checkpoint = sys.argv[2]

token = os.environ.get("HF_TOKEN")
if not token:
    print("ERROR: HF_TOKEN not set")
    sys.exit(1)

if not os.path.isdir(checkpoint):
    print(f"ERROR: checkpoint directory not found: {checkpoint}")
    sys.exit(1)

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
