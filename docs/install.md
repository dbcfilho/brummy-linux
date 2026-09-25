# Instalar o Brummy — 3 caminhos

O Brummy hoje é uma **camada pós-instalação** (igual o Omarchy do DHH: você instala um
Arch base e roda **um comando** que deixa tudo pronto). A ISO "pronta, só clicar"
é o próximo nível (v1.1, com archiso + Calamares) — chega lá.

## Caminho A (recomendado agora): Arch oficial + archinstall

A ISO oficial do Arch já vem com instalador guiado por menu — sem particionar na mão:

1. Baixe a ISO em archlinux.org, crie a VM no Boxes (ou pen drive no PC real)
2. No boot da ISO, digite: `archinstall`
3. Menu guiado: idioma pt_BR, disco (apague tudo / particionamento automático,
   **sistema de arquivos btrfs** — é o que liga os snapshots, veja `docs/snapshots.md`), perfil
   `minimal` ou `desktop → Hyprland` (tanto faz — o Brummy refaz por cima),
   usuário + sudo, rede NetworkManager. Confirma e espera.
4. Reinicie no sistema instalado, passe a pasta `brummy-linux` pra dentro
   (pasta compartilhada do Boxes, `scp`, ou `git clone` se já publicou no GitHub)
5. Um comando só:

```bash
cd brummy-linux && ./install.sh
```

Pronto: perfis, dev, boot, tudo automático. É o "sh" — mas é **um**, não vinte.

## Caminho B: EndeavourOS (instalador gráfico de verdade)

Se não quiser nem ver o `archinstall`: instale o **EndeavourOS** (Arch com Calamares
gráfico, igual Ubuntu) e rode o mesmo comando do passo 5. O Brummy funciona em
qualquer base Arch. Ideal pro T430 e pra quem quer zero terminal na instalação.

## Caminho C (v1.1): ISO do Brummy

Com `archiso` + Calamares dá pra gerar uma ISO que já instala tudo com o Brummy
dentro — aí sim "pronto, só clicar". Requer montar e testar num Arch real, então
fica pra depois do teste em VM do V1.

## Levar os arquivos pra VM

- **Boxes:** Devices → Shared Folder, ou arraste via `scp`:
  `scp -r brummy-linux/ usuario@ip-da-vm:~`
- **GitHub (recomendado):** é só
  `git clone https://github.com/dbcfilho/brummy-linux.git && cd brummy-linux && ./install.sh`
  em qualquer máquina.
