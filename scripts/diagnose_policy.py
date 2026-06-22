#!/usr/bin/env python3
import os
import sys
import torch
from huggingface_hub import login
from lerobot.policies.vla_jepa.modeling_vla_jepa import VLAJEPAPolicy
from lerobot.policies.factory import make_pre_post_processors
from lerobot.datasets import LeRobotDataset

policy_repo = sys.argv[1] if len(sys.argv) > 1 else "witsense-ai/so101_vla_jepa_v3"
dataset_path = os.path.expanduser(
    "~/ws/lerobot/so101-custom-training/witsense-ai/so101_pick_and_place_ring_20260613_182839"
)

token = os.environ.get("HF_TOKEN")
login(token=token)

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Policy: {policy_repo} | Device: {device}")

rename_map = {
    "observation.images.top": "observation.images.exterior_1_left",
    "observation.images.wrist": "observation.images.exterior_2_left",
}

print("\n=== Loading Dataset ===")
dataset = LeRobotDataset("witsense-ai/so101_pick_and_place_ring", root=dataset_path)
actions = torch.stack([dataset[i]["action"] for i in range(min(200, len(dataset)))])
print(f"Training actions  min={actions.min():.3f}  max={actions.max():.3f}  mean={actions.mean():.3f}")
print(f"Per-joint mean:   {actions.mean(dim=0).numpy().round(3)}")
print(f"Per-joint std:    {actions.std(dim=0).numpy().round(3)}")

print("\n=== Loading Policy + Postprocessor ===")
policy = VLAJEPAPolicy.from_pretrained(policy_repo)
policy.eval().to(device)

_, postprocessor = make_pre_post_processors(
    policy_cfg=policy.config,
    pretrained_path=policy_repo,
    dataset_stats=dataset.meta.stats,
)
print("✓ Postprocessor loaded")

print("\n=== Inference: normalized → denormalized (actual robot commands) ===")
denorm_actions = []
for i in range(10):
    sample = dataset[i * 50]
    obs = {}
    for k, v in sample.items():
        if k.startswith("observation."):
            k = rename_map.get(k, k)
            obs[k] = v.unsqueeze(0).to(device)

    with torch.no_grad():
        norm_action = policy.select_action(obs)
        denorm = postprocessor(norm_action)

    denorm_actions.append(denorm.cpu())
    print(f"  [{i}] norm={norm_action.cpu().numpy().round(3)}  →  robot_deg={denorm.detach().cpu().numpy().round(1)}")

denorm = torch.stack(denorm_actions)
print(f"\n=== Actual robot command stats ===")
print(f"min={denorm.min():.2f}°  max={denorm.max():.2f}°  range={denorm.max()-denorm.min():.2f}°")
print(f"Per-joint mean: {denorm.mean(dim=0).numpy().round(2)}")
print(f"Per-joint std:  {denorm.std(dim=0).numpy().round(2)}")

train_range = actions.max() - actions.min()
robot_range = denorm.max() - denorm.min()
ratio = robot_range / train_range

print(f"\nTraining range: {train_range:.2f}°  |  Robot command range: {robot_range:.2f}°  |  ratio: {ratio:.2f}")

if robot_range < 5.0:
    print("❌ Robot commands near-zero — postprocessor not denormalizing correctly")
elif ratio < 0.1:
    print("⚠️  Policy predicting near-mean actions — not converged or mode collapse")
elif denorm.std() < 1.0:
    print("⚠️  All commands identical — mode collapse")
else:
    print("✅ Robot commands look reasonable — deploy and observe")
