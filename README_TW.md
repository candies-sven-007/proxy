[English](README.md) | [简体中文](README_CN.md) | [繁體中文](README_TW.md) | [日本語](README_JP.md)

# Sing-box 多協議一鍵部署腳本

一個強大的 Sing-box 自動化部署工具，支援 SS / HY2 / TUIC / VLESS Reality / AnyTLS Reality 協議自選部署和線路機 VLESS Reality 中轉的完整解決方案。

---

## ✨ 主要特性

### 🎯 部署機功能

- ✅ **一鍵安裝** - 自動部署 Sing-box 最新服務端
- ✅ **自動生成** - 自動生成金鑰和設定檔，Reality 自選或預設 SNI
- ✅ **多系統支援** - 支援 Alpine、Debian、Ubuntu、CentOS、RHEL、Fedora 等作業系統
- ✅ **開機自啟** - 自動設定 Systemd / OpenRC 開機自啟，崩潰自動重啟服務端
- ✅ **連線 IP** - 自動取得公網 IP 或手動輸入連線 IP/DDNS 網域名稱，並生成客戶端連結
- ✅ **管理工具** - 輸入 `candies-sb` 指令進入管理介面查看節點連結、重置連接埠、服務端控制等功能

### 🔁 線路機功能

- ✅ **一鍵生成** - 從落地機直接生成線路機安裝腳本
- ✅ **Reality 入站** - 自動部署 VLESS Reality 入站
- ✅ **靈活連接埠** - 支援自動尋找空閒連接埠或手動指定
- ✅ **流量轉發** - 自動轉發流量至落地機 SS 節點
- ✅ **完整連結** - 生成可用的 VLESS Reality 客戶端連結

---

## ✅ 一鍵部署指令

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/candies-sven-007/proxy/main/install-multilingual.sh)
```

---

## 🔧 管理面板

安裝完成後執行：

```bash
candies-sb
```

支援功能：
- 查看節點連結
- 編輯設定檔
- 按協議重置連接埠
- 啟動 / 停止 / 重啟服務
- 更新 Sing-box
- 生成線路機腳本
- 解除安裝

---

## 📋 支援協議

| 協議 | 傳輸層 | TLS |
|------|--------|-----|
| Shadowsocks 2022 | TCP/UDP | — |
| Hysteria2 | QUIC | 自簽憑證 |
| TUIC | QUIC | 自簽憑證 |
| VLESS Reality | TCP | Reality |
| AnyTLS Reality | TCP | Reality |

---

## 📄 開源授權

MIT
