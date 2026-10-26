# README do Auto Builder do LineageOS 23

<div align="center">

# Script Auto Builder do LineageOS 23

<p align="center">
  <a href="https://github.com/EduuTech/Lineageos-23-auto-builder-script/stargazers"><img src="https://img.shields.io/github/stars/EduuTech/Lineageos-23-auto-builder-script?style=flat-square&logo=github" alt="GitHub Stars"></a>
  <a href="https://github.com/EduuTech/Lineageos-23-auto-builder-script/network/members"><img src="https://img.shields.io/github/forks/EduuTech/Lineageos-23-auto-builder-script?style=flat-square&logo=github" alt="GitHub Forks"></a>
  <a href="https://github.com/EduuTech/Lineageos-23-auto-builder-script/blob/main/LICENSE"><img src="https://img.shields.io/github/license/EduuTech/Lineageos-23-auto-builder-script?style=flat-square" alt="License"></a>
</p>

[English](README.md)

</div>

---

Bem-vindo ao repositório! Este script automatiza a compilação do LineageOS 23, e pretendo adicionar suporte para outras versões no futuro.

> **Nota:** O KernelSU é suportado apenas em dispositivos não-GKI com versões de kernel inferiores a 4.14. Esta ferramenta foi projetada exclusivamente para o LineageOS 23.

Se quiser contribuir, sinta-se à vontade para abrir uma issue ou enviar um pull request!

---

## O que isso faz?
Ele instala as ferramentas e dependências necessárias, inicializa o repositório, gerencia a sincronização, extrai blobs proprietários, integra o KernelSU opcional e compila a sua ROM.

## Como Começar

### Opção 1: Usando o Git (Recomendado)
```bash
git clone https://github.com/EduuTech/Lineageos-23-auto-builder-script.git
cd Lineageos-23-auto-builder-script
./menu.sh
```

### Opção 2: Via Download de ZIP
```bash
curl -L https://github.com/EduuTech/Lineageos-23-auto-builder-script/archive/refs/heads/main.zip -o lineage-builder.zip
unzip lineage-builder.zip
cd Lineageos-23-auto-builder-script-main
./menu.sh
```

---

## Requisitos de Sistema Recomendados
* **SO:** Ubuntu 26.06 ou Debian mais recente (x64). Veja a [Lista de Sistemas Operacionais Suportados](OS_LIST).
* **RAM:** Mínimo de 16 GB
* **CPU:** 8 núcleos
* **Armazenamento:** SSD de 1 TB (HDDs funcionam, mas espere tempos de compilação significativamente mais lentos)

> [!WARNING]
> Por favor, não execute scripts auxiliares diretamente com o bash, pois isso causará erros. Sempre use o script do menu principal (`./menu.sh`).

---

## Nota do Autor
Criei isso por puro tédio. Não testei completamente todos os casos extremos porque não tenho um hardware de PC adequado — na verdade, escrevi e gerenciei todo este projeto diretamente de um dispositivo Android! ;D

---

## ✅ Tarefas Pendentes
- [x] Adicionar suporte ao KernelSU
- [ ] Adicionar suporte ao KernelSU GKI
- [x] Adicionar uma forma de gerar builds assinadas (Ainda em refinamento)

---

[Licença](LICENSE)
