[English](README.md) | [简体中文](README_CN.md) | [繁體中文](README_TW.md) | [日本語](README_JP.md)

# Sing-box 多协议一键部署脚本

一个强大的 Sing-box 自动化部署工具，支持 SS / HY2 / TUIC / VLESS Reality / AnyTLS Reality 协议自选部署和线路机 VLESS Reality 中转的完整解决方案。

---

## ✨ 主要特性

### 🎯 部署机功能

- ✅ **一键安装** - 自动部署 Sing-box 最新服务端
- ✅ **自动生成** - 自动生成密钥和配置文件，Reality 自选或默认 SNI
- ✅ **多系统支持** - 支持 Alpine、Debian、Ubuntu、CentOS、RHEL、Fedora 等操作系统
- ✅ **开机自启** - 自动配置 Systemd / OpenRC 开机自启，崩溃自动拉起服务端
- ✅ **连接 IP** - 自动获取公网 IP 或手动输入连接 IP/DDNS 域名，并生成客户端链接
- ✅ **管理工具** - 输入 `candies-sb` 指令进入管理界面查看节点链接、重置端口、服务端控制等功能

### 🔁 线路机功能

- ✅ **一键生成** - 从落地机直接生成线路机安装脚本
- ✅ **Reality 入站** - 自动部署 VLESS Reality 入站
- ✅ **灵活端口** - 支持自动寻找空闲端口或手动指定
- ✅ **流量转发** - 自动转发流量到落地机 SS 节点
- ✅ **完整链接** - 生成可用的 VLESS Reality 客户端链接

---

## ✅ 一键部署命令

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/candies-sven-007/proxy/main/install-multilingual.sh)
```

---

## 🔧 管理面板

安装完成后执行：

```bash
candies-sb
```

支持功能：
- 查看节点链接
- 编辑配置文件
- 按协议重置端口
- 启动 / 停止 / 重启服务
- 更新 Sing-box
- 生成线路机脚本
- 卸载

---

## 📋 支持协议

| 协议 | 传输层 | TLS |
|------|--------|-----|
| Shadowsocks 2022 | TCP/UDP | — |
| Hysteria2 | QUIC | 自签证书 |
| TUIC | QUIC | 自签证书 |
| VLESS Reality | TCP | Reality |
| AnyTLS Reality | TCP | Reality |

---

## 📄 开源协议

MIT
