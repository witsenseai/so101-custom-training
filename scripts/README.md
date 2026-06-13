# SO-101 Training & Evaluation Scripts

This directory contains bash scripts for training and evaluating Vision-Language-Action (VLA) models on the SO-101 robot.

## Script Overview

### New VLA Training & Evaluation Scripts

These are the primary scripts for this project:

#### Training
- **`train_xvla.sh`** - Train XVLA model from scratch on your dataset
  - Best for: Large datasets (>2000 demos), task-specific training
  - Training time: 4-12 hours
  - Output: `outputs/train/xvla_pick_and_place_ring/`

- **`train_vla_jepa.sh`** - Fine-tune VLA-JEPA pretrained model
  - Best for: Smaller datasets, fast adaptation
  - Training time: 1-4 hours
  - Output: `outputs/train/vla_jepa_pick_and_place_ring/`

#### Evaluation (Simulation/Benchmark)
- **`eval_xvla.sh`** - Evaluate XVLA on benchmark environments
  - Collects metrics and videos
  - Output: `outputs/eval/xvla_pick_and_place_ring/`

- **`eval_vla_jepa.sh`** - Evaluate VLA-JEPA on benchmark environments
  - Collects metrics and videos
  - Output: `outputs/eval/vla_jepa_pick_and_place_ring/`

#### Evaluation (Real Robot)
- **`eval_xvla_robot.sh`** - Run XVLA inference on real SO-101 robot
  - Collects 10 episodes of policy rollouts
  - Uploads results to HF Hub
  - Requires: Robot connected and calibrated

- **`eval_vla_jepa_robot.sh`** - Run VLA-JEPA inference on real SO-101 robot
  - Collects 10 episodes of policy rollouts
  - Uploads results to HF Hub
  - Requires: Robot connected and calibrated

#### Comparison & Analysis
- **`compare_models.sh`** - Train both models and generate comparison report
  - Trains XVLA and VLA-JEPA sequentially
  - Automatically evaluates both
  - Generates timing and performance comparisons
  - Output: `outputs/comparison_TIMESTAMP/`

### Legacy Scripts

- **`train.sh`** - Original ACT model training script
- **`eval_policy.sh`** - Original policy evaluation on robot
- **`teleop.sh`** - Teleoperation script for data collection
- **`record_*.sh`** - Dataset recording scripts
- **`upload_policy.sh`** - Upload trained policy to HF Hub
- **`calibrate.sh`** - Robot calibration
- **`setup_eval.sh`** - Network setup for evaluation

## Quick Start

### 1. Train XVLA
```bash
bash scripts/train_xvla.sh
```

### 2. Train VLA-JEPA
```bash
bash scripts/train_vla_jepa.sh
```

### 3. Compare Both Models
```bash
bash scripts/compare_models.sh both
```

### 4. Evaluate on Robot
```bash
# After training and benchmarking
bash scripts/eval_xvla_robot.sh
# OR
bash scripts/eval_vla_jepa_robot.sh
```

## Workflow

### Standard Workflow

```
1. Train Models
   ├── XVLA: bash scripts/train_xvla.sh
   └── VLA-JEPA: bash scripts/train_vla_jepa.sh

2. Benchmark Evaluation (optional)
   ├── XVLA: bash scripts/eval_xvla.sh
   └── VLA-JEPA: bash scripts/eval_vla_jepa.sh

3. Real Robot Evaluation
   ├── XVLA: bash scripts/eval_xvla_robot.sh
   └── VLA-JEPA: bash scripts/eval_vla_jepa_robot.sh

4. Compare Results
   └── bash scripts/compare_models.sh none
```

### Quick Comparison Workflow

```bash
# Train both and evaluate automatically
bash scripts/compare_models.sh both

# This runs:
# 1. XVLA training
# 2. VLA-JEPA training
# 3. XVLA evaluation
# 4. VLA-JEPA evaluation
# 5. Generates comparison report
```

### Evaluation-Only Workflow

```bash
# If models are already trained
bash scripts/compare_models.sh both true
```

## Configuration

### Environment Variables

All scripts use environment variables from the `env` file:

```bash
export HF_TOKEN=...              # HuggingFace token
export HF_USER=...               # HuggingFace username
export TASK_NAME=...             # Task name
export ROBOT_LEADER_PORT=...     # Leader robot port
export ROBOT_FOLLOWER_PORT=...   # Follower robot port
```

### Custom Training Parameters

You can extend any script with additional `lerobot-train` parameters:

```bash
# Example: Lower learning rate
lerobot-train \
  --dataset.repo_id=... \
  --policy.type=xvla \
  --learning_rate=1e-5 \
  --batch_size=4 \
  ...
```

## Directory Structure

