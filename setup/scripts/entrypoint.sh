#!/bin/bash

# ==============================================================================
# Docker Container Entrypoint Script (Updated Version)
# ==============================================================================
# - Installs PyTorch (CPU or GPU)
# - Installs required Python deps
# - Downloads Stable Diffusion 3.5 + text encoders
# - Installs ComfyUI Manager (if not present)
# ==============================================================================

# --- Configuration ---
COMFYUI_DIR="/app/comfyui"
**USE_CUDA="true" # Always use GPU**

# Model paths & URLs
SD35_MODEL_PATH="$COMFYUI_DIR/models/checkpoints/sd3.5_medium.safetensors"
SD35_MODEL_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors"

CLIP_G_PATH="$COMFYUI_DIR/models/clip/sd3.5_medium/clip_g.safetensors"
CLIP_G_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/text_encoders/sd3.5_medium_clip_g.safetensors"

CLIP_L_PATH="$COMFYUI_DIR/models/clip/sd3.5_medium/clip_l.safetensors"
CLIP_L_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/text_encoders/sd3.5_medium_clip_l.safetensors"

T5_XXL_PATH="$COMFYUI_DIR/models/clip/sd3.5_medium/t5xxl_fp8_e4m3fn.safetensors"
T5_XXL_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/text_encoders/sd3.5_medium_t5xxl_fp8_e4m3fn.safetensors"

# ComfyUI Manager
COMFYUI_MANAGER_DIR="$COMFYUI_DIR/custom_nodes/ComfyUI-Manager"
COMFYUI_MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager.git"

# --- Helper Function ---
download_file() {
  local url="$1"
  local path="$2"
  local filename=$(basename "$path")

  if [ ! -f "$path" ]; then
    echo "--- Downloading $filename ---"
    mkdir -p "$(dirname "$path")"
    if [ -n "$HF_TOKEN" ]; then
      wget -c --header="Authorization: Bearer $HF_TOKEN" "$url" -O "$path"
    else
      wget -c "$url" -O "$path"
    fi
  else
    echo "--- $filename already exists. Skipping. ---"
  fi
}

# --- Start Setup ---
echo "========== ComfyUI Docker Entrypoint =========="

# 1. Git
if ! command -v git &>/dev/null; then
  echo "--- Git not found. Installing... ---"
  apt-get update && apt-get install -y git
fi

# 2. Python + Pip + Torch
echo "--- Installing Python dependencies ---"
cd "$COMFYUI_DIR"
python3 -m pip install --upgrade pip

# Select CPU or GPU PyTorch based on ENV
if [ "$USE_CUDA" = "true" ]; then
  echo "--- Installing GPU-enabled PyTorch ---"
  python3 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
else
  echo "--- Installing CPU-only PyTorch ---"
  python3 -m pip install torch torchvision torchaudio
fi

# 3. Install requirements
python3 -m pip install -r requirements.txt

# 4. Download Models
echo "--- Downloading Models ---"
download_file "$SD35_MODEL_URL" "$SD35_MODEL_PATH"
download_file "$CLIP_G_URL" "$CLIP_G_PATH"
download_file "$CLIP_L_URL" "$CLIP_L_PATH"
download_file "$T5_XXL_URL" "$T5_XXL_PATH"

# 5. Install ComfyUI Manager
if [ ! -d "$COMFYUI_MANAGER_DIR" ]; then
  echo "--- Installing ComfyUI Manager ---"
  git clone "$COMFYUI_MANAGER_REPO" "$COMFYUI_MANAGER_DIR"
else
  echo "--- ComfyUI Manager already installed ---"
fi

# 7. Run ComfyUI
echo "--- Starting ComfyUI Server ---"
exec python3 main.py --listen --port 8188
