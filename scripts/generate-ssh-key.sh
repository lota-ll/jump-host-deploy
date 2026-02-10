#!/bin/bash
# ============================================================================
# Generate SSH Key Pair for Jump Host Access
# Run this ONCE, then distribute:
#   - id_jumphost (private) -> Web Server /root/.ssh/id_jumphost
#   - id_jumphost.pub (public) -> Jump Host authorized_keys (done by setup.sh)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${SCRIPT_DIR}/../ssh-keys"

mkdir -p "$KEY_DIR"

if [ -f "${KEY_DIR}/id_jumphost" ]; then
    echo "⚠️  Ключ вже існує: ${KEY_DIR}/id_jumphost"
    read -p "   Перегенерувати? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Використовуємо існуючий ключ."
        exit 0
    fi
fi

echo "Генерація SSH ключа..."
ssh-keygen -t ed25519 -f "${KEY_DIR}/id_jumphost" -N "" -C "operator@jumphost.ecocharge.internal"

echo ""
echo "✅ Ключ згенеровано!"
echo ""
echo "Файли:"
echo "  Private: ${KEY_DIR}/id_jumphost"
echo "  Public:  ${KEY_DIR}/id_jumphost.pub"
echo ""
echo "Розподіл:"
echo "  1. Web Server (192.168.250.50):"
echo "     scp ${KEY_DIR}/id_jumphost root@192.168.250.50:/root/.ssh/id_jumphost"
echo "     ssh root@192.168.250.50 'chmod 600 /root/.ssh/id_jumphost'"
echo ""
echo "  2. Jump Host (192.168.100.40):"
echo "     Ключ буде автоматично встановлено скриптом setup.sh"
echo ""
