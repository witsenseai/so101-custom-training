#!/usr/bin/env python3
import os
import sys
import torch
from huggingface_hub import login
from lerobot.policies.vla_jepa.modeling_vla_jepa import VLAJEPAPolicy
from lerobot.datasets import LeRobotDataset

policy_repo = sys.argv[1] if len(sys.argv) > 1 else "witsense-ai/so101_vla_jepa_fewshot_2000"
dataset_path = os.path.expanduser(
    "~/ws/lerobot/so101-custom-training/witsense-ai/so101_pick_and_place_ring_20260613_182839"
)

token = os.environ.get("HF_TOKEN")
login(token=token)

device = "cuda" if torch.cuda.is_available() else "cpu"

print(f"Policy: {policy_repo}")
print(f"Device: {device}")
print("")

print("=== Loading Dataset ===")
dataset = LeRobotDataset("witsense-ai/so101_pick_and_place_ring", root=dataset_path)
actions = torch.stack([dataset[i]["action"] for i in range(min(200, len(dataset)))])
print(f"Training actions — min: {actions.min():.3f}  max: {actions.max():.3f}  mean: {actions.mean():.3f}  std: {actions.std():.3f}")
print(f"Per-joint mean: {actions.mean(dim=0).numpy().round(3)}")
print(f"Per-joint std:  {actions.std(dim=0).numpy().round(3)}")

print("")
print("=== Loading Policy ===")
policy = VLAJEPAPolicy.from_pretrained(policy_repo)
policy.eval().to(device)

rename_map = {
    "observation.images.top": "observation.images.exterior_1_left",
    "observation.images.wrist": "observation.images.exterior_2_left",
}

print("")
print("=== Running Inference on 10 Samples ===")
predicted_actions = []
for i in range(10):
    sample = dataset[i * 50]
    obs = {}
    for k, v in sample.items():
        if k.startswith("observation."):
            k = rename_map.get(k, k)
            obs[k] = v.unsqueeze(0).to(device)

    with torch.no_grad():
        action = policy.select_action(obs)

    predicted_actions.append(action.cpu())
    print(f"  sample {i:2d}: {action.cpu().numpy().round(3)}")

predicted = torch.stack(predicted_actions)
print("")
print("=== Diagnosis ===")
print(f"Predicted — min: {predicted.min():.3f}  max: {predicted.max():.3f}  mean: {predicted.mean():.3f}  std: {predicted.std():.3f}")

action_range = actions.max() - actions.min()
pred_range = predicted.max() - predicted.min()
ratio = pred_range / action_range

print(f"Training range: {action_range:.3f}")
print(f"Predicted range: {pred_range:.3f}  (ratio: {ratio:.2f})")
print("")

if pred_range < 0.05:
    print("❌ ISSUE: Policy outputs near-zero actions — likely normalization bug or collapsed policy")
elif ratio < 0.1:
    print("⚠️  ISSUE: Predicted range much smaller than training range — policy not moving enough")
elif predicted.std() < 0.01:
    print("⚠️  ISSUE: All predictions identical — policy outputting constant action (mode collapse)")
else:
    print("✅ Actions look reasonable — issue may be inference frequency or deployment config")
