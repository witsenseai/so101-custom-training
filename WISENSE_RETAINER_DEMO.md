# SO-101 Arms — LeRobot v0.4.4 Full Pipeline
### Jetson Orin · LeRobot 0.4.4 · Python ≥ 3.10

> All commands use the installed CLI entry points (`lerobot-*`).  
> Secrets live in `~/.env` — always load it first.

---

## 0. Session Bootstrap

```bash
# Load secrets
set -a && source ~/.env && set +a

# ~/.env must contain:
# HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
# HF_USER=your-hf-username

# Activate virtual environment
source ~/lerobot/.venv/bin/activate   # adjust path if different

# Verify install
lerobot-info

# Set task variables — edit once per task
export TASK_NAME="container_door_retainer_catch"
export TASK_DESC="Rotate and pull retainer catch to open freight container door latch"
export DATASET_REPO="${HF_USER}/so101_${TASK_NAME}"
export POLICY_REPO="${HF_USER}/so101_${TASK_NAME}_pi0fast"
export OUTPUT_DIR="${HOME}/outputs/train/pi0fast_${TASK_NAME}"
export PRETRAINED="physical-intelligence/pi0-fast"   # gated — request access first
```

---

## Step 1 — Find Ports of Connected SO-101 Arms

> Plug arms in **one at a time**. The script is interactive — it detects the newly added port.

### 1a. Run the port finder — repeat for each arm

```bash
# Unplug both arms first, then plug in the LEADER arm only:
lerobot-find-port
# → Prints e.g.  Found port: /dev/ttyUSB0
export LEADER_PORT=/dev/ttyUSB0

# Unplug leader, plug in FOLLOWER arm only:
lerobot-find-port
# → Prints e.g.  Found port: /dev/ttyUSB1
export FOLLOWER_PORT=/dev/ttyUSB1
```

### 1b. Fix permission denied (if needed)

```bash
sudo usermod -aG dialout $USER
# Log out and back in, OR for immediate fix in current session:
sudo chmod 666 $LEADER_PORT $FOLLOWER_PORT
```

### 1c. (Optional) Find connected cameras

```bash
lerobot-find-cameras
# Note the index or path of each camera for use in --robot.cameras below
```

---

## Step 2 — Record Teleoperation Dataset

### 2a. (First time only) Calibrate LEADER arm

```bash
lerobot-calibrate \
  --teleop.type=so101_leader \
  --teleop.port=$LEADER_PORT \
  --teleop.id=leader
```

### 2b. (First time only) Calibrate FOLLOWER arm

```bash
lerobot-calibrate \
  --robot.type=so101_follower \
  --robot.port=$FOLLOWER_PORT \
  --robot.id=follower
```

### 2c. Record the dataset

```bash
lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$FOLLOWER_PORT \
  --robot.id=follower \
  --robot.cameras="{top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}}" \
  --teleop.type=so101_leader \
  --teleop.port=$LEADER_PORT \
  --teleop.id=leader \
  --dataset.repo_id=${DATASET_REPO} \
  --dataset.single_task="${TASK_DESC}" \
  --dataset.num_episodes=50 \
  --dataset.streaming_encoding=true \
  --dataset.encoder_threads=2 \
  --display_data=true
```

> **Key flags:**  
> `--dataset.num_episodes` — total demos to record (aim ≥ 50 for meaningful generalisation)  
> `--dataset.single_task` — natural-language task description stored in the dataset  
> `--dataset.streaming_encoding=true` — encodes video frames to disk in real time (saves RAM on Orin)  
> `--robot.cameras` — add a wrist camera: `wrist: {type: opencv, index_or_path: 1, width: 640, height: 480, fps: 30}`

### 2d. (Optional) Teleoperate without recording — for practice

```bash
lerobot-teleoperate \
  --robot.type=so101_follower \
  --robot.port=$FOLLOWER_PORT \
  --robot.id=follower \
  --teleop.type=so101_leader \
  --teleop.port=$LEADER_PORT \
  --teleop.id=leader \
  --display_data=true
```

### 2e. Inspect a recorded episode

```bash
lerobot-dataset-viz \
  --repo-id ${DATASET_REPO} \
  --episode-index 0
```

---

## Step 3 — Push Dataset to HuggingFace Hub

