# VLA-JEPA Few-Shot Training for SO-101

This guide explains how to train **VLA-JEPA** on your SO-101 robot with limited data (10-50 episodes).

## Why VLA-JEPA for Few-Shot Learning?

**VLA-JEPA vs SmolVLA:**

| Aspect | VLA-JEPA | SmolVLA |
|--------|----------|---------|
| **Pretraining** | Large-scale DROID dataset | Light pretraining |
| **Architecture** | Qwen3-VL + V-JEPA2 world model | Simpler Vision-Language |
| **Few-shot (14 eps)** | ✅ Designed for this | ❌ Needs 50+ episodes |
| **Inference cost** | Higher (Qwen backbone) | Lower |
| **Best for** | Limited task-specific data | Abundant data |

**Key insight:** VLA-JEPA's **frozen Qwen backbone** already understands language and vision from massive pretraining. You only fine-tune the action head on your 14 episodes.

---

## Training Workflow

### Step 1: Prepare Your Dataset

Ensure you have episodes recorded in `witsense-ai/` folder:
```bash
ls -la witsense-ai/*/data/episode_*
# Should show your 14 episodes
```

### Step 2: Run Few-Shot Training

```bash
./scripts/train_vla_jepa_fewshot.sh
```

**What this does:**
- Loads pretrained `lerobot/VLA-JEPA-Pretrain` (trained on DROID)
- **Freezes** Qwen3-VL backbone (language understanding stays fixed)
- Fine-tunes **action head only** on your 14 episodes
- Trains for 10,000 steps (~3 full passes over data)
- Saves checkpoints every 500 steps

**Expected duration:** 10-15 minutes on GPU

### Step 3: Evaluate on Robot

```bash
./scripts/eval_vla_jepa_robot.sh
```

This runs 5 rollout episodes with the trained policy and records to HF Hub.

---

## Key Configuration for Few-Shot Learning

```bash
# Training hyperparameters (in train_vla_jepa_fewshot.sh)
--policy.freeze_qwen=true        # ← Crucial for few-shot
--learning_rate=1e-4              # Conservative LR
--warmup_steps=500                # Longer warmup (5% of steps)
--batch_size=8                    # Small batch fits limited data
--steps=10000                     # ~3 epochs over 14 episodes
```

**Why freeze Qwen?**
- Qwen is pretrained on billions of tokens and images
- Your task instruction ("pickup ring and place it") is understood already
- Only the action mapping needs to be learned from your 14 episodes
- Freezing prevents overfitting on tiny dataset

---

## Troubleshooting

### Policy doesn't move
**Likely:** Pretrained model not found or training diverged
```bash
# Verify pretrained model loads
python -c "from lerobot.policies import make_policy; p = make_policy('lerobot/VLA-JEPA-Pretrain'); print('✓ Model loaded')"

# Check training loss decreased
tail -100 outputs/train/vla_jepa_fewshot/logs.txt | grep "loss"
```

### CUDA out of memory
```bash
# Reduce batch size in train_vla_jepa_fewshot.sh
--batch_size=4  # Instead of 8
```

### Dataset not found
```bash
# Your dataset must be in the witsense-ai folder
# Structure should be:
witsense-ai/
  └── tidyup-place/
      └── data/
          ├── episode_0/
          ├── episode_1/
          ...
```

---

## Next Steps After Training

1. **Improve performance:** Collect more episodes (50+) and retrain
2. **Different task:** Modify the task description in `eval_vla_jepa_robot.sh`
3. **Other robots:** Set `--policy.reinit_modules` if action/state dims differ

---

## References

- **Paper:** [VLA-JEPA: Enhancing Vision-Language-Action Model with Latent World Model](https://arxiv.org/abs/2602.10098)
- **Model Card:** https://huggingface.co/lerobot/VLA-JEPA-Pretrain
- **LeRobot Docs:** See `../docs/source/vla_jepa.mdx`
