#!/usr/bin/env bash
# =============================================================================
# Menu de seleção de idioma + lançador do LineageOS 23 builder
# =============================================================================
# Pergunta o idioma (Português / English), pergunta se deseja KernelSU e
# chama o script correspondente (lineageos23pt.sh ou lineageos23en.sh)
# passando a variável de ambiente USE_KERNELSU.
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
# Funções auxiliares
# ---------------------------------------------------------------------------

mostrar_boas_vindas() {
  clear
  echo "Olá e bem-vindo ao meu menu"
  sleep 1
  echo "Hello and welcome to my menu"
  sleep 1
  echo
  echo "Escolha uma língua / Choose one language"
  echo
  echo "1) Português"
  echo "2) English"
  echo
  echo "Aviso: escreva 1 para Português ou 2 para English"
  sleep 1
  echo "Warning: write 1 for Portuguese or 2 for English"
  sleep 1
}

perguntar_kernelsu_pt() {
  echo
  echo "Você vai querer adicionar KernelSU ao seu kernel?"
  echo "Ele é da versão de suporte sem GKI para 4.14 para baixo."
  read -rp "(S/N): " KERNELSU
}

perguntar_kernelsu_en() {
  echo
  echo "Do you want to add KernelSU to your kernel?"
  echo "It is the non-GKI support version for 4.14 and below."
  read -rp "(Y/N): " KERNELSU
}

executar_builder() {
  local script="$1"
  local usar_kernelsu="$2"

  if [[ ! -f "${script}" ]]; then
    echo "Erro: script '${script}' não encontrado no diretório atual."
    echo "Error: script '${script}' not found in the current directory."
    exit 1
  fi

  chmod +x "${script}"
  USE_KERNELSU="${usar_kernelsu}" ./"${script}"

}

# ---------------------------------------------------------------------------
# Principal
# ---------------------------------------------------------------------------

main() {
  mostrar_boas_vindas

  read -rp "Escreva / Write: " lang

  case "${lang}" in
    1)
      # ---------- Português ----------
      perguntar_kernelsu_pt

      if [[ \( {KERNELSU} =\~ ^[Ss] \) ]]; then
        echo "Tá bom."
        executar_builder "lineageos23pt.sh" "true"
      else
        echo "Bem-vindo ao meu LineageOS 23 builder"
        executar_builder "lineageos23pt.sh" "false"
      fi

      echo "Agora você tem um build do LineageOS 23"
      ;;

    2)
      # ---------- English ----------
      perguntar_kernelsu_en

      if [[ \( {KERNELSU} =\~ ^[Yy] \) ]]; then
        echo "Okay"
        executar_builder "lineageos23en.sh" "true"
      else
        echo "Welcome to my LineageOS 23 builder"
        executar_builder "lineageos23en.sh" "false"
      fi

      echo "Now you have a build of LineageOS 23"
      ;;

    *)
      echo "Não entendi, meu fi."
      echo "I don't understand."
      exit 1
      ;;
  esac
}

main "$@"
