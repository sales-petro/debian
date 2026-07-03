# Criar usuário admin no Debian

Guia para criar um usuário com privilégios de administrador (`sudo`) no Debian.

## Pré-requisitos

- Acesso root ou um usuário que já esteja no grupo `sudo`
- Comandos executados com `sudo` quando indicado

## Opção 1 — Script rápido

Edite as variáveis, salve em um arquivo temporário e execute:

```bash
sudo bash <<'EOF'
set -euo pipefail

USERNAME="nome-do-usuario"
PASSWORD="senha-segura"

if id "$USERNAME" &>/dev/null; then
  echo "Usuário $USERNAME já existe — atualizando senha e grupo sudo..."
else
  useradd -m -s /bin/bash "$USERNAME"
  echo "Usuário $USERNAME criado."
fi

echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

echo "OK: $USERNAME está no grupo sudo."
EOF
```

## Opção 2 — Comandos manuais

```bash
# Criar usuário com home e shell bash
sudo useradd -m -s /bin/bash nome-do-usuario

# Definir senha (será solicitada de forma interativa)
sudo passwd nome-do-usuario

# Conceder sudo
sudo usermod -aG sudo nome-do-usuario
```

No Debian, o grupo de administradores é `sudo` (não `wheel`).

## Verificar

```bash
id nome-do-usuario
groups nome-do-usuario
```

O grupo `sudo` deve aparecer na lista.

Testar privilégios (como o novo usuário):

```bash
su - nome-do-usuario
sudo whoami
```

Deve retornar `root`.

## Segurança

- Use senhas fortes; evite deixar credenciais em arquivos versionados no git.
- Prefira `passwd` interativo em vez de `chpasswd` com senha em texto plano no script.
- Remova scripts temporários após o uso.
