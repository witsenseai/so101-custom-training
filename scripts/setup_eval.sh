#!/bin/bash
# setup_env.sh — run once on a fresh machine

# 1. Install Miniforge (if conda not available)
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh -b
source ~/miniforge3/bin/activate

# 2. Create conda environment
conda create -y -n lerobot python=3.10
conda activate lerobot

# 3. Install ffmpeg
conda install -y -c conda-forge ffmpeg

# 4. Clone and install LeRobot with feetech support (SO101)
git clone https://github.com/huggingface/lerobot.git ~/lerobot
cd ~/lerobot
pip install -e ".[feetech]"

# 5. Login to HuggingFace
huggingface-cli login

# 6. Clone custom training scripts
git clone https://github.com/witsenseai/so101-custom-training.git ~/so101-custom-training

echo "Setup complete!"
echo "Next: cd ~/so101-custom-training && cp .env.example .env && edit .env with your values"