[English](README.md) | [简体中文](README_CN.md) | [繁體中文](README_TW.md) | [日本語](README_JP.md)

# Sing-box Multi-Protocol Deployment Script

A powerful Sing-box automated deployment tool supporting SS / HY2 / TUIC / VLESS Reality / AnyTLS Reality protocols, with full relay server deployment support.

---

## ✨ Features

### 🎯 Server Deployment

- ✅ **One-click install** - Automatically deploy the latest Sing-box server
- ✅ **Auto-generate** - Auto-generate passwords and config files, Reality SNI customizable or default
- ✅ **Multi-OS support** - Alpine, Debian, Ubuntu, CentOS, RHEL, Fedora
- ✅ **Auto-start** - Systemd / OpenRC boot startup, auto-restart on crash
- ✅ **Connection IP** - Auto-detect public IP or manually input IP/DDNS hostname
- ✅ **Management tool** - Enter `candies-sb` to view node links, reset ports, control service

### 🔁 Relay Server

- ✅ **One-click generate** - Generate relay install script directly from landing server
- ✅ **Reality inbound** - Auto-deploy VLESS Reality inbound
- ✅ **Flexible port** - Auto-find free port or manually specify
- ✅ **Traffic forwarding** - Auto-forward traffic to landing server SS node
- ✅ **Full link** - Generate ready-to-use VLESS Reality client link

---

## ✅ One-click Deploy

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/candies-sven-007/proxy/main/install-multilingual.sh)
```

---

## 🔧 Management Panel

After installation, run:

```bash
candies-sb
```

Available actions:
- View node links
- Edit config file
- Reset port per protocol
- Start / Stop / Restart service
- Update Sing-box
- Generate relay server script
- Uninstall

---

## 📋 Supported Protocols

| Protocol | Transport | TLS |
|----------|-----------|-----|
| Shadowsocks 2022 | TCP/UDP | — |
| Hysteria2 | QUIC | Self-signed |
| TUIC | QUIC | Self-signed |
| VLESS Reality | TCP | Reality |
| AnyTLS Reality | TCP | Reality |

---

## 📄 License

MIT
