# EcoCharge Jump Host (Bastion)

**IP:** 192.168.100.40
**OS:** Ubuntu 22.04
**Роль:** Бастіон-хост з доступом до всіх мережевих зон. Містить FLAG #6.

---

## Архітектура

Jump Host — це multi-homed сервер з інтерфейсами у трьох мережах:

| Інтерфейс | Мережа | IP | Призначення |
|------------|--------|----|-------------|
| eth0 | DMZ (192.168.100.0/24) | 192.168.100.40 | Management access |
| eth1 | Internal (192.168.20.0/24) | 192.168.20.40 | Доступ до CSMS/DB |
| eth2 | OT (172.16.0.0/24) | 172.16.0.10 | Доступ до chargers |

## Вразливості

1. **Stolen SSH Key:** Ключ `id_jumphost` знайдений на Web Server дає доступ як `operator`
2. **Multi-homed Access:** З Jump Host можна дістатися до Internal та OT мереж
3. **Pre-installed Tools:** tcpdump, nmap, psql — дозволяють sniffing та DB access
4. **FLAG #6:** `FLAG{p1v0t_m4st3r_jumb0}` — в MOTD при логіні

## Розгортання

```bash
sudo ./setup.sh
```

## Мережеві вимоги (Proxmox)

Перед запуском скрипту, VM повинна мати 3 мережевих інтерфейси:
- **net0 (eth0):** vmbr відповідний DMZ (192.168.100.0/24)
- **net1 (eth1):** vmbr відповідний Internal (192.168.20.0/24)
- **net2 (eth2):** vmbr відповідний OT (172.16.0.0/24)

## Attack Path

1. Атакуючий знаходить `/root/.ssh/id_jumphost` на Web Server (Phase 1)
2. `ssh -i id_jumphost operator@192.168.100.40` → FLAG #6
3. З Jump Host — SSH tunnel до Grafana (192.168.100.30:3000) → FLAG #5
4. З Jump Host — `psql -h 192.168.20.20` → FLAG #7
5. З Jump Host — `tcpdump -i eth2 port 8092` → FLAG #8 (OCPP sniffing)
6. З Jump Host — відправка RemoteStopTransaction → FLAG #9

## Встановлені інструменти

- `tcpdump` — перехоплення OCPP трафіку
- `nmap` — сканування мережі
- `postgresql-client` — підключення до БД
- `python3` + wscat — робота з WebSocket (OCPP)
- `curl`, `netcat`, `socat` — мережеві утиліти
