#!/bin/bash

# ==============================================================================
# Docker Container Entrypoint Script (Final Corrected Version)
# ==============================================================================
# This script runs INSIDE the pre-built ComfyUI container.
# It installs dependencies and downloads models before launching the app.
# ==============================================================================

# --- Configuration ---
# These paths match the volume mounts in docker-compose.yml for the universonic/comfyui image
COMFYUI_DIR="/app/comfyui"

SD35_MODEL_PATH="$COMFYUI_DIR/models/checkpoints/sd3.5_medium.safetensors"
SD35_MODEL_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors"

# --- CORRECTED URLs for Text Encoders ---
CLIP_G_PATH="$COMFYUI_DIR/models/clip/sd3.5_medium/clip_g.safetensors"
CLIP_G_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/text_encoders/sd3.5_medium_clip_g.safetensors"

CLIP_L_PATH="$COMFYUI_DIR/models/clip/sd3.5_medium/clip_l.safetensors"
CLIP_L_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/text_encoders/sd3.5_medium_clip_l.safetensors"

T5_XXL_PATH="$COMFYUI_DIR/models/clip/sd3.5_medium/t5xxl_fp8_e4m3fn.safetensors"
T5_XXL_URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/text_encoders/sd3.5_medium_t5xxl_fp8_e4m3fn.safetensors"

# --- Helper function for cleaner output ---
download_file() {
  local url="$1"
  local path="$2"
  local filename=$(basename "$path")
  
  if [ ! -f "$path" ]; then
    echo "--- Downloading $filename... (This may take a while) ---"
    mkdir -p "$(dirname "$path")"
    # Use wget with an Authorization header if HF_TOKEN is set
    if [ -n "$HF_TOKEN" ]; then
        wget -c --header="Authorization: Bearer $HF_TOKEN" "$url" -O "$path"
    else
        wget -c "$url" -O "$path"
    fi
  else
    echo "--- $filename found. Skipping download. ---"
  fi
}

# --- Logic ---

# 1. Install Python Dependencies
echo "--- Installing/Verifying Python dependencies from requirements.txt ---"
cd "$COMFYUI_DIR"
pip install -r requirements.txt

# 2. Download all required models
echo "--- Checking AI Models ---"
download_file "$SD35_MODEL_URL" "$SD35_MODEL_PATH"
download_file "$CLIP_G_URL" "$CLIP_G_PATH"
download_file "$CLIP_L_URL" "$CLIP_L_PATH"
download_file "$T5_XXL_URL" "$T5_XXL_PATH"

# 3. Launch ComfyUI
echo "--- Starting ComfyUI ---"
exec python3 main.py --listen --port 8188
