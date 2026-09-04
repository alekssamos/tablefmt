#!/usr/bin/env bash
# Установка tablefmt как команды. Запуск: bash install.sh
set -euo pipefail
cd "$(dirname "$0")"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

cp tablefmt "$BIN_DIR/tablefmt"
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
