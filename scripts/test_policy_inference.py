#!/usr/bin/env python3
import os
import torch
from huggingface_hub import login
from lerobot.policies.vla_jepa.modeling_vla_jepa import VLAJEPAPolicy
from lerobot.datasets import LeRobotDataset

token = os.environ.get("HF_TOKEN")
policy_repo = "witsense-ai/so101_vla_jepa_fewshot_3000"
dataset_repo = "witsense-ai/so101_pick_and_place_ring"

login(token=token)

print("Loading policy...")
policy = VLAJEPAPolicy.from_pretrained(policy_repo)
policy.eval()
device = "cuda" if torch.cuda.is_available() else "cpu"
policy.to(device)
print(f"✓ Policy loaded on {device}")

print("\nLoading dataset sample...")
local_dataset_path = os.path.expanduser(
    "~/ws/lerobot/so101-custom-training/witsense-ai/so101_pick_and_place_ring_20260613_182839"
)
dataset = LeRobotDataset(dataset_repo, root=local_dataset_path)
sample = dataset[0]

rename_map = {
    "observation.images.top": "observation.images.exterior_1_left",
    "observation.images.wrist": "observation.images.exterior_2_left",
}

obs = {}
for k, v in sample.items():
    if k.startswith("observation."):
        k = rename_map.get(k, k)
        obs[k] = v.unsqueeze(0).to(device)

print("Running inference...")
with torch.no_grad():
    action = policy.select_action(obs)

print(f"✓ Action shape: {action.shape}")
print(f"  Action values: {action.cpu().numpy()}")
print("\nPolicy is working!")
