# VLA Training & Evaluation Guide for SO-101

This guide provides comprehensive instructions for training and evaluating two state-of-the-art Vision-Language-Action (VLA) models on the SO-101 robot for the pick-and-place task.

## Models Overview

### 1. **XVLA** (Best VLA)
- **Status**: Latest/best Vision-Language-Action model in LeRobot
- **Training Type**: Train from scratch on your dataset
- **Best For**: Custom tasks where you want to train a model specifically for your data
- **Advantages**:
  - Optimized for robotics tasks
  - Flexible training from scratch
  - Good generalization when trained on sufficient data
- **Disadvantages**:
  - Requires more training data and compute
  - Training time is longer

### 2. **VLA-JEPA** (Pretrained Foundation Model)
- **Model**: `lerobot/VLA-JEPA-Pretrain` (pretrained on large diverse robotic data)
- **Training Type**: Fine-tuning on your dataset
- **Best For**: Quick adaptation to new tasks with limited data
- **Advantages**:
  - Benefits from large-scale pretraining
  - Requires less task-specific data
  - Faster fine-tuning
  - Better sample efficiency
- **Disadvantages**:
  - Larger model size
  - More VRAM required during fine-tuning

## Available VLA-JEPA Variants

The LeRobot library provides three pretrained VLA-JEPA checkpoints:

| Model | Dataset | World Model | Use Case |
|-------|---------|-------------|----------|
| `lerobot/VLA-JEPA-LIBERO` | LIBERO-90 | Enabled | Task-agnostic (90+ tasks) |
| `lerobot/VLA-JEPA-Pretrain` | Large diverse data | Enabled | General pretraining |
| `lerobot/VLA-JEPA-SimplerEnv` | SimplerEnv | Disabled | Simpler environments |

**Recommended**: `lerobot/VLA-JEPA-Pretrain` for new robotics tasks.

---

## Quick Start

### Prerequisites

Ensure you have:
1. LeRoBot environment activated: `source ~/ws/lerobot/.venv/bin/activate`
2. Environment variables set in `env` file (HF_TOKEN, robot ports, etc.)
3. CUDA-capable GPU with sufficient VRAM (24GB+ recommended)

### Training

#### Train XVLA Model
```bash
bash scripts/train_xvla.sh
```

**What it does:**
- Downloads your SO-101 pick-and-place dataset
- Initializes XVLA policy from scratch
- Trains on your dataset with the default LeRobot training pipeline
- Saves checkpoints and final model to HuggingFace Hub

**Expected**:
- Training time: 4-12 hours (depends on dataset size and hardware)
- Output: `outputs/train/xvla_pick_and_place_ring/`

#### Train VLA-JEPA Model
```bash
bash scripts/train_vla_jepa.sh
```

**What it does:**
- Downloads your SO-101 pick-and-place dataset
- Downloads pretrained VLA-JEPA foundation model
- Fine-tunes on your dataset
- Saves checkpoints and final model to HuggingFace Hub

**Expected**:
- Training time: 1-4 hours (much faster than XVLA due to pretraining)
- Output: `outputs/train/vla_jepa_pick_and_place_ring/`

### Evaluation

#### Simulation/Benchmark Evaluation

**XVLA**:
```bash
bash scripts/eval_xvla.sh
```

**VLA-JEPA**:
```bash
bash scripts/eval_vla_jepa.sh
```

These scripts evaluate the policies on benchmark environments (if your task has a simulator).
Outputs include success rates, execution times, and generated videos.

#### Real Robot Evaluation

**XVLA on SO-101**:
```bash
bash scripts/eval_xvla_robot.sh
```

**VLA-JEPA on SO-101**:
```bash
bash scripts/eval_vla_jepa_robot.sh
```

**What happens**:
1. Policy is downloaded from HuggingFace Hub
2. Robot connects and enters demonstration mode with policy inference
3. Collects 10 episodes (30 seconds each) of policy rollouts
4. Saves results to `witsense-ai/eval_pick_and_place_ring_[xvla|vla_jepa]`

---

## Comparison: XVLA vs VLA-JEPA

### Training Efficiency
| Metric | XVLA | VLA-JEPA |
|--------|------|----------|
| Training Time | 4-12h | 1-4h |
| VRAM Required | 20-24GB | 24-32GB |
| Data Requirement | High (>1k demos) | Low-Medium (>500 demos) |
| Convergence | Slower | Faster |

