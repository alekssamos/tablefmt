#!/usr/bin/env bash
# Установка tablefmt как команды. Запуск: bash install.sh
set -euo pipefail
REPO="alekssamos/tablefmt"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

# Источник скрипта: локальный файл при запуске из клона, иначе скачивание.
if [[ -f "$(dirname "$0")/tablefmt" ]]; then
    src="$(dirname "$0")/tablefmt"
else
    src="$(mktemp)"
    trap 'rm -f "$src"' EXIT
    echo "Скачивание tablefmt…"
    curl -LsSf "${RAW}/tablefmt" -o "$src"
fi

cp "$src" "$BIN_DIR/tablefmt"
chmod +x "$BIN_DIR/tablefmt"

# Добавляем в PATH, если ещё нет.
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    for rc in "${HOME}/.bashrc" "${HOME}/.profile"; do
        if [[ -f "$rc" ]] && ! grep -q "$BIN_DIR" "$rc"; then
            printf '\n# tablefmt\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
            echo "PATH добавлен в $rc"
        fi
    done
fi

echo "tablefmt установлен: $BIN_DIR/tablefmt"
echo "Проверка:"
"$BIN_DIR/tablefmt" --version
