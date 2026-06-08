[English](README.md) | [简体中文](README_CN.md) | [繁體中文](README_TW.md) | [日本語](README_JP.md)

# Sing-box マルチプロトコル ワンクリックデプロイスクリプト

SS / HY2 / TUIC / VLESS Reality / AnyTLS Reality プロトコルの自動デプロイと、リレーサーバーの VLESS Reality 中継に対応した強力な Sing-box 自動化ツールです。

---

## ✨ 主な機能

### 🎯 サーバーデプロイ

- ✅ **ワンクリックインストール** - 最新の Sing-box サーバーを自動デプロイ
- ✅ **自動生成** - パスワードと設定ファイルを自動生成、Reality SNI はカスタムまたはデフォルト
- ✅ **マルチOS対応** - Alpine、Debian、Ubuntu、CentOS、RHEL、Fedora に対応
- ✅ **自動起動** - Systemd / OpenRC による起動時自動起動、クラッシュ時自動再起動
- ✅ **接続IP** - パブリックIPの自動取得またはIP/DDNSホスト名の手動入力に対応
- ✅ **管理ツール** - `candies-sb` コマンドでノードリンク確認・ポートリセット・サービス制御が可能

### 🔁 リレーサーバー

- ✅ **ワンクリック生成** - 着地サーバーからリレーサーバーインストールスクリプトを直接生成
- ✅ **Reality インバウンド** - VLESS Reality インバウンドを自動デプロイ
- ✅ **柔軟なポート** - 空きポートの自動検索または手動指定に対応
- ✅ **トラフィック転送** - 着地サーバーの SS ノードへ自動転送
- ✅ **完全なリンク** - すぐに使える VLESS Reality クライアントリンクを生成

---

## ✅ ワンクリックデプロイコマンド

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/candies-sven-007/proxy/main/install-multilingual.sh)
```

---

## 🔧 管理パネル

インストール後に実行：

```bash
candies-sb
```

利用可能な操作：
- ノードリンクの確認
- 設定ファイルの編集
- プロトコルごとのポートリセット
- サービスの起動 / 停止 / 再起動
- Sing-box のアップデート
- リレーサーバースクリプトの生成
- アンインストール

---

## 📋 対応プロトコル

| プロトコル | トランスポート | TLS |
|------------|----------------|-----|
| Shadowsocks 2022 | TCP/UDP | — |
| Hysteria2 | QUIC | 自己署名証明書 |
| TUIC | QUIC | 自己署名証明書 |
| VLESS Reality | TCP | Reality |
| AnyTLS Reality | TCP | Reality |

---

## 📄 ライセンス

MIT
