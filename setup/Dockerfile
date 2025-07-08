# Start with an official, slim Python 3.12 image based on Debian
FROM python:3.12-slim-bookworm

# Set a working directory inside the image
WORKDIR /app

# Install system dependencies like git and wget
RUN apt-get update && apt-get install -y git wget && rm -rf /var/lib/apt/lists/*

# Clone the ComfyUI repository into the current directory (/app)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Clone the ComfyUI-Manager directly into the custom_nodes folder
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git ./custom_nodes/ComfyUI-Manager

# Install the correct PyTorch version for CUDA 12.1
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# This command finds the problem line and removes the specific version requirement
RUN sed -i '/comfyui-workflow-templates/s/==.*//' requirements.txt

# Install ComfyUI's other Python requirements
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port ComfyUI runs on
EXPOSE 8188

# This is the default command to run when the container starts
CMD ["python3", "main.py", "--listen"]