```bash
# Login
huggingface-cli login --token "${HF_TOKEN}"

# LeRobot saves the dataset to $HF_LEROBOT_HOME/<repo_id>
# Default location: ~/.cache/lerobot/<HF_USER>/<dataset_name>
huggingface-cli upload "${DATASET_REPO}" \
  ~/.cache/lerobot/${DATASET_REPO} \
  --repo-type dataset \
  --token "${HF_TOKEN}"
```

> If you set a custom `HF_LEROBOT_HOME`, replace `~/.cache/lerobot` with that path.

### Verify the dataset is live

```bash
python - <<'EOF'
import os
from datasets import load_dataset
ds = load_dataset(os.environ["DATASET_REPO"], split="train", streaming=True)
sample = next(iter(ds))
print("Keys:", list(sample.keys()))
EOF
```

---

## Step 4 — Train a π0-fast Policy

> ⚠️ **Orin memory note:** π0-fast uses PaliGemma-2B + action expert 300M.  
> Requires ~20 GB GPU memory for training.  
> AGX Orin 64GB → `batch_size=4` works. AGX Orin 32GB → try `batch_size=2`.  
> Add `--policy.dtype=bfloat16` if you hit CUDA OOM.

> ⚠️ **Gated model:** Request access to `physical-intelligence/pi0-fast` on HuggingFace  
> before running — your `HF_TOKEN` must be authorised on that repo.

```bash
lerobot-train \
  --policy.path=${PRETRAINED} \
  --dataset.repo_id=${DATASET_REPO} \
  --output_dir=${OUTPUT_DIR} \
  --batch_size=4 \
  --steps=80000 \
  --save_freq=10000 \
  --log_freq=200 \
  --eval_freq=20000 \
  --wandb.enable=false \
  --seed=42
```

### Monitor GPU on Orin

```bash
# In a second terminal:
watch -n 2 tegrastats
```

### Resume a stopped training run

```bash
lerobot-train \
  --config_path=${OUTPUT_DIR}/train_config.json \
  --resume=true
```

### Identify the best checkpoint

```bash
ls ${OUTPUT_DIR}/checkpoints/
# e.g. 010000/  020000/  030000/  last/
# Use the checkpoint with the lowest eval loss from the training log.
# The 'last/' symlink always points to the most recent save.
export BEST_CKPT="${OUTPUT_DIR}/checkpoints/last/pretrained_model"
```

---

## Step 5 — Evaluate Trained Policy (Autonomous Operation)

> In LeRobot v0.4.4, real-robot autonomous evaluation is done via `lerobot-record`  
> with `--policy.path` and **no teleop args**. The follower arm runs the policy autonomously  
> and episodes are saved locally for review.

```bash
export EVAL_DATASET="${HF_USER}/so101_${TASK_NAME}_eval"

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=$FOLLOWER_PORT \
  --robot.id=follower \
  --robot.cameras="{top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}}" \
  --policy.path=${BEST_CKPT} \
  --dataset.repo_id=${EVAL_DATASET} \
  --dataset.single_task="${TASK_DESC}" \
  --dataset.num_episodes=10 \
  --dataset.streaming_encoding=true \
  --display_data=true
```

> No `--teleop.*` args → policy drives the follower; leader arm not needed.

### Replay an eval episode on hardware

```bash
lerobot-replay \
  --robot.type=so101_follower \
  --robot.port=$FOLLOWER_PORT \
  --robot.id=follower \
  --repo-id ${EVAL_DATASET} \
  --episode-index 0
```

### Visualise eval episodes

```bash
lerobot-dataset-viz \
  --repo-id ${EVAL_DATASET} \
  --episode-index 0
```

---

## Step 6 — Push Trained Policy to HuggingFace Hub

```bash
# Push the best checkpoint as a model repo
huggingface-cli upload "${POLICY_REPO}" \
  "${BEST_CKPT}" \
  --repo-type model \
  --token "${HF_TOKEN}"
```

### Add a model card