### Performance
| Metric | XVLA | VLA-JEPA |
|--------|------|----------|
| Generalization | Good (task-specific) | Excellent (broad pretraining) |
| In-Distribution | Strong | Strong |
| Out-of-Distribution | Moderate | Good |
| Fine-tuning Stability | Stable | Stable |

### Practical Recommendations

**Choose XVLA if:**
- You have lots of training data (>2000 demonstrations)
- You want a smaller, more memory-efficient model
- You're doing pure training (not fine-tuning)
- Inference latency is critical

**Choose VLA-JEPA if:**
- You have limited training data (<1000 demonstrations)
- You want better generalization to unseen scenarios
- You want faster training/adaptation
- You value sample efficiency

---

## Configuration

### Training Customization

You can modify the training scripts to add custom configurations:

```bash
# Example: Override training hyperparameters
lerobot-train \
  --dataset.repo_id=witsense-ai/so101_pick_and_place_ring \
  --policy.type=xvla \
  --output_dir=outputs/train/xvla_custom \
  --job_name=xvla_custom \
  --policy.device=cuda \
  --batch_size=8 \
  --learning_rate=1e-4 \
  --num_epochs=100 \
  --wandb.enable=true \  # Enable W&B logging
  --policy.repo_id=witsense-ai/so101_pick_and_place_ring_policy_xvla
```

### Evaluation Customization

```bash
# Example: Evaluate with more episodes
lerobot-eval \
  --policy.path=witsense-ai/so101_pick_and_place_ring_policy_xvla \
  --eval.n_episodes=50 \
  --eval.batch_size=4 \
  --eval.save_videos=true \
  --policy.device=cuda
```

---

## Troubleshooting

### CUDA Out of Memory
- Reduce `--batch_size` in training command
- Close other GPU applications
- Use VLA-JEPA which may handle memory better for your GPU

### Training Not Starting
- Verify HF_TOKEN is set: `echo $HF_TOKEN`
- Check dataset exists: `huggingface-cli repo info witsense-ai/so101_pick_and_place_ring --repo-type dataset`
- Verify CUDA installation: `python -c "import torch; print(torch.cuda.is_available())"`

### Policy Evaluation Fails
- Ensure policy was uploaded to HF Hub: `huggingface-cli repo info witsense-ai/so101_pick_and_place_ring_policy_xvla`
- Check VRAM during inference (may need more than training)
- Try evaluation on CPU for debugging: `--policy.device=cpu`

### Robot Connection Issues
- Verify robot ports: `lerobot-find-port`
- Check `env` file has correct ports: `cat env | grep ROBOT`
- Test port availability: `ls -la /dev/ttyACM*`

---

## Output Structure

After training/evaluation, you'll find:

```
outputs/
├── train/
│   ├── xvla_pick_and_place_ring/
│   │   ├── checkpoints/
│   │   │   ├── 000500/
│   │   │   ├── 001000/
│   │   │   └── ...
│   │   ├── logs/
│   │   └── config.json
│   └── vla_jepa_pick_and_place_ring/
│       ├── checkpoints/
│       ├── logs/
│       └── config.json
└── eval/
    ├── xvla_pick_and_place_ring/
    │   ├── metrics.json
    │   ├── videos/
    │   └── logs/
    └── vla_jepa_pick_and_place_ring/
        ├── metrics.json
        ├── videos/
        └── logs/
```

---

## Next Steps

1. **Run Training**: Start with the XVLA or VLA-JEPA training script
2. **Monitor Progress**: Check logs in `outputs/train/*/logs/`
3. **Evaluate Checkpoint**: Test intermediate checkpoints on robot
4. **Compare Results**: Run both models and compare success rates
5. **Optimize**: Fine-tune hyperparameters based on results

---

## References

- **XVLA**: Latest VLA variant in LeRobot
- **VLA-JEPA**: https://huggingface.co/lerobot/VLA-JEPA-Pretrain
- **LeRobot Training**: https://huggingface.co/docs/lerobot/training
- **LeRobot Evaluation**: https://huggingface.co/docs/lerobot/evaluation

---

## Support

For issues or questions:
1. Check LeRobot documentation: `https://huggingface.co/docs/lerobot`
2. Review script output for error messages
3. Check `/home/suva/ws/lerobot/CLAUDE.md` for project setup

---

**Last Updated**: 2026-06-13
