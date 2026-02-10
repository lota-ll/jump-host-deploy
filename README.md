# EcoCharge Jump Host (Bastion)

**IP:** 192.168.100.40  
**OS:** Ubuntu 22.04  
**Роль:** Бастіон-хост з доступом до Internal та OT мереж через Firewall VM.  
**Variant:** Single Interface via Firewall

---

## Архітектура

Jump Host має **один мережевий інтерфейс** у DMZ.  
Доступ до Internal та OT досягається через **static routes** на Firewall VM.

| Інтерфейс | IP | Мережа | Доступ |
|-----------|-----|--------|--------|
| eth0 | 192.168.100.40/24 | DMZ | Прямий |
| — | via 192.168.100.1 | Internal (192.168.20.0/24) | Через Firewall |
| — | via 192.168.100.1 | OT (172.16.0.0/24) | Через Firewall |

### Порівняння з multi-homed варіантом

| | Multi-homed (3 NIC) | Single Interface (цей варіант) |
|---|---|---|
| Інтерфейси | eth0, eth1, eth2 | eth0 тільки |
| IP forwarding | Увімкнено на Jump Host | На Firewall VM |
| tcpdump OT | `-i eth2 port 8092` | `-i eth0 host 192.168.20.20` |
| OCPP interaction | Direct sniff | wscat або tcpdump на eth0 |
| Proxmox | 3 vmbr | 1 vmbr |

---

## Вразливості

1. **Stolen SSH Key:** Ключ `id_jumphost` знайдений на Web Server дає доступ як `operator`
2. **Routed Access:** Через Jump Host та firewall rules можна дістатися до Internal та OT
3. **Pre-installed Tools:** tcpdump, nmap, psql, wscat — дозволяють sniffing та DB access
4. **FLAG #6:** `FLAG{p1v0t_m4st3r_jumb0}` — в MOTD при логіні

---

## Розгортання

### 1. Jump Host VM (1 NIC у Proxmox)

```bash
sudo ./setup.sh
```

### 2. Обов'язково: правила на Firewall VM

```bash
# Jump Host <-> Internal (CSMS)
iptables -I FORWARD 1 -s 192.168.100.40 -d 192.168.20.0/24 -j ACCEPT
iptables -I FORWARD 2 -s 192.168.20.0/24 -d 192.168.100.40 -j ACCEPT

# Jump Host <-> OT (Chargers)
iptables -I FORWARD 3 -s 192.168.100.40 -d 172.16.0.0/24 -j ACCEPT
iptables -I FORWARD 4 -s 172.16.0.0/24 -d 192.168.100.40 -j ACCEPT

# Зберегти
iptables-save > /etc/iptables/rules.v4
```

### 3. Перевірка

```bash
ssh -i ssh-keys/id_jumphost operator@192.168.100.40
ping 192.168.20.20   # CSMS
ping 172.16.0.40     # CP001
```

---

## Attack Path

1. Атакуючий знаходить `/root/.ssh/id_jumphost` на Web Server (Phase 1)
2. `ssh -i id_jumphost operator@192.168.100.40` → **FLAG #6** (MOTD)
3. З Jump Host — SSH tunnel до Grafana → **FLAG #5**
4. З Jump Host — `psql -h 192.168.20.20` → **FLAG #7**
5. З Jump Host — `wscat -c ws://192.168.20.20:8092/CP001` → **FLAG #8** (OCPP)
6. З Jump Host — RemoteStopTransaction → **FLAG #9**

### Про OCPP sniffing (FLAG #8)

У цьому варіанті атакуючий не бачить OT трафік напряму.  
Замість passive sniffing використовується **active OCPP interaction**:

```bash
# Підключитися до CSMS від імені charger
wscat -c ws://192.168.20.20:8092/CP001

# Або перехопити трафік що йде через eth0
tcpdump -i eth0 -A 'host 192.168.20.20 and port 8092'
```

---

## Встановлені інструменти

- `tcpdump` — перехоплення мережевого трафіку (на eth0)
- `nmap` — сканування мережі
- `postgresql-client` — підключення до CSMS DB
- `wscat` — WebSocket клієнт для OCPP
- `curl`, `netcat`, `socat` — мережеві утиліти
- `python3` — скрипти для автоматизації
