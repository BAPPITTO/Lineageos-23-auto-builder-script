#!/usr/bin/env bash
# =============================================================================
# LineageOS build helper (lineage-23.2)
# =============================================================================
# Automates dependency installation, repo sync, proprietary blob extraction,
# optional KernelSU integration, and building (signed or unsigned).
#
# MIT License
#
# Copyright (c) 2026 Dudu-gsh
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration / globals
# ---------------------------------------------------------------------------
HERE="$(pwd)/"
LINEAGE_DIR="${HOME}/android/lineage"
REPO_BRANCH="lineage-23.2"
CORES=$(( $(nproc) - 2 ))
(( CORES < 1 )) && CORES=1

# Will be set by user prompts
EMAIL=""
NAME=""
USE_KERNELSU=false
CODENAME=""
ZIP=""
PASTA=""          # directory containing extract-files.{sh,py}
SIGNED=""

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

prompt_path() {
  # Asks for the directory that contains extract-files.sh / extract-files.py
  # (the path shown above "Extract proprietary blobs" in the device wiki)
  echo "What is written above \"Extract proprietary blobs\""
  read -rp "Please write the path here: " PASTA
}

prompt_zip() {
  echo "Please download the .zip installer first."
  echo "Where is the file?"
  echo "Example: /home/myuser/Lineage_something23.zip"
  read -rp "Paste the path here: " ZIP
}

prompt_codename() {
  echo "In the compilation steps there is a command called:"
  echo "    breakfast YourDevice"
  echo "What is the device codename? (e.g. rosemary, nx_tab)"
  read -rp "Codename: " CODENAME
  clear
  echo "This will take a while – take a nap, have a coffee, or something."
  sleep 3
}

install_dependencies() {
  echo "This will ask for sudo so that it can install the required tools."
  sudo apt update
  sudo apt install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git git-lfs gnupg gperf imagemagick protobuf-compiler python3-protobuf \
    lib32readline-dev lib32z1-dev libdw-dev libelf-dev libgnutls-dev lz4 \
    libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync \
    schedtool squashfs-tools xsltproc xxd zip zlib1g-dev python-is-python3
}

setup_repo_tool() {
  mkdir -p "${HOME}/bin"
  PATH="\( {HOME}/bin: \){PATH}"
  export PATH

  curl -fLo "${HOME}/bin/repo" https://storage.googleapis.com/git-repo-downloads/repo
  chmod a+x "${HOME}/bin/repo"
}

configure_git_and_ccache() {
  export USE_CCACHE=1
  export CCACHE_EXEC=/usr/bin/ccache

  git config --global user.email "${EMAIL}"
  git config --global user.name  "${NAME}"
  git lfs install
  git config --global trailer.changeid.key "Change-Id"

  ccache -M 30G
  ccache -o compression=true
}

sync_lineage() {
  mkdir -p "${LINEAGE_DIR}"
  cd "${LINEAGE_DIR}"

  repo init -u https://github.com/LineageOS/android.git \
            -b "${REPO_BRANCH}" \
            --git-lfs \
            --no-clone-bundle

  repo sync -c -j"${CORES}"
  clear
}

run_breakfast() {
  source build/envsetup.sh

  while ! breakfast "${CODENAME}"; do
    echo "Error: '${CODENAME}' does not exist or is unsupported."
    prompt_codename
  done
}

extract_blobs() {
  # Validate ZIP exists
  while [[ ! -f "${ZIP}" ]]; do
    echo "File not found: ${ZIP}"
    prompt_zip
  done

  # Validate extract directory exists
  while [[ ! -d "${PASTA}" ]]; do
    echo "Wrong path: ${PASTA}"
    prompt_path
  done

  cd "${PASTA}"

  if [[ -f ./extract-files.sh ]]; then
    ./extract-files.sh "${ZIP}"
  elif [[ -f ./extract-files.py ]]; then
    ./extract-files.py "${ZIP}"
  else
    echo "Important file not found (extract-files.sh or extract-files.py)!"
    exit 1
  fi
}

setup_kernelsu() {
  if [[ "${USE_KERNELSU}" != true ]]; then
    return
  fi

  cd "${HERE}"
  git clone https://github.com/EduuTech/KernelSU
  cd KernelSU
  chmod +x kernel/setup.sh

  # Return to Lineage tree and locate the device kernel directory
  cd "${LINEAGE_DIR}"
  # shellcheck disable=SC2046
  cd "\( (find kernel -type d -name " \){CODENAME}")/.."
  "${HERE}KernelSU/kernel/setup.sh"

  croot
}

build_rom() {
  croot
  clear

  read -rp "Want to compile a Signed Build? (Y/N): " SIGNED

  if [[ \( {SIGNED} =\~ ^[Yy] \) ]]; then
    cd "${HERE}"
    chmod +x sign_pls.sh
    ./sign_pls.sh "${EMAIL}"
  else
    mka bacon "${CODENAME}"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  # User identity for git
  read -rp "Enter your GitHub email (used for cloning): " EMAIL
  read -rp "Enter your Git name (can be anything): " NAME

  # Optional KernelSU
  read -rp "Do you want to enable KernelSU? (y/N): " -n 1 -r
  echo
  if [[ \( {REPLY} =\~ ^[Yy] \) ]]; then
    USE_KERNELSU=true
  else
    USE_KERNELSU=false
  fi

  # Device codename (needed later for breakfast / KernelSU / build)
  prompt_codename

  # System preparation
  install_dependencies
  setup_repo_tool
  clear
  configure_git_and_ccache
  clear

  # Source tree
  sync_lineage

  # Device configuration + proprietary blobs
  run_breakfast
  prompt_zip
  prompt_path
  extract_blobs

  # Optional KernelSU patch
  setup_kernelsu

  # Build
  build_rom
}

main "$@"
