#!/usr/bin/env python3
import os
import sys
from pathlib import Path
from huggingface_hub import HfApi, login

if len(sys.argv) < 3:
    print("Usage: python3 push_checkpoint_to_hf.py <repo_id> <checkpoint_step_dir>")
    print("")
    print("Pass the step directory (pretrained_model is found automatically):")
    print("  python3 push_checkpoint_to_hf.py witsense-ai/so101_vla_jepa_v3 /workspace/vla_jepa_training_v3/checkpoints/010000")
    print("  python3 push_checkpoint_to_hf.py witsense-ai/so101_act_fewshot  /workspace/act_training/checkpoints/last")
    sys.exit(1)

repo_id = sys.argv[1]
checkpoint_dir = Path(sys.argv[2])

# pretrained_model/ contains policy weights + preprocessor.json + postprocessor.json
pretrained_dir = checkpoint_dir / "pretrained_model"
if not pretrained_dir.is_dir():
    # caller passed pretrained_model directly
    pretrained_dir = checkpoint_dir

if not pretrained_dir.is_dir():
    print(f"ERROR: pretrained_model not found in {checkpoint_dir}")
    sys.exit(1)

token = os.environ.get("HF_TOKEN")
if not token:
    print("ERROR: HF_TOKEN not set")
    sys.exit(1)

login(token=token)
api = HfApi(token=token)
api.create_repo(repo_id=repo_id, repo_type="model", private=True, exist_ok=True)
api.upload_folder(
    folder_path=str(pretrained_dir),
    repo_id=repo_id,
    repo_type="model",
    commit_message=f"Push checkpoint from {checkpoint_dir.name}"
)
print(f"✓ Pushed to https://huggingface.co/{repo_id}")
