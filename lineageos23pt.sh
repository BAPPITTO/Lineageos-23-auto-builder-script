#!/usr/bin/env bash
# =============================================================================
# Auxiliar de compilação do LineageOS (lineage-23.2)
# =============================================================================
# Automatiza a instalação de dependências, sincronização do repo, extração de
# blobs proprietários, integração opcional do KernelSU e a compilação
# (assinada ou não assinada).
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
# Configuração / variáveis globais
# ---------------------------------------------------------------------------
HERE="$(pwd)/"
LINEAGE_DIR="${HOME}/android/lineage"
REPO_BRANCH="lineage-23.2"
CORES=$(( $(nproc) - 2 ))
(( CORES < 1 )) && CORES=1

# Serão definidas pelos prompts do usuário
EMAIL=""
NAME=""
USE_KERNELSU=false
CODENAME=""
ZIP=""
PASTA=""          # diretório que contém extract-files.{sh,py}
SIGNED=""

# ---------------------------------------------------------------------------
# Funções auxiliares
# ---------------------------------------------------------------------------

prompt_path() {
  # Pergunta o diretório que contém extract-files.sh / extract-files.py
  # (o caminho mostrado acima de "Extract proprietary blobs" no wiki do dispositivo)
  echo "O que está escrito acima de \"Extract proprietary blobs\""
  read -rp "Por favor, escreva o caminho aqui: " PASTA
}

prompt_zip() {
  echo "Por favor, baixe o instalador .zip primeiro."
  echo "Onde está o arquivo?"
  echo "Exemplo: /home/meuusuario/Lineage_algo23.zip"
  read -rp "Cole o caminho aqui: " ZIP
}

prompt_codename() {
  echo "Nos passos de compilação existe um comando chamado:"
  echo "    breakfast SeuDispositivo"
  echo "Qual é o codinome do dispositivo? (ex.: rosemary, nx_tab)"
  read -rp "Codinome: " CODENAME
  clear
  echo "Isso vai demorar um pouco – tire um cochilo, tome um café ou algo assim."
  sleep 3
}

install_dependencies() {
  echo "Isso vai pedir sudo para instalar as ferramentas necessárias."
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
    echo "Erro: '${CODENAME}' não existe ou não é suportado."
    prompt_codename
  done
}

extract_blobs() {
  # Valida se o ZIP existe
  while [[ ! -f "${ZIP}" ]]; do
    echo "Arquivo não encontrado: ${ZIP}"
    prompt_zip
  done

  # Valida se o diretório de extração existe
  while [[ ! -d "${PASTA}" ]]; do
    echo "Caminho errado: ${PASTA}"
    prompt_path
  done

  cd "${PASTA}"

  if [[ -f ./extract-files.sh ]]; then
    ./extract-files.sh "${ZIP}"
  elif [[ -f ./extract-files.py ]]; then
    ./extract-files.py "${ZIP}"
  else
    echo "Arquivo importante não encontrado (extract-files.sh ou extract-files.py)!"
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

  # Volta para a árvore do Lineage e localiza o diretório do kernel do dispositivo
  cd "${LINEAGE_DIR}"
  # shellcheck disable=SC2046
  cd "\( (find kernel -type d -name " \){CODENAME}")/.."
  "${HERE}KernelSU/kernel/setup.sh"

  croot
}

build_rom() {
  croot
  clear

  read -rp "Deseja compilar um build Assinado? (S/N): " SIGNED

  if [[ \( {SIGNED} =\~ ^[SsYy] \) ]]; then
    cd "${HERE}"
    chmod +x sign_pls.sh
    ./sign_pls.sh "${EMAIL}"
  else
    mka bacon "${CODENAME}"
  fi
}

# ---------------------------------------------------------------------------
# Principal
# ---------------------------------------------------------------------------

main() {
  # Identidade do usuário para o git
  read -rp "Digite seu e-mail do GitHub (usado para clonar): " EMAIL
  read -rp "Digite seu nome no Git (pode ser qualquer coisa): " NAME

  # Codinome do dispositivo (necessário depois para breakfast / KernelSU / build)
  prompt_codename

  # Preparação do sistema
  install_dependencies
  setup_repo_tool
  clear
  configure_git_and_ccache
  clear

  # Árvore de código-fonte
  sync_lineage

  # Configuração do dispositivo + blobs proprietários
  run_breakfast
  prompt_zip
  prompt_path
  extract_blobs

  # Patch opcional do KernelSU
  setup_kernelsu

  # Compilação
  build_rom
}

main "$@"
