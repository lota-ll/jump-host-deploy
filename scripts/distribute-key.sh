#!/bin/bash
# ============================================================================
# Distribute SSH Key to Web Server
# Copies id_jumphost private key to Web Server so it can be found by attacker
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="${SCRIPT_DIR}/../ssh-keys/id_jumphost"
WEB_SERVER="${1:-192.168.250.50}"

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Ключ не знайдено: $KEY_FILE"
    echo "   Спочатку запустіть: ./generate-ssh-key.sh"
    exit 1
fi

echo "=============================================="
echo "Розподіл SSH ключа на Web Server"
echo "=============================================="
echo ""
echo "Web Server: $WEB_SERVER"
echo "Key file:   $KEY_FILE"
echo ""

# Copy to Web Server
echo "[1/2] Копіювання ключа на Web Server..."
scp "$KEY_FILE" "root@${WEB_SERVER}:/root/.ssh/id_jumphost"

echo "[2/2] Встановлення прав..."
ssh "root@${WEB_SERVER}" "chmod 600 /root/.ssh/id_jumphost && echo '✅ Ключ встановлено'"

echo ""
echo "=============================================="
echo "✅ Ключ розміщено на Web Server"
echo "=============================================="
echo ""
echo "Перевірка (з Web Server):"
echo "  ssh -i /root/.ssh/id_jumphost operator@192.168.100.40"
echo ""
echo "Attack path:"
echo "  1. Атакуючий отримує RCE на Web Server"
echo "  2. Знаходить /root/.ssh/id_jumphost"
echo "  3. ssh -i id_jumphost operator@192.168.100.40"
echo "  4. FLAG #6!"
echo ""
