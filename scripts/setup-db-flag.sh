#!/bin/bash
# ============================================================================
# Insert FLAG #7 into CitrineOS Database
# Run this ONCE on a machine that has access to 192.168.20.20:5432
# (Jump Host or CSMS server itself)
# ============================================================================

CSMS_HOST="${1:-192.168.20.20}"
DB_USER="citrine"
DB_PASS="citrine"
DB_NAME="citrine"

echo "=============================================="
echo "Inserting FLAG #7 into CitrineOS Database"
echo "=============================================="

# Check connection
PGPASSWORD=$DB_PASS psql -h $CSMS_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Не вдається підʼєднатися до PostgreSQL на $CSMS_HOST"
    exit 1
fi

echo "✅ Підключено до PostgreSQL"

# Create a table with flag (if it doesn't exist)
PGPASSWORD=$DB_PASS psql -h $CSMS_HOST -U $DB_USER -d $DB_NAME << 'SQLEOF'
-- Table for internal system flags/secrets
CREATE TABLE IF NOT EXISTS "SystemSecrets" (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    description VARCHAR(500),
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert FLAG #7 (if not exists)
INSERT INTO "SystemSecrets" (key, value, description)
SELECT 'ctf_flag_7', 'FLAG{d4t4b4s3_full_dump}', 'Internal CTF flag - database access verification'
WHERE NOT EXISTS (
    SELECT 1 FROM "SystemSecrets" WHERE key = 'ctf_flag_7'
);

-- Also insert some realistic-looking secrets
INSERT INTO "SystemSecrets" (key, value, description)
SELECT 'ocpp_ws_secret', 'ws_4uth_t0k3n_2024', 'WebSocket authentication token for OCPP connections'
WHERE NOT EXISTS (SELECT 1 FROM "SystemSecrets" WHERE key = 'ocpp_ws_secret');

INSERT INTO "SystemSecrets" (key, value, description)
SELECT 'rfid_master_key', 'EC:0C:H4:RG:3M:4S:T3:R0', 'Master RFID key for all charging stations'
WHERE NOT EXISTS (SELECT 1 FROM "SystemSecrets" WHERE key = 'rfid_master_key');

INSERT INTO "SystemSecrets" (key, value, description)
SELECT 'api_internal_token', 'int3rn4l_4p1_t0k3n_ec0ch4rg3', 'Internal API authentication token'
WHERE NOT EXISTS (SELECT 1 FROM "SystemSecrets" WHERE key = 'api_internal_token');

-- Verify
SELECT * FROM "SystemSecrets";
SQLEOF

echo ""
echo "✅ FLAG #7 та секрети додано до бази даних"
echo ""
echo "Перевірка:"
echo "  PGPASSWORD=citrine psql -h $CSMS_HOST -U citrine -d citrine -c 'SELECT * FROM \"SystemSecrets\";'"
echo ""
