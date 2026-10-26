# LineageOS 23 Auto Builder README

<div align="center">

# LineageOS 23 Auto Builder Script

[![GitHub stars](https://img.shields.io/github/stars/EduuTech/Lineageos-23-auto-builder-script?style=social)](https://github.com/EduuTech/Lineageos-23-auto-builder-script/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/EduuTech/Lineageos-23-auto-builder-script?style=social)](https://github.com/EduuTech/Lineageos-23-auto-builder-script/network/members)
[![GitHub license](https://img.shields.io/github/license/EduuTech/Lineageos-23-auto-builder-script)](LICENSE)

[Português-BR](README_PT.md) | [English](README.md)

</div>

---

Welcome to the repository! This script automates building LineageOS 23, and I plan to add support for other versions down the line.

> **Note:** KernelSU is only supported on non-GKI devices with kernel versions below 4.14. This tool is designed exclusively for LineageOS 23.

If you want to contribute, feel free to open an issue or submit a pull request!

---

## What does this do?
It installs the required tools and dependencies, initializes the repo, handles syncing, extracts proprietary blobs, integrates optional KernelSU, and builds your ROM.

## How to Get Started

### Option 1: Using Git (Recommended)
```bash
git clone https://github.com/EduuTech/Lineageos-23-auto-builder-script.git
cd Lineageos-23-auto-builder-script
./menu.sh
```

### Option 2: Via ZIP Download
```bash
curl -L https://github.com/EduuTech/Lineageos-23-auto-builder-script/archive/refs/heads/main.zip -o lineage-builder.zip
unzip lineage-builder.zip
cd Lineageos-23-auto-builder-script-main
./menu.sh
```

---

## Recommended System Requirements
* **OS:** Ubuntu 26.06 or latest Debian (x64). See the [Supported OS List](OS_LIST.md).
* **RAM:** 16GB minimum
* **CPU:** 8 cores
* **Storage:** 1TB SSD (HDDs work, but expect significantly slower compilation times)

> [!WARNING]
> Please do not run auxiliary scripts directly with bash, as it will cause errors. Always use the main menu script (`./menu.sh`).

---

## Author's Note
I created this out of sheer boredom. I haven't fully tested every edge case because I don't have proper PC hardware - I actually wrote and managed this entire project directly from an Android device! ;D

---

## ✅ To-Do
- [x] Add support for KernelSU
- [ ] Add support for KernelSU GKI
- [x] Add a way to build signed builds (Still being refined)

---

[License](LICENSE)