```bash
cat > /tmp/model_card.md << EOF
---
license: apache-2.0
tags:
  - lerobot
  - pi0_fast
  - so101
  - robotics
  - ${TASK_NAME}
---

# SO-101 π0-fast Policy — ${TASK_NAME}

Fine-tuned from [\`${PRETRAINED}\`](https://huggingface.co/${PRETRAINED})  
on the [\`${DATASET_REPO}\`](https://huggingface.co/datasets/${DATASET_REPO}) dataset.

**Task:** ${TASK_DESC}  
**Hardware:** SO-101 follower arm · Jetson Orin  
**Framework:** LeRobot v0.4.4

## Usage
\`\`\`bash
lerobot-record \\
  --robot.type=so101_follower \\
  --robot.port=/dev/ttyUSB1 \\
  --robot.id=follower \\
  --policy.path=${POLICY_REPO} \\
  --dataset.repo_id=${HF_USER}/so101_${TASK_NAME}_run \\
  --dataset.single_task="${TASK_DESC}" \\
  --dataset.num_episodes=5
\`\`\`
EOF

huggingface-cli upload "${POLICY_REPO}" \
  /tmp/model_card.md README.md \
  --repo-type model \
  --token "${HF_TOKEN}"
```

### Verify model is live

```bash
python - <<'EOF'
import os
from huggingface_hub import HfApi
api = HfApi()
info = api.model_info(os.environ["POLICY_REPO"])
print("Live:", info.id, "| Modified:", info.last_modified)
EOF
```

---

## Quick Reference — Variables

| Variable | Purpose | Example |
|---|---|---|
| `HF_TOKEN` | HuggingFace write token | `hf_xxx...` |
| `HF_USER` | HuggingFace username | `suvarna-witsense` |
| `LEADER_PORT` | Leader arm USB port | `/dev/ttyUSB0` |
| `FOLLOWER_PORT` | Follower arm USB port | `/dev/ttyUSB1` |
| `TASK_NAME` | Short task slug | `container_door_retainer_catch` |
| `TASK_DESC` | Natural-language task description | `"Rotate and pull..."` |
| `DATASET_REPO` | HF dataset repo id | `${HF_USER}/so101_${TASK_NAME}` |
| `POLICY_REPO` | HF model repo id | `${HF_USER}/so101_${TASK_NAME}_pi0fast` |
| `PRETRAINED` | Base π0-fast checkpoint | `physical-intelligence/pi0-fast` |
| `OUTPUT_DIR` | Local training output directory | `~/outputs/train/pi0fast_...` |
| `BEST_CKPT` | Path to best checkpoint | `${OUTPUT_DIR}/checkpoints/last/pretrained_model` |

## CLI Entry Points Reference

| Command | Purpose |
|---|---|
| `lerobot-find-port` | Interactively identify USB port of an arm |
| `lerobot-find-cameras` | List available cameras by index |
| `lerobot-find-joint-limits` | Discover min/max joint angles |
| `lerobot-setup-motors` | Configure Dynamixel motor IDs |
| `lerobot-calibrate` | Calibrate a robot or teleoperator |
| `lerobot-teleoperate` | Teleop without recording |
| `lerobot-record` | Record dataset OR run autonomous policy |
| `lerobot-replay` | Replay a recorded episode on hardware |
| `lerobot-dataset-viz` | Visualise dataset episodes |
| `lerobot-edit-dataset` | Trim or delete episodes from a dataset |
| `lerobot-train` | Fine-tune a policy |
| `lerobot-eval` | Evaluate policy in simulation (gym env only) |
| `lerobot-info` | Print LeRobot install info |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Permission denied /dev/ttyUSB*` | `sudo chmod 666 /dev/ttyUSBx` |
| Port not found by `lerobot-find-port` | Unplug all arms, plug in one at a time, rerun |
| `HfHubHTTPError 401` | Re-run `huggingface-cli login --token $HF_TOKEN` |
| `HfHubHTTPError 403` on pi0-fast download | Request gated model access on HF Hub first |
| CUDA OOM during training | Reduce `--batch_size` to 2; add `--policy.dtype=bfloat16` |
| Policy drives arm erratically | Re-calibrate; verify camera index matches recording config |
| USB latency causing stuttering | `echo 1 \| sudo tee /sys/bus/usb-serial/devices/ttyUSB*/latency_timer` |
| Dataset not found after recording | Check `$HF_LEROBOT_HOME` — default is `~/.cache/lerobot` |