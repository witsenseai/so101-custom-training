# Quick Start: XVLA vs VLA-JEPA Training & Evaluation

## Overview

This directory contains scripts for training and evaluating two state-of-the-art VLA (Vision-Language-Action) models on your SO-101 robot:

1. **XVLA** - Latest VLA model (train from scratch)
2. **VLA-JEPA** - Pretrained foundation model (fine-tune)

## Setup

Before running any scripts, make sure:

```bash
# 1. Activate environment
source ~/ws/lerobot/.venv/bin/activate

# 2. Verify environment variables
cat env

# 3. Verify dataset exists
huggingface-cli repo info witsense-ai/so101_pick_and_place_ring --repo-type dataset
```

## Available Scripts

### Training Scripts

| Script | Model | Purpose |
|--------|-------|---------|
| `train_xvla.sh` | XVLA | Train XVLA from scratch |
| `train_vla_jepa.sh` | VLA-JEPA | Fine-tune VLA-JEPA on your data |

### Evaluation Scripts

#### Simulation/Benchmark Evaluation
| Script | Model | Purpose |
|--------|-------|---------|
| `eval_xvla.sh` | XVLA | Evaluate on benchmark environments |
| `eval_vla_jepa.sh` | VLA-JEPA | Evaluate on benchmark environments |

#### Real Robot Evaluation
| Script | Model | Purpose |
|--------|-------|---------|
| `eval_xvla_robot.sh` | XVLA | Evaluate on real SO-101 robot |
| `eval_vla_jepa_robot.sh` | VLA-JEPA | Evaluate on real SO-101 robot |

### Comparison Scripts

| Script | Purpose |
|--------|---------|
| `compare_models.sh` | Train & evaluate both models, generate comparison report |

---

## Usage Examples

### Option 1: Quick Training (Single Model)

**Train XVLA only:**
```bash
bash scripts/train_xvla.sh
```

**Train VLA-JEPA only:**
```bash
bash scripts/train_vla_jepa.sh
```

### Option 2: Train Both & Compare

Train both models and automatically evaluate them:
```bash
bash scripts/compare_models.sh both
```

Train both and only evaluate existing models:
```bash
bash scripts/compare_models.sh both true
```

### Option 3: Sequential Training

Train XVLA first, then VLA-JEPA:
```bash
bash scripts/train_xvla.sh && bash scripts/train_vla_jepa.sh
```

---

## Evaluation Workflow

### Step 1: Evaluate on Benchmark (Optional)

After training, benchmark on simulated environments:

```bash
# XVLA
bash scripts/eval_xvla.sh

# VLA-JEPA
bash scripts/eval_vla_jepa.sh
```

### Step 2: Evaluate on Real Robot

Once satisfied with benchmark results, evaluate on the SO-101:

```bash
# XVLA on SO-101
bash scripts/eval_xvla_robot.sh

# VLA-JEPA on SO-101
bash scripts/eval_vla_jepa_robot.sh
```

**Note**: Robot evaluation:
- Collects 10 episodes of policy rollouts
- Saves dataset to HuggingFace Hub
- Allows real-time monitoring of policy behavior

### Step 3: Compare Results

Generate a comparison report:
```bash
bash scripts/compare_models.sh none  # Run evaluation only
```

---

## Expected Training Times

| Model | Time | VRAM | Notes |
|-------|------|------|-------|
| XVLA | 4-12h | 20-24GB | Train from scratch |
| VLA-JEPA | 1-4h | 24-32GB | Fine-tuning (faster!) |

## Expected Hardware

| Component | Requirement |
|-----------|-------------|
| GPU | NVIDIA A100/H100 recommended, A10/RTX4090 minimum |
| VRAM | 24GB+ (32GB recommended for VLA-JEPA) |
| Storage | 100GB for datasets + checkpoints |
| Network | Good internet for HuggingFace Hub uploads |

---

## Key Outputs

After training:
```
outputs/train/
├── xvla_pick_and_place_ring/          # XVLA training outputs
│   ├── checkpoints/                   # Model checkpoints
│   ├── logs/                          # Training logs
│   └── config.json                    # Training config
└── vla_jepa_pick_and_place_ring/      # VLA-JEPA training outputs
    ├── checkpoints/
    ├── logs/
    └── config.json
```

