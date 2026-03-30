# 🛡️ SystemVault - Advanced Linux Maintenance & DevOps Suite

**SystemVault** is a script useful, unified shell utility designed to optimize, secure, and set up your Linux desktop and development environment. It consolidates multiple system tweaks, tool installations, and DevOps configurations into a single, high-performance interactive interface.

---

## 🚀 Key Features

### 🛠️ System Optimization (Tweaks)
- **Kernel Tuning**: Advanced `sysctl` configurations for swappiness, inotify, and network throughput.
- **SSD/NVMe Performance**: Automated TRIM scheduling and I/O scheduler optimization.
- **GNOME Speed-Up**: One-click animation removal and interface responsiveness fixes.
- **Memory Management**: Automated ZRAM setup for efficient memory usage.

### 📦 Tool Installation
- **CLI Essentials**: Git, Htop, Preload, Curl, and Build-Essential.
- **ZSH & Oh My Zsh**: Automated installation of a modern shell environment.
- **Containerization**: Full Docker & Docker Compose setup with user group management.
- **Snap/Flatpak Maintenance**: Automated cache and old revision cleanup.

### ☸️ DevOps Environment (K8s & Cloud Native)
- **Kubernetes Kit**: One-click install for `kubectl` and `helm`.
- **Local Clusters**: Automated K3s installation for lightweight local development.
- **Cloud Native Tools**: Quick access to monitoring tools like `K9s` and `bottom`.

### 🔍 Debugging & Maintenance
- **Diagnostic Reports**: Generate comprehensive system health logs in seconds.
- **Cache Clearing**: Safe resets for GNOME Shell, mesa shader caches, and journal logs.
- **Safe Recovery**: Automated terminal-based diagnostic collection for boot/graphic issues.

---

## 🖥️ How to Use

### Prerequisites
- **Ubuntu/Debian-based system** (Optimized for Ubuntu 22.04/24.04).
- **sudo** access.

### Running SystemVault

1.  **Clone the repository** (or download the script):
    ```bash
    git clone https://github.com/yourusername/system-vault.git
    cd system-vault
    ```

2.  **Make the script executable**:
    ```bash
    chmod +x system-vault.sh
    ```

3.  **Run with sudo**:
    ```bash
    sudo ./system-vault.sh
    ```

---

## ⚡ One-Click Optimization
For users in a hurry, use **Option 5** in the main menu. It applies a curated set of performance and maintenance tasks instantly, including:
- Kernel parameter optimization.
- SSD TRIM enabling.
- Apt cleanup and cache purging.
- System journal vacuuming (7-day retention).

---

## 📁 File Structure & Backups
- **Logs**: Detailed run logs are stored in `/var/log/system-vault`.
- **Backups**: System configurations (sysctl, GNOME settings) are backed up to `/var/backups/system-vault` before any modification.

---

## 🤝 Contributing
Feel free to fork this project, report issues, or suggest new features via pull requests.

---

## 📜 License
This project is licensed under the MIT License.

---
> Made with ❤️ by **Antigravity AI**

<div> 
  <a href="https://instagram.com/nifferr_" target="_blank"><img src="https://img.shields.io/badge/-Instagram-%23E4405F?style=for-the-badge&logo=instagram&logoColor=white" target="_blank"></a>
</div>
