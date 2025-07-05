#!/bin/bash

# ==============================================================================
# Native Ubuntu Docker Installation Script (setup.sh)
# ==============================================================================
# This script installs Docker Engine and Docker Compose on a native Ubuntu
# system by setting up Docker's official APT repository.
# It will ask for your password to run commands with 'sudo'.
# ==============================================================================

# --- Helper Function for Headers ---
header() {
    echo ""
    term_width=$(tput cols)
    padding=$(printf '%0.1s' ={1..500})
    printf "\e[32m%.*s\n\e[0m" "$term_width" "$padding"
    printf "\e[1;32m%*s\n\e[0m" $(( ( term_width + ${#1} ) / 2 )) "$1"
    printf "\e[32m%.*s\n\e[0m" "$term_width" "$padding"
}

# --- Script Logic ---

header "STEP 1: CHECKING FOR EXISTING DOCKER INSTALLATION"
if command -v docker &> /dev/null; then
    echo "✅ Docker appears to be already installed. Skipping installation."
    echo "Ensuring user is in the docker group..."
    if ! groups "$USER" | grep -q '\bdocker\b'; then
        echo "Adding current user ($USER) to the 'docker' group..."
        sudo usermod -aG docker "$USER"
        echo "‼️ You must log out and log back in for this change to take effect."
    fi
    exit 0
fi

header "STEP 2: SETTING UP DOCKER'S OFFICIAL APT REPOSITORY"
echo "This script will now set up and install Docker. It will ask for your administrator password."

# Update apt and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo "✅ Docker repository setup complete."

header "STEP 3: INSTALLING DOCKER ENGINE AND COMPOSE"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "✅ Docker packages installed."

header "STEP 4: POST-INSTALLATION SETUP"
# Create the docker group if it doesn't exist
if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi

# Add your user to the docker group
echo "Adding current user ($USER) to the 'docker' group to run Docker without sudo."
sudo usermod -aG docker "$USER"

echo ""
echo -e "\e[1;32m======================== INSTALLATION COMPLETE ========================\e[0m"
echo -e "✅ Docker is now installed on your system."
echo -e "‼️ \e[1;33mIMPORTANT: You must LOG OUT and LOG BACK IN for the group changes to apply.\e[0m"
echo -e "After you log back in, you can run Docker commands without needing 'sudo'."
