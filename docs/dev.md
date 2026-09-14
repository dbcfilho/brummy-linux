# Brummy — setup dev (espelha o Debian do dbrum)

Instalado por padrão (`./install.sh`); pule com `--no-dev`.

| Debian (atual) | Brummy (Arch) |
|---|---|
| Java 25 Temurin via SDKMAN, sem Maven/Gradle | `jdk-openjdk` (latest) + `jdk21-openjdk` (LTS), `maven`, `gradle`; `mise` (já no base) p/ versões por projeto |
| Node 24 via nvm + pnpm/yarn/vercel/railway/eas/gemini CLIs | `nodejs`, `npm` (corepack traz pnpm/yarn); CLIs globais instale por projeto |
| Python 3.13 sistema | `python`, `python-pip`, `python-virtualenv`, `uv` |
| Docker 29 + compose, sem k8s | `docker` (base) + `kubectl`, `k9s`, `kustomize`, `helm` |
| Postgres 17 local + clients psql/mysql/sqlite3 | `postgresql` (initdb + enable automáticos) + `mariadb-clients`, `sqlite`, `redis`, `dbeaver` |
| Android Studio flatpak (sem SDK) | `--with-android`: `android-studio` (AUR) + `android-tools`, `android-udev`, `scrcpy` |
| Postman flatpak, VSCodium flatpak | `postman-bin` (AUR), `vscodium-bin` (AUR base) |
| git/gh/tmux/jq/curl/make/cmake/gcc | base + `git-delta`, `direnv`, `httpie` |

## Pós-install úteis

- Java: `sudo archlinux-java status` — default vai para latest (espelha seu 25); troque com `sudo archlinux-java set java-21-openjdk`.
- Por projeto prefira `mise` (`mise use java@21 node@24`) em vez de trocar o Java global.
- Postgres: cluster em `/var/lib/postgres/data`, locale `pt_BR.UTF-8`; crie seu user/db como faz no Debian (`createuser`/`createdb`).
- `brummy doctor` agora tem seção `dev` + `laptop` separadas.
