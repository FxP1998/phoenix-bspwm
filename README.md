# 🪽 Phoenix-BSPWM Architecture

> [!CAUTION]
> **DEVELOPMENT BUILD: STRICTLY USE AT YOUR OWN RISK**
> This repository is currently in active development and is not production-ready. The system architecture, installation scripts, and configurations are hardcoded for specific hardware (HP Laptop 15-bs0xx / Intel Skylake). Deploying these dotfiles onto a different machine without auditing the configurations will likely result in broken X11 sessions, network failures, or boot loops. Do not blindly execute these scripts.

## ⚙️ Overview
A hyper-minimal, zero-friction Arch Linux window management environment built on X11 and BSPWM. Engineered for maximum hardware efficiency, direct-to-desktop boot times, and a unified aesthetic.

## 🎨 Theme Matrix
* **Palette:** Catppuccin Mocha
* **Primary Accent:** Red (`#f38ba8`)
* **Base Background:** (`#1e1e2e`)

## 🛠️ Core Stack
* **Window Manager:** `bspwm` + `sxhkd`
* **Status Bar:** `polybar` (Dynamic Wi-Fi/Ethernet auto-collapsing)
* **Application Launcher:** `rofi` (Custom layout)
* **Terminals:** `alacritty` & `kitty`
* **Compositor:** `picom` 
* **Security:** `i3lock-color` (Frosted blur integration)
* **File Manager:** `yazi` (Routed via `nvim`)

## 🚀 Installation
*(The `install.sh` deployment script is currently under construction.)*

---
**Author:** M. H. IMAM (FxP1998)
