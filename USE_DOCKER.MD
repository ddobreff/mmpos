# 🚀 Docker & Docker Compose Installation Guide

This guide explains how to install **Docker Engine** and **Docker Compose** on:

- [Ubuntu / Debian-based](#ubuntu--debian-based)
- [RHEL / CentOS / Fedora](#rhel--centos--fedora-rpm-based)
- [Arch Linux / Manjaro](#arch-linux--manjaro)

---

## 📦 Ubuntu / Debian-based

### 1. Uninstall old versions (optional)
```
sudo apt remove docker docker-engine docker.io containerd runc
```
### 2. Update and install dependencies
```
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```
### 3. Add Docker's GPG key and repo
```
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
### 4. Install Docker Engine & CLI
```
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
### 5. Enable and test Docker
```
sudo systemctl enable --now docker
sudo docker run hello-world
```
📦 RHEL / CentOS / Fedora (RPM-based)
### 1. Uninstall old versions (optional)
```
sudo yum remove docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine
```
### 2. Install required packages
```
sudo dnf -y install dnf-plugins-core
```
### 3. Add Docker repository
```
sudo dnf config-manager \
    --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```
For Fedora, use: https://download.docker.com/linux/fedora/docker-ce.repo

### 4. Install Docker Engine & CLI
```
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
### 5. Start and test Docker
```
sudo systemctl enable --now docker
sudo docker run hello-world
```
📦 Arch Linux / Manjaro
### 1. Install Docker and Compose
```
sudo pacman -Syu docker docker-compose
```
### 2. Enable and start Docker
```
sudo systemctl enable --now docker
```
### 3. Run test container
```
sudo docker run hello-world
```
👤 Post-Install (Optional)
To run Docker without sudo:

```
sudo usermod -aG docker $USER
newgrp docker
```
✅ Verify Installation
Run:

```
docker --version
docker compose version
```
📚 Useful Links
Docker Engine Docs: https://docs.docker.com/engine/install/

Compose Plugin Docs: https://docs.docker.com/compose/

NVIDIA GPU Support: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html


## Now follow guide here to use mmp-agent docker image:

MMP Agent: https://hub.docker.com/r/ddobreff/mmp-agent
