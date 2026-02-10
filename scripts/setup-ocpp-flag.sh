#!/bin/bash
# ============================================================================
# Setup FLAG #8 - OCPP Sniffing Evidence
# Creates a pre-captured OCPP traffic sample that contains the flag
# This simulates what the attacker would find via tcpdump on eth2
# ============================================================================

echo "=============================================="
echo "Setting up FLAG #8 - OCPP Sniffing"
echo "=============================================="

# Create evidence directory
mkdir -p /home/operator/evidence

# Create a readable OCPP capture log (simulated)
cat > /home/operator/evidence/ocpp-capture-sample.txt << 'CAPEOF'
=== OCPP 1.6 Traffic Capture (eth0 - via Firewall) ===
Date: $(date)
Interface: eth0 (192.168.100.40, traffic routed via firewall)
Filter: host 192.168.20.20 and port 8092

--- Packet 1: BootNotification ---
172.16.0.40:43210 -> 192.168.20.20:8092 [WebSocket TEXT]
[2,"boot-001","BootNotification",{"chargePointVendor":"CyberRange","chargePointModel":"EVerest Simulator","chargePointSerialNumber":"CP001","firmwareVersion":"1.0"}]

--- Packet 2: BootNotification Response ---
192.168.20.20:8092 -> 172.16.0.40:43210 [WebSocket TEXT]
[3,"boot-001",{"status":"Accepted","currentTime":"2024-12-15T10:00:00Z","interval":60}]

--- Packet 3: StatusNotification ---
172.16.0.40:43210 -> 192.168.20.20:8092 [WebSocket TEXT]
[2,"status-001","StatusNotification",{"connectorId":1,"errorCode":"NoError","status":"Available","timestamp":"2024-12-15T10:00:05Z"}]

--- Packet 4: Heartbeat ---
172.16.0.40:43210 -> 192.168.20.20:8092 [WebSocket TEXT]
[2,"hb-001","Heartbeat",{}]

--- Packet 5: Authorize (RFID Card) ---
172.16.0.40:43210 -> 192.168.20.20:8092 [WebSocket TEXT]
[2,"auth-001","Authorize",{"idTag":"ECOCHARGE001"}]

--- Packet 6: Authorize Response ---
192.168.20.20:8092 -> 172.16.0.40:43210 [WebSocket TEXT]
[3,"auth-001",{"idTagInfo":{"status":"Accepted","expiryDate":"2025-12-31T23:59:59Z"}}]

--- Packet 7: StartTransaction ---
172.16.0.40:43210 -> 192.168.20.20:8092 [WebSocket TEXT]
[2,"tx-001","StartTransaction",{"connectorId":1,"idTag":"ECOCHARGE001","meterStart":0,"timestamp":"2024-12-15T10:01:00Z"}]

--- Packet 8: StartTransaction Response ---
192.168.20.20:8092 -> 172.16.0.40:43210 [WebSocket TEXT]
[3,"tx-001",{"transactionId":12345,"idTagInfo":{"status":"Accepted"}}]

--- Packet 9: MeterValues ---
172.16.0.40:43210 -> 192.168.20.20:8092 [WebSocket TEXT]
[2,"mv-001","MeterValues",{"connectorId":1,"transactionId":12345,"meterValue":[{"timestamp":"2024-12-15T10:05:00Z","sampledValue":[{"value":"2500","measurand":"Energy.Active.Import.Register","unit":"Wh"},{"value":"230","measurand":"Voltage","unit":"V"},{"value":"16","measurand":"Current.Import","unit":"A"}]}]}]

=== ANALYSIS ===
WARNING: All OCPP 1.6 traffic is transmitted in CLEARTEXT over WebSocket (ws://)
No TLS/SSL encryption detected on port 8092.
Captured credentials: idTag=ECOCHARGE001 (valid RFID)
Transaction data visible: transactionId=12345, energy consumption

FLAG{cl34rt3xt_0cpp_sn1ff1ng}

=== END CAPTURE ===
CAPEOF

chown operator:operator /home/operator/evidence/ocpp-capture-sample.txt
chmod 644 /home/operator/evidence/ocpp-capture-sample.txt

# Hint file
cat > /home/operator/evidence/README.txt << 'READMEEOF'
OCPP Traffic Analysis Evidence
==============================

This directory contains captured OCPP traffic from the OT network.

To capture live traffic (single interface via firewall):
  sudo tcpdump -i eth0 -A 'host 192.168.20.20 and port 8092'

Or use active OCPP interaction via wscat:
  wscat -c ws://192.168.20.20:8092/CP001

NOTE: OCPP 1.6 (CP001 on 172.16.0.40) uses unencrypted WebSocket.
      OCPP 2.0.1 (CP002 on 172.16.0.60) uses Security Profile 1.

The difference in security is clearly visible in captured traffic.
READMEEOF
chown operator:operator /home/operator/evidence/README.txt

echo "✅ FLAG #8 evidence створено в /home/operator/evidence/"
echo ""
