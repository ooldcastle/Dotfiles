#!/bin/bash
# Legt alle Public Keys aus einem Git-Repo in ~/.ssh/authorized_keys ab
# Verwendung: ./install-pubkeys.sh [ziel-user]

set -euo pipefail

# ──────────────── Konfiguration ────────────────
REPO_URL="https://github.com/ooldcastle/Dotfiles.git"
PUBKEY_PATH="pubkeys/ssh"           # Pfad im Repo
TARGET_USER="${1:-$(whoami)}"       # Optionaler Ziel-User als Argument
# ───────────────────────────────────────────────

TARGET_HOME=$(eval echo "~${TARGET_USER}")
AUTH_KEYS="${TARGET_HOME}/.ssh/authorized_keys"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "[*] Klone Repo ..."
git clone --depth=1 --quiet "$REPO_URL" "$TMPDIR/repo"

KEY_DIR="$TMPDIR/repo/$PUBKEY_PATH"

if [ ! -d "$KEY_DIR" ]; then
  echo "[!] Pfad '$PUBKEY_PATH' nicht im Repo gefunden." >&2
  exit 1
fi

# SSH-Verzeichnis & authorized_keys anlegen falls nicht vorhanden
install -d -m 700 -o "$TARGET_USER" "${TARGET_HOME}/.ssh"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown "$TARGET_USER" "$AUTH_KEYS"

ADDED=0
SKIPPED=0

for keyfile in "$KEY_DIR"/*.pub; do
  [ -f "$keyfile" ] || continue
  while IFS= read -r key; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    if grep -qF "$key" "$AUTH_KEYS" 2>/dev/null; then
      echo "  [~] Bereits vorhanden: $(basename "$keyfile")"
      ((SKIPPED++))
    else
      echo "$key" >> "$AUTH_KEYS"
      echo "  [+] Hinzugefügt: $(basename "$keyfile")"
      ((ADDED++))
    fi
  done < "$keyfile"
done

echo ""
echo "[✓] Fertig: ${ADDED} Key(s) hinzugefügt, ${SKIPPED} bereits vorhanden."
echo "    Datei: $AUTH_KEYS"