After evaluation:
```
outputs/eval/
├── xvla_pick_and_place_ring/          # XVLA evaluation outputs
│   ├── metrics.json                   # Evaluation metrics
│   ├── videos/                        # Generated videos
│   └── logs/                          # Eval logs
└── vla_jepa_pick_and_place_ring/      # VLA-JEPA evaluation outputs
    ├── metrics.json
    ├── videos/
    └── logs/
```

Comparison results:
```
outputs/comparison_TIMESTAMP/
├── COMPARISON_REPORT.md               # Detailed comparison
├── RESULTS_SUMMARY.txt                # Quick summary
├── timing.txt                         # Training/eval times
├── xvla_metrics.json                  # XVLA metrics
├── vla_jepa_metrics.json              # VLA-JEPA metrics
├── xvla_training.log                  # XVLA training log
└── vla_jepa_training.log              # VLA-JEPA training log
```

---

## Monitoring Training

### Check Progress in Real-Time

```bash
# Watch training logs
tail -f outputs/train/xvla_pick_and_place_ring/logs/training.log

# In another terminal
tail -f outputs/train/vla_jepa_pick_and_place_ring/logs/training.log
```

### Monitor GPU Usage

```bash
watch -n 2 nvidia-smi
```

### Check Checkpoint Progress

```bash
ls -lhS outputs/train/xvla_pick_and_place_ring/checkpoints/
```

---

## Troubleshooting

### Out of Memory (OOM) Error

**For XVLA**:
```bash
# Reduce batch size
lerobot-train \
  --dataset.repo_id=witsense-ai/so101_pick_and_place_ring \
  --policy.type=xvla \
  --batch_size=4 \
  ...
```

**For VLA-JEPA**:
```bash
# Reduce batch size or use gradient accumulation
lerobot-train \
  --dataset.repo_id=witsense-ai/so101_pick_and_place_ring \
  --policy.type=vla_jepa \
  --batch_size=2 \
  ...
```

### Training Stuck/Slow

- Check CPU/GPU utilization: `nvidia-smi`
- Reduce number of workers: `--dataloader.num_workers=0`
- Check disk I/O: `iostat -x 1`

### Policy Not Found During Evaluation

```bash
# Verify policy exists on Hub
huggingface-cli repo info witsense-ai/so101_pick_and_place_ring_policy_xvla

# Or use local checkpoint
bash scripts/eval_xvla.sh --policy.path=outputs/train/xvla_pick_and_place_ring/checkpoints/005000/pretrained_model
```

### Robot Connection Issues

```bash
# Find robot ports
lerobot-find-port

# Update env file
nano env
```

---

## Model Selection Guide

### Use XVLA if:
- ✓ You have >2000 demonstrations
- ✓ You want a smaller production model
- ✓ You're training specific to one task
- ✓ Inference latency is critical

### Use VLA-JEPA if:
- ✓ You have <1000 demonstrations
- ✓ You need better generalization
- ✓ You want faster training
- ✓ You need good out-of-distribution performance

### Use Both if:
- ✓ You want to compare performance
- ✓ You have time/compute for both
- ✓ You want an ensemble for robustness

---

## Next Steps

1. **Start training**: `bash scripts/train_xvla.sh`
2. **Monitor progress**: `tail -f outputs/train/*/logs/training.log`
3. **Evaluate on robot**: `bash scripts/eval_xvla_robot.sh`
4. **Iterate**: Collect more data, re-train, evaluate

---

## References

- **Full Guide**: Read [VLA_TRAINING_GUIDE.md](../VLA_TRAINING_GUIDE.md) for detailed information
- **LeRobot Docs**: https://huggingface.co/docs/lerobot
- **VLA-JEPA Hub**: https://huggingface.co/lerobot/VLA-JEPA-Pretrain
- **SO-101 Docs**: See project documentation

---

## Support

For issues:
1. Check script output for error messages
2. Verify environment setup: `env | grep -E 'HF_|ROBOT_'`
3. Review LeRoBot documentation
4. Check project CLAUDE.md for setup details

---

**Last Updated**: 2026-06-13