```
scripts/
├── README.md                      # This file
├── QUICK_START.md                # Quick start guide
├── train_xvla.sh                 # Train XVLA
├── train_vla_jepa.sh             # Train VLA-JEPA
├── eval_xvla.sh                  # Benchmark eval XVLA
├── eval_vla_jepa.sh              # Benchmark eval VLA-JEPA
├── eval_xvla_robot.sh            # Robot eval XVLA
├── eval_vla_jepa_robot.sh        # Robot eval VLA-JEPA
├── compare_models.sh             # Compare both models
└── [legacy scripts]              # Previous scripts
```

## Outputs

### Training Outputs
```
outputs/train/
├── xvla_pick_and_place_ring/
│   ├── checkpoints/              # Model checkpoints
│   ├── logs/                     # Training logs
│   └── config.json               # Config
└── vla_jepa_pick_and_place_ring/
    ├── checkpoints/
    ├── logs/
    └── config.json
```

### Evaluation Outputs
```
outputs/eval/
├── xvla_pick_and_place_ring/
│   ├── metrics.json              # Performance metrics
│   ├── videos/                   # Generated videos
│   └── logs/                     # Eval logs
└── vla_jepa_pick_and_place_ring/
    ├── metrics.json
    ├── videos/
    └── logs/
```

### Comparison Outputs
```
outputs/comparison_TIMESTAMP/
├── COMPARISON_REPORT.md          # Detailed comparison
├── RESULTS_SUMMARY.txt           # Quick summary
├── timing.txt                    # Training/eval times
├── xvla_metrics.json             # Metrics
├── vla_jepa_metrics.json         # Metrics
├── xvla_training.log             # Training logs
└── vla_jepa_training.log         # Training logs
```

## Monitoring

### Real-Time Training Progress

```bash
# XVLA training
tail -f outputs/train/xvla_pick_and_place_ring/logs/training.log

# VLA-JEPA training
tail -f outputs/train/vla_jepa_pick_and_place_ring/logs/training.log
```

### GPU Usage

```bash
watch -n 2 nvidia-smi
```

### Checkpoint Progress

```bash
ls -lhS outputs/train/xvla_pick_and_place_ring/checkpoints/
```

## Troubleshooting

### Training Fails: CUDA Out of Memory

Reduce batch size:
```bash
# Edit the script and add:
--batch_size=4
```

Or modify the training command directly:
```bash
lerobot-train \
  --dataset.repo_id=... \
  --policy.type=xvla \
  --batch_size=2 \
  ...
```

### Evaluation Hangs

- Check GPU memory: `nvidia-smi`
- Reduce eval batch size: `--eval.batch_size=1`
- Try on CPU: `--policy.device=cpu`

### Robot Connection Issues

```bash
# Find available ports
lerobot-find-port

# Update env file
nano env

# Verify ports
cat env | grep ROBOT
```

### Policy Not Found

```bash
# Verify on Hub
huggingface-cli repo info witsense-ai/so101_pick_and_place_ring_policy_xvla

# Or use local checkpoint
--policy.path=outputs/train/xvla_pick_and_place_ring/checkpoints/005000/pretrained_model
```

## Performance Tips

### Faster Training
- Use VLA-JEPA (fine-tuning is faster than training from scratch)
- Enable mixed precision: `--policy.use_amp=true`
- Use gradient accumulation for larger effective batch sizes

### Better Results
- Collect more data (>2000 demos)
- Use XVLA for task-specific training
- Train longer (more epochs)
- Monitor validation metrics

### GPU Efficiency
- Balance batch size vs VRAM
- Use gradient checkpointing: `--gradient_checkpointing=true`
- Enable torch.compile for inference

## Documentation

- **Quick Start**: `QUICK_START.md`
- **Full Guide**: `../VLA_TRAINING_GUIDE.md`
- **LeRoBot Docs**: https://huggingface.co/docs/lerobot
- **VLA-JEPA**: https://huggingface.co/lerobot/VLA-JEPA-Pretrain

## Model References

### XVLA
- Latest VLA variant in LeRoBot
- Trained from scratch on task
- Best for: Large datasets, task-specific training

### VLA-JEPA
- Pretrained on large diverse robotic data
- Fine-tuning on task
- Variants:
  - `lerobot/VLA-JEPA-LIBERO` - LIBERO-90 tasks
  - `lerobot/VLA-JEPA-Pretrain` - General pretraining (recommended)
  - `lerobot/VLA-JEPA-SimplerEnv` - Simpler environments

## Support

For issues:
1. Check script error output
2. Verify environment: `env | grep -E 'HF_|ROBOT_'`
3. Review LeRoBot documentation
4. Check project `CLAUDE.md` for setup

---

**Created**: 2026-06-13
**Last Updated**: 2026-06-13

For more information, see `QUICK_START.md` and `../VLA_TRAINING_GUIDE.md`.
