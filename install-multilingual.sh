#!/usr/bin/env bash
# =============================================================
# Candies Sing-box 多协议部署脚本
# Author  : Candies-Sven
# Repo    : https://github.com/candies-sven-007/proxy
# =============================================================
set -euo pipefail

# -----------------------
# 语言选择
select_language() {
    echo ""
    echo "==========================================="
    echo " Please select language / 请选择语言"
    echo "==========================================="
    echo "1) 简体中文"
    echo "2) 繁體中文"
    echo "3) 日本語"
    echo "4) English"
    echo ""
    printf "Enter number (default 1): "
    read -r lang_choice
    case "${lang_choice:-1}" in
        1) LANG_CODE="zh_CN" ;;
        2) LANG_CODE="zh_TW" ;;
        3) LANG_CODE="ja"    ;;
        4) LANG_CODE="en"    ;;
        *) LANG_CODE="zh_CN" ;;
    esac
    export LANG_CODE
    mkdir -p /etc/sing-box
    echo "LANG_CODE=$LANG_CODE" > /etc/sing-box/.lang
}

select_language

# -----------------------
# 多语言字符串
msg() {
    local key="$1"
    local text=""
    case "$LANG_CODE" in
        zh_CN) case "$key" in
            detecting_os)       text="检测到系统" ;;
            need_root)          text="此脚本需要 root 权限" ;;
            need_root2)         text="请使用: sudo bash 或切换到 root 用户" ;;
            installing_deps)    text="安装系统依赖..." ;;
            apk_fail)           text="apk update 失败" ;;
            apt_fail)           text="apt update 失败" ;;
            deps_fail)          text="依赖安装失败" ;;
            deps_ok)            text="依赖安装完成" ;;
            unknown_os)         text="未识别的系统类型,尝试继续..." ;;
            enter_node_name)    text="请输入节点名称(留空则默认无后缀):" ;;
            select_proto)       text="=== 选择要部署的协议 ===" ;;
            enter_proto)        text="请输入要部署的协议编号(多个用空格分隔,如: 1 2 4):" ;;
            invalid_opt)        text="无效选项" ;;
            no_proto)           text="未选择任何协议,退出安装" ;;
            selected_proto)     text="已选择协议:" ;;
            select_ss_method)   text="=== 选择 Shadowsocks 加密方式 ===" ;;
            enter_choice)       text="请输入选择(默认为 1):" ;;
            invalid_method)     text="无效选择，使用默认方式: 2022-blake3-aes-128-gcm" ;;
            selected_method)    text="已选择加密方式" ;;
            enter_ip)           text="请输入节点连接 IP 或 DDNS域名(留空默认出口IP):" ;;
            enter_sni)          text="请输入 Reality 的 SNI(留空默认 addons.mozilla.org):" ;;
            config_ports)       text="开始配置端口和密码..." ;;
            config_ss)          text="=== 配置 Shadowsocks (SS) ===" ;;
            config_hy2)         text="=== 配置 Hysteria2 (HY2) ===" ;;
            config_tuic)        text="=== 配置 TUIC ===" ;;
            config_reality)     text="=== 配置 VLESS Reality ===" ;;
            config_anytls)      text="=== 配置 AnyTLS Reality ===" ;;
            enter_port_ss)      text="请输入 SS 端口(留空则随机 10000-60000): " ;;
            enter_port_hy2)     text="请输入 HY2 端口(留空则随机 10000-60000): " ;;
            enter_port_tuic)    text="请输入 TUIC 端口(留空则随机 10000-60000): " ;;
            enter_port_reality) text="请输入 VLESS Reality 端口(留空则随机 10000-60000): " ;;
            enter_port_anytls)  text="请输入 AnyTLS Reality 端口(留空则随机 10000-60000): " ;;
            pwd_generated)      text="密码已自动生成" ;;
            port_label)         text="端口" ;;
            method_label)       text="加密方式" ;;
            installing_sb)      text="开始安装 sing-box..." ;;
            sb_detected)        text="检测到已安装 sing-box" ;;
            reinstall_q)        text="是否重新安装?(y/N): " ;;
            skip_install)       text="跳过 sing-box 安装" ;;
            edge_install)       text="使用 Edge 仓库安装 sing-box" ;;
            sb_fail)            text="sing-box 安装失败" ;;
            sb_not_found)       text="sing-box 安装后未找到可执行文件" ;;
            sb_ok)              text="sing-box 安装成功" ;;
            skip_reality_keys)  text="跳过 Reality 密钥生成" ;;
            gen_reality_keys)   text="生成 Reality 密钥对..." ;;
            reality_keys_fail)  text="生成 Reality 密钥失败" ;;
            reality_keys_ok)    text="Reality 密钥已生成" ;;
            skip_cert)          text="跳过证书生成(未选择 HY2 或 TUIC)" ;;
            gen_cert)           text="生成 HY2/TUIC 自签证书..." ;;
            cert_fail)          text="证书生成失败" ;;
            cert_ok)            text="证书已生成" ;;
            cert_exists)        text="证书已存在" ;;
            gen_config)         text="生成配置文件" ;;
            config_ok)          text="配置文件验证通过" ;;
            config_warn)        text="配置文件验证失败,但继续执行" ;;
            config_saved)       text="配置缓存已保存" ;;
            setup_service)      text="配置系统服务..." ;;
            svc_start_fail)     text="服务启动失败" ;;
            svc_ok_openrc)      text="✅ OpenRC 服务已启动" ;;
            svc_ok_systemd)     text="✅ Systemd 服务已启动" ;;
            svc_abnormal)       text="服务状态异常" ;;
            svc_done)           text="服务配置完成" ;;
            using_custom_ip)    text="使用用户提供的连接IP" ;;
            pub_ip_fail)        text="无法获取公网 IP，请手动替换" ;;
            pub_ip_ok)          text="检测到公网 IP" ;;
            deploy_done)        text="🎉 Sing-box 部署完成!" ;;
            config_info)        text="📋 配置信息:" ;;
            server_label)       text="服务器" ;;
            sni_label)          text="Reality SNI" ;;
            file_loc)           text="📂 文件位置:" ;;
            client_links)       text="📜 客户端链接:" ;;
            mgmt_cmds)          text="🔧 管理命令:" ;;
            creating_sb)        text="正在创建 candies-sb 管理面板" ;;
            sb_created)         text="✅ 管理面板已创建,可输入 candies-sb 打开管理面板" ;;
        esac ;;
        zh_TW) case "$key" in
            detecting_os)       text="偵測到系統" ;;
            need_root)          text="此腳本需要 root 權限" ;;
            need_root2)         text="請使用: sudo bash 或切換到 root 使用者" ;;
            installing_deps)    text="安裝系統依賴..." ;;
            apk_fail)           text="apk update 失敗" ;;
            apt_fail)           text="apt update 失敗" ;;
            deps_fail)          text="依賴安裝失敗" ;;
            deps_ok)            text="依賴安裝完成" ;;
            unknown_os)         text="未識別的系統類型,嘗試繼續..." ;;
            enter_node_name)    text="請輸入節點名稱(留空則預設無後綴):" ;;
            select_proto)       text="=== 選擇要部署的協議 ===" ;;
            enter_proto)        text="請輸入要部署的協議編號(多個用空格分隔,如: 1 2 4):" ;;
            invalid_opt)        text="無效選項" ;;
            no_proto)           text="未選擇任何協議,退出安裝" ;;
            selected_proto)     text="已選擇協議:" ;;
            select_ss_method)   text="=== 選擇 Shadowsocks 加密方式 ===" ;;
            enter_choice)       text="請輸入選擇(預設為 1):" ;;
            invalid_method)     text="無效選擇，使用預設方式: 2022-blake3-aes-128-gcm" ;;
            selected_method)    text="已選擇加密方式" ;;
            enter_ip)           text="請輸入節點連線 IP 或 DDNS域名(留空預設出口IP):" ;;
            enter_sni)          text="請輸入 Reality 的 SNI(留空預設 addons.mozilla.org):" ;;
            config_ports)       text="開始設定連接埠和密碼..." ;;
            config_ss)          text="=== 設定 Shadowsocks (SS) ===" ;;
            config_hy2)         text="=== 設定 Hysteria2 (HY2) ===" ;;
            config_tuic)        text="=== 設定 TUIC ===" ;;
            config_reality)     text="=== 設定 VLESS Reality ===" ;;
            config_anytls)      text="=== 設定 AnyTLS Reality ===" ;;
            enter_port_ss)      text="請輸入 SS 連接埠(留空則隨機 10000-60000): " ;;
            enter_port_hy2)     text="請輸入 HY2 連接埠(留空則隨機 10000-60000): " ;;
            enter_port_tuic)    text="請輸入 TUIC 連接埠(留空則隨機 10000-60000): " ;;
            enter_port_reality) text="請輸入 VLESS Reality 連接埠(留空則隨機 10000-60000): " ;;
            enter_port_anytls)  text="請輸入 AnyTLS Reality 連接埠(留空則隨機 10000-60000): " ;;
            pwd_generated)      text="密碼已自動生成" ;;
            port_label)         text="連接埠" ;;
            method_label)       text="加密方式" ;;
            installing_sb)      text="開始安裝 sing-box..." ;;
            sb_detected)        text="偵測到已安裝 sing-box" ;;
            reinstall_q)        text="是否重新安裝?(y/N): " ;;
            skip_install)       text="跳過 sing-box 安裝" ;;
            edge_install)       text="使用 Edge 倉庫安裝 sing-box" ;;
            sb_fail)            text="sing-box 安裝失敗" ;;
            sb_not_found)       text="sing-box 安裝後未找到可執行檔" ;;
            sb_ok)              text="sing-box 安裝成功" ;;
            skip_reality_keys)  text="跳過 Reality 金鑰生成" ;;
            gen_reality_keys)   text="生成 Reality 金鑰對..." ;;
            reality_keys_fail)  text="生成 Reality 金鑰失敗" ;;
            reality_keys_ok)    text="Reality 金鑰已生成" ;;
            skip_cert)          text="跳過憑證生成(未選擇 HY2 或 TUIC)" ;;
            gen_cert)           text="生成 HY2/TUIC 自簽憑證..." ;;
            cert_fail)          text="憑證生成失敗" ;;
            cert_ok)            text="憑證已生成" ;;
            cert_exists)        text="憑證已存在" ;;
            gen_config)         text="生成設定檔" ;;
            config_ok)          text="設定檔驗證通過" ;;
            config_warn)        text="設定檔驗證失敗,但繼續執行" ;;
            config_saved)       text="設定快取已儲存" ;;
            setup_service)      text="設定系統服務..." ;;
            svc_start_fail)     text="服務啟動失敗" ;;
            svc_ok_openrc)      text="✅ OpenRC 服務已啟動" ;;
            svc_ok_systemd)     text="✅ Systemd 服務已啟動" ;;
            svc_abnormal)       text="服務狀態異常" ;;
            svc_done)           text="服務設定完成" ;;
            using_custom_ip)    text="使用使用者提供的連線IP" ;;
            pub_ip_fail)        text="無法取得公網 IP，請手動替換" ;;
            pub_ip_ok)          text="偵測到公網 IP" ;;
            deploy_done)        text="🎉 Sing-box 部署完成!" ;;
            config_info)        text="📋 設定資訊:" ;;
            server_label)       text="伺服器" ;;
            sni_label)          text="Reality SNI" ;;
            file_loc)           text="📂 檔案位置:" ;;
            client_links)       text="📜 客戶端連結:" ;;
            mgmt_cmds)          text="🔧 管理指令:" ;;
            creating_sb)        text="正在建立 candies-sb 管理面板" ;;
            sb_created)         text="✅ 管理面板已建立,可輸入 candies-sb 開啟管理面板" ;;
        esac ;;
        ja) case "$key" in
            detecting_os)       text="システムを検出" ;;
            need_root)          text="このスクリプトは root 権限が必要です" ;;
            need_root2)         text="sudo bash を使用するか root に切り替えてください" ;;
            installing_deps)    text="システム依存関係をインストール中..." ;;
            apk_fail)           text="apk update に失敗しました" ;;
            apt_fail)           text="apt update に失敗しました" ;;
            deps_fail)          text="依存関係のインストールに失敗しました" ;;
            deps_ok)            text="依存関係のインストール完了" ;;
            unknown_os)         text="不明なシステムタイプです。続行を試みます..." ;;
            enter_node_name)    text="ノード名を入力してください(空白でサフィックスなし):" ;;
            select_proto)       text="=== デプロイするプロトコルを選択 ===" ;;
            enter_proto)        text="プロトコル番号を入力してください(スペース区切り、例: 1 2 4):" ;;
            invalid_opt)        text="無効なオプション" ;;
            no_proto)           text="プロトコルが選択されていません。インストールを終了します" ;;
            selected_proto)     text="選択されたプロトコル:" ;;
            select_ss_method)   text="=== Shadowsocks 暗号化方式を選択 ===" ;;
            enter_choice)       text="選択を入力してください(デフォルト: 1):" ;;
            invalid_method)     text="無効な選択です。デフォルトを使用: 2022-blake3-aes-128-gcm" ;;
            selected_method)    text="暗号化方式を選択しました" ;;
            enter_ip)           text="接続 IP または DDNS ドメインを入力してください(空白で自動検出):" ;;
            enter_sni)          text="Reality SNI を入力してください(空白でデフォルト addons.mozilla.org):" ;;
            config_ports)       text="ポートとパスワードの設定を開始..." ;;
            config_ss)          text="=== Shadowsocks (SS) を設定 ===" ;;
            config_hy2)         text="=== Hysteria2 (HY2) を設定 ===" ;;
            config_tuic)        text="=== TUIC を設定 ===" ;;
            config_reality)     text="=== VLESS Reality を設定 ===" ;;
            config_anytls)      text="=== AnyTLS Reality を設定 ===" ;;
            enter_port_ss)      text="SS ポートを入力してください(空白でランダム 10000-60000): " ;;
            enter_port_hy2)     text="HY2 ポートを入力してください(空白でランダム 10000-60000): " ;;
            enter_port_tuic)    text="TUIC ポートを入力してください(空白でランダム 10000-60000): " ;;
            enter_port_reality) text="VLESS Reality ポートを入力してください(空白でランダム 10000-60000): " ;;
            enter_port_anytls)  text="AnyTLS Reality ポートを入力してください(空白でランダム 10000-60000): " ;;
            pwd_generated)      text="パスワードを自動生成しました" ;;
            port_label)         text="ポート" ;;
            method_label)       text="暗号化方式" ;;
            installing_sb)      text="sing-box のインストールを開始..." ;;
            sb_detected)        text="sing-box がすでにインストールされています" ;;
            reinstall_q)        text="再インストールしますか?(y/N): " ;;
            skip_install)       text="sing-box のインストールをスキップ" ;;
            edge_install)       text="Edge リポジトリから sing-box をインストール" ;;
            sb_fail)            text="sing-box のインストールに失敗しました" ;;
            sb_not_found)       text="インストール後に sing-box 実行ファイルが見つかりません" ;;
            sb_ok)              text="sing-box のインストールに成功しました" ;;
            skip_reality_keys)  text="Reality キーペアの生成をスキップ" ;;
            gen_reality_keys)   text="Reality キーペアを生成中..." ;;
            reality_keys_fail)  text="Reality キーペアの生成に失敗しました" ;;
            reality_keys_ok)    text="Reality キーペアを生成しました" ;;
            skip_cert)          text="証明書の生成をスキップ(HY2/TUIC 未選択)" ;;
            gen_cert)           text="HY2/TUIC 用の自己署名証明書を生成中..." ;;
            cert_fail)          text="証明書の生成に失敗しました" ;;
            cert_ok)            text="証明書を生成しました" ;;
            cert_exists)        text="証明書はすでに存在します" ;;
            gen_config)         text="設定ファイルを生成" ;;
            config_ok)          text="設定ファイルの検証に成功しました" ;;
            config_warn)        text="設定ファイルの検証に失敗しましたが続行します" ;;
            config_saved)       text="設定キャッシュを保存しました" ;;
            setup_service)      text="システムサービスを設定中..." ;;
            svc_start_fail)     text="サービスの起動に失敗しました" ;;
            svc_ok_openrc)      text="✅ OpenRC サービスが起動しました" ;;
            svc_ok_systemd)     text="✅ Systemd サービスが起動しました" ;;
            svc_abnormal)       text="サービスの状態が異常です" ;;
            svc_done)           text="サービスの設定が完了しました" ;;
            using_custom_ip)    text="ユーザー指定の接続IPを使用" ;;
            pub_ip_fail)        text="パブリックIPを取得できませんでした。手動で置き換えてください" ;;
            pub_ip_ok)          text="パブリックIPを検出しました" ;;
            deploy_done)        text="🎉 Sing-box のデプロイが完了しました!" ;;
            config_info)        text="📋 設定情報:" ;;
            server_label)       text="サーバー" ;;
            sni_label)          text="Reality SNI" ;;
            file_loc)           text="📂 ファイルの場所:" ;;
            client_links)       text="📜 クライアントリンク:" ;;
            mgmt_cmds)          text="🔧 管理コマンド:" ;;
            creating_sb)        text="candies-sb 管理パネルを作成中" ;;
            sb_created)         text="✅ 管理パネルを作成しました。candies-sb と入力して開いてください" ;;
        esac ;;
        en) case "$key" in
            detecting_os)       text="Detected OS" ;;
            need_root)          text="This script requires root privileges" ;;
            need_root2)         text="Please use: sudo bash or switch to root user" ;;
            installing_deps)    text="Installing system dependencies..." ;;
            apk_fail)           text="apk update failed" ;;
            apt_fail)           text="apt update failed" ;;
            deps_fail)          text="Dependency installation failed" ;;
            deps_ok)            text="Dependencies installed" ;;
            unknown_os)         text="Unknown OS type, trying to continue..." ;;
            enter_node_name)    text="Enter node name suffix (leave blank for none):" ;;
            select_proto)       text="=== Select protocols to deploy ===" ;;
            enter_proto)        text="Enter protocol numbers (space-separated, e.g.: 1 2 4):" ;;
            invalid_opt)        text="Invalid option" ;;
            no_proto)           text="No protocol selected, exiting" ;;
            selected_proto)     text="Selected protocols:" ;;
            select_ss_method)   text="=== Select Shadowsocks encryption method ===" ;;
            enter_choice)       text="Enter choice (default 1):" ;;
            invalid_method)     text="Invalid choice, using default: 2022-blake3-aes-128-gcm" ;;
            selected_method)    text="Selected encryption method" ;;
            enter_ip)           text="Enter node connection IP or DDNS hostname (leave blank for auto-detect):" ;;
            enter_sni)          text="Enter Reality SNI (leave blank for default addons.mozilla.org):" ;;
            config_ports)       text="Configuring ports and passwords..." ;;
            config_ss)          text="=== Configure Shadowsocks (SS) ===" ;;
            config_hy2)         text="=== Configure Hysteria2 (HY2) ===" ;;
            config_tuic)        text="=== Configure TUIC ===" ;;
            config_reality)     text="=== Configure VLESS Reality ===" ;;
            config_anytls)      text="=== Configure AnyTLS Reality ===" ;;
            enter_port_ss)      text="Enter SS port (leave blank for random 10000-60000): " ;;
            enter_port_hy2)     text="Enter HY2 port (leave blank for random 10000-60000): " ;;
            enter_port_tuic)    text="Enter TUIC port (leave blank for random 10000-60000): " ;;
            enter_port_reality) text="Enter VLESS Reality port (leave blank for random 10000-60000): " ;;
            enter_port_anytls)  text="Enter AnyTLS Reality port (leave blank for random 10000-60000): " ;;
            pwd_generated)      text="Password auto-generated" ;;
            port_label)         text="Port" ;;
            method_label)       text="Method" ;;
            installing_sb)      text="Installing sing-box..." ;;
            sb_detected)        text="sing-box already installed" ;;
            reinstall_q)        text="Reinstall? (y/N): " ;;
            skip_install)       text="Skipping sing-box installation" ;;
            edge_install)       text="Installing sing-box from Edge repository" ;;
            sb_fail)            text="sing-box installation failed" ;;
            sb_not_found)       text="sing-box executable not found after installation" ;;
            sb_ok)              text="sing-box installed successfully" ;;
            skip_reality_keys)  text="Skipping Reality key generation" ;;
            gen_reality_keys)   text="Generating Reality key pair..." ;;
            reality_keys_fail)  text="Failed to generate Reality key pair" ;;
            reality_keys_ok)    text="Reality key pair generated" ;;
            skip_cert)          text="Skipping cert generation (HY2/TUIC not selected)" ;;
            gen_cert)           text="Generating self-signed cert for HY2/TUIC..." ;;
            cert_fail)          text="Certificate generation failed" ;;
            cert_ok)            text="Certificate generated" ;;
            cert_exists)        text="Certificate already exists" ;;
            gen_config)         text="Generating config file" ;;
            config_ok)          text="Config file validation passed" ;;
            config_warn)        text="Config validation failed, continuing anyway" ;;
            config_saved)       text="Config cache saved" ;;
            setup_service)      text="Configuring system service..." ;;
            svc_start_fail)     text="Service failed to start" ;;
            svc_ok_openrc)      text="✅ OpenRC service started" ;;
            svc_ok_systemd)     text="✅ Systemd service started" ;;
            svc_abnormal)       text="Service status abnormal" ;;
            svc_done)           text="Service configuration complete" ;;
            using_custom_ip)    text="Using user-provided connection IP" ;;
            pub_ip_fail)        text="Could not detect public IP, please replace manually" ;;
            pub_ip_ok)          text="Detected public IP" ;;
            deploy_done)        text="🎉 Sing-box deployment complete!" ;;
            config_info)        text="📋 Configuration:" ;;
            server_label)       text="Server" ;;
            sni_label)          text="Reality SNI" ;;
            file_loc)           text="📂 File locations:" ;;
            client_links)       text="📜 Client links:" ;;
            mgmt_cmds)          text="🔧 Management commands:" ;;
            creating_sb)        text="Creating candies-sb management panel" ;;
            sb_created)         text="✅ Management panel created. Type candies-sb to open" ;;
        esac ;;
    esac
    echo "$text"
}

# -----------------------
info() { echo -e "\033[1;34m[Candies-INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[Candies-WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[Candies-ERR]\033[0m $*" >&2; }

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID:-}"
        OS_ID_LIKE="${ID_LIKE:-}"
    else
        OS_ID=""
        OS_ID_LIKE=""
    fi
    if echo "$OS_ID $OS_ID_LIKE" | grep -qi "alpine"; then
        OS="alpine"
    elif echo "$OS_ID $OS_ID_LIKE" | grep -Ei "debian|ubuntu" >/dev/null; then
        OS="debian"
    elif echo "$OS_ID $OS_ID_LIKE" | grep -Ei "centos|rhel|fedora" >/dev/null; then
        OS="redhat"
    else
        OS="unknown"
    fi
}

detect_os
info "$(msg detecting_os): $OS (${OS_ID:-unknown})"

check_root() {
    if [ "$(id -u)" != "0" ]; then
        err "$(msg need_root)"
        err "$(msg need_root2)"
        exit 1
    fi
}
check_root

install_deps() {
    info "$(msg installing_deps)"
    case "$OS" in
        alpine)
            apk update || { err "$(msg apk_fail)"; exit 1; }
            apk add --no-cache bash curl ca-certificates openssl openrc jq || { err "$(msg deps_fail)"; exit 1; }
            ;;
        debian)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y || { err "$(msg apt_fail)"; exit 1; }
            apt-get install -y curl ca-certificates openssl jq || { err "$(msg deps_fail)"; exit 1; }
            ;;
        redhat)
            yum install -y curl ca-certificates openssl jq || { err "$(msg deps_fail)"; exit 1; }
            ;;
        *)
            warn "$(msg unknown_os)"
            ;;
    esac
    info "$(msg deps_ok)"
}
install_deps

rand_port() { shuf -i 10000-60000 -n 1 2>/dev/null || echo $((RANDOM % 50001 + 10000)); }
rand_pass()  { openssl rand -base64 16 2>/dev/null | tr -d '\n\r' || head -c 16 /dev/urandom | base64 2>/dev/null | tr -d '\n\r'; }
rand_uuid()  {
    if [ -f /proc/sys/kernel/random/uuid ]; then cat /proc/sys/kernel/random/uuid
    else openssl rand -hex 16 | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/'
    fi
}

echo "$(msg enter_node_name)"
read -r user_name
if [ -n "$user_name" ]; then
    suffix="-${user_name}"
    echo "$suffix" > /root/node_names.txt
else
    suffix=""
fi

select_protocols() {
    info "$(msg select_proto)"
    echo "1) Shadowsocks (SS)"
    echo "2) Hysteria2 (HY2)"
    echo "3) TUIC"
    echo "4) VLESS Reality"
    echo "5) AnyTLS Reality"
    echo ""
    echo "$(msg enter_proto)"
    read -r protocol_input
    ENABLE_SS=false; ENABLE_HY2=false; ENABLE_TUIC=false; ENABLE_REALITY=false; ENABLE_ANYTLS=false
    for num in $protocol_input; do
        case "$num" in
            1) ENABLE_SS=true ;;
            2) ENABLE_HY2=true ;;
            3) ENABLE_TUIC=true ;;
            4) ENABLE_REALITY=true ;;
            5) ENABLE_ANYTLS=true ;;
            *) warn "$(msg invalid_opt): $num" ;;
        esac
    done
    if ! $ENABLE_SS && ! $ENABLE_HY2 && ! $ENABLE_TUIC && ! $ENABLE_REALITY && ! $ENABLE_ANYTLS; then
        err "$(msg no_proto)"; exit 1
    fi
    mkdir -p /etc/sing-box
    cat > /etc/sing-box/.protocols <<EOF
ENABLE_SS=$ENABLE_SS
ENABLE_HY2=$ENABLE_HY2
ENABLE_TUIC=$ENABLE_TUIC
ENABLE_REALITY=$ENABLE_REALITY
ENABLE_ANYTLS=$ENABLE_ANYTLS
EOF
    info "$(msg selected_proto)"
    $ENABLE_SS      && echo "  - Shadowsocks"
    $ENABLE_HY2     && echo "  - Hysteria2"
    $ENABLE_TUIC    && echo "  - TUIC"
    $ENABLE_REALITY && echo "  - VLESS Reality"
    $ENABLE_ANYTLS  && echo "  - AnyTLS Reality"
    export ENABLE_SS ENABLE_HY2 ENABLE_TUIC ENABLE_REALITY ENABLE_ANYTLS
}

mkdir -p /etc/sing-box
select_protocols

select_ss_method() {
    if ! $ENABLE_SS; then SS_METHOD="2022-blake3-aes-128-gcm"; return 0; fi
    info "$(msg select_ss_method)"
    echo "1) 2022-blake3-aes-128-gcm (recommended)"
    echo "2) aes-128-gcm"
    echo ""
    echo "$(msg enter_choice)"
    read -r ss_method_choice
    case "${ss_method_choice:-1}" in
        1) SS_METHOD="2022-blake3-aes-128-gcm" ;;
        2) SS_METHOD="aes-128-gcm" ;;
        *) warn "$(msg invalid_method)"; SS_METHOD="2022-blake3-aes-128-gcm" ;;
    esac
    info "$(msg selected_method): $SS_METHOD"
    export SS_METHOD
}
select_ss_method

echo ""
echo "$(msg enter_ip)"
read -r CUSTOM_IP
CUSTOM_IP="$(echo "$CUSTOM_IP" | tr -d '[:space:]')"

REALITY_SNI=""
if $ENABLE_REALITY || $ENABLE_ANYTLS; then
    echo ""
    echo "$(msg enter_sni)"
    read -r REALITY_SNI
    REALITY_SNI="$(echo "${REALITY_SNI:-addons.mozilla.org}" | tr -d '[:space:]')"
else
    REALITY_SNI="addons.mozilla.org"
fi

mkdir -p /etc/sing-box
echo "CUSTOM_IP=$CUSTOM_IP"     > /etc/sing-box/.config_cache.tmp || true
echo "REALITY_SNI=$REALITY_SNI" >> /etc/sing-box/.config_cache.tmp || true
if [ -f /etc/sing-box/.config_cache ]; then
    awk 'FNR==NR{a[$1]=1;next} {split($0,k,"="); if(!(k[1] in a)) print $0}' \
        /etc/sing-box/.config_cache.tmp /etc/sing-box/.config_cache \
        >> /etc/sing-box/.config_cache.tmp2 || true
    mv /etc/sing-box/.config_cache.tmp2 /etc/sing-box/.config_cache.tmp || true
fi
mv /etc/sing-box/.config_cache.tmp /etc/sing-box/.config_cache || true

get_config() {
    info "$(msg config_ports)"
    if $ENABLE_SS; then
        info "$(msg config_ss)"
        if [ -n "${SINGBOX_PORT_SS:-}" ]; then PORT_SS="$SINGBOX_PORT_SS"
        else read -p "$(msg enter_port_ss)" USER_PORT_SS; PORT_SS="${USER_PORT_SS:-$(rand_port)}"; fi
        PSK_SS=$(rand_pass)
        info "$(msg port_label) SS: $PORT_SS | $(msg method_label): $SS_METHOD | $(msg pwd_generated)"
    fi
    if $ENABLE_HY2; then
        info "$(msg config_hy2)"
        if [ -n "${SINGBOX_PORT_HY2:-}" ]; then PORT_HY2="$SINGBOX_PORT_HY2"
        else read -p "$(msg enter_port_hy2)" USER_PORT_HY2; PORT_HY2="${USER_PORT_HY2:-$(rand_port)}"; fi
        PSK_HY2=$(rand_pass)
        info "$(msg port_label) HY2: $PORT_HY2 | $(msg pwd_generated)"
    fi
    if $ENABLE_TUIC; then
        info "$(msg config_tuic)"
        if [ -n "${SINGBOX_PORT_TUIC:-}" ]; then PORT_TUIC="$SINGBOX_PORT_TUIC"
        else read -p "$(msg enter_port_tuic)" USER_PORT_TUIC; PORT_TUIC="${USER_PORT_TUIC:-$(rand_port)}"; fi
        PSK_TUIC=$(rand_pass); UUID_TUIC=$(rand_uuid)
        info "$(msg port_label) TUIC: $PORT_TUIC | $(msg pwd_generated)"
    fi
    if $ENABLE_REALITY; then
        info "$(msg config_reality)"
        if [ -n "${SINGBOX_PORT_REALITY:-}" ]; then PORT_REALITY="$SINGBOX_PORT_REALITY"
        else read -p "$(msg enter_port_reality)" USER_PORT_REALITY; PORT_REALITY="${USER_PORT_REALITY:-$(rand_port)}"; fi
        UUID=$(rand_uuid)
        info "$(msg port_label) VLESS Reality: $PORT_REALITY | $(msg pwd_generated)"
    fi
    if $ENABLE_ANYTLS; then
        info "$(msg config_anytls)"
        if [ -n "${SINGBOX_PORT_ANYTLS:-}" ]; then PORT_ANYTLS="$SINGBOX_PORT_ANYTLS"
        else read -p "$(msg enter_port_anytls)" USER_PORT_ANYTLS; PORT_ANYTLS="${USER_PORT_ANYTLS:-$(rand_port)}"; fi
        ANYTLS_USER=$(openssl rand -hex 4)
        ANYTLS_PSK=$(openssl rand -base64 16)
        info "$(msg port_label) AnyTLS: $PORT_ANYTLS | $(msg pwd_generated)"
    fi
}
get_config

install_singbox() {
    info "$(msg installing_sb)"
    if command -v sing-box >/dev/null 2>&1; then
        CURRENT_VERSION=$(sing-box version 2>/dev/null | head -1 || echo "unknown")
        warn "$(msg sb_detected): $CURRENT_VERSION"
        read -p "$(msg reinstall_q)" REINSTALL
        if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then info "$(msg skip_install)"; return 0; fi
    fi
    case "$OS" in
        alpine)
            info "$(msg edge_install)"
            apk update || { err "$(msg apk_fail)"; exit 1; }
            apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community sing-box || { err "$(msg sb_fail)"; exit 1; }
            ;;
        debian|redhat)
            bash <(curl -fsSL https://sing-box.app/install.sh) || { err "$(msg sb_fail)"; exit 1; }
            ;;
        *)
            err "$(msg sb_fail)"; exit 1 ;;
    esac
    command -v sing-box >/dev/null 2>&1 || { err "$(msg sb_not_found)"; exit 1; }
    info "$(msg sb_ok): $(sing-box version 2>/dev/null | head -1)"
}
install_singbox

generate_reality_keys() {
    if ! $ENABLE_REALITY && ! $ENABLE_ANYTLS; then
        info "$(msg skip_reality_keys)"; return 0
    fi
    info "$(msg gen_reality_keys)"
    REALITY_KEYS=$(sing-box generate reality-keypair 2>&1) || { err "$(msg reality_keys_fail)"; exit 1; }
    REALITY_PK=$(echo "$REALITY_KEYS"  | grep "PrivateKey" | awk '{print $NF}' | tr -d '\r')
    REALITY_PUB=$(echo "$REALITY_KEYS" | grep "PublicKey"  | awk '{print $NF}' | tr -d '\r')
    REALITY_SID=$(sing-box generate rand 8 --hex 2>&1) || { err "$(msg reality_keys_fail)"; exit 1; }
    [ -z "$REALITY_PK" ] || [ -z "$REALITY_PUB" ] || [ -z "$REALITY_SID" ] && { err "$(msg reality_keys_fail)"; exit 1; }
    mkdir -p /etc/sing-box
    echo -n "$REALITY_PUB" > /etc/sing-box/.reality_pub
    echo -n "$REALITY_SID" > /etc/sing-box/.reality_sid
    info "$(msg reality_keys_ok)"
}
generate_reality_keys

generate_cert() {
    if ! $ENABLE_HY2 && ! $ENABLE_TUIC; then info "$(msg skip_cert)"; return 0; fi
    info "$(msg gen_cert)"
    mkdir -p /etc/sing-box/certs
    if [ ! -f /etc/sing-box/certs/fullchain.pem ] || [ ! -f /etc/sing-box/certs/privkey.pem ]; then
        openssl req -x509 -newkey rsa:2048 -nodes \
            -keyout /etc/sing-box/certs/privkey.pem \
            -out    /etc/sing-box/certs/fullchain.pem \
            -days 3650 -subj "/CN=www.bing.com" || { err "$(msg cert_fail)"; exit 1; }
        info "$(msg cert_ok)"
    else
        info "$(msg cert_exists)"
    fi
}
generate_cert

CONFIG_PATH="/etc/sing-box/config.json"

create_config() {
    info "$(msg gen_config): $CONFIG_PATH"
    mkdir -p "$(dirname "$CONFIG_PATH")"
    local TEMP_INBOUNDS="/tmp/singbox_inbounds_$$.json"
    > "$TEMP_INBOUNDS"
    local need_comma=false

    if $ENABLE_SS; then
        cat >> "$TEMP_INBOUNDS" <<'INBOUND_SS'
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": PORT_SS_PLACEHOLDER,
      "method": "METHOD_SS_PLACEHOLDER",
      "password": "PSK_SS_PLACEHOLDER",
      "tag": "ss-in"
    }
INBOUND_SS
        sed -i "s|PORT_SS_PLACEHOLDER|$PORT_SS|g;s|METHOD_SS_PLACEHOLDER|$SS_METHOD|g;s|PSK_SS_PLACEHOLDER|$PSK_SS|g" "$TEMP_INBOUNDS"
        need_comma=true
    fi

    if $ENABLE_HY2; then
        $need_comma && echo "," >> "$TEMP_INBOUNDS"
        cat >> "$TEMP_INBOUNDS" <<'INBOUND_HY2'
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": PORT_HY2_PLACEHOLDER,
      "users": [{"password": "PSK_HY2_PLACEHOLDER"}],
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/certs/fullchain.pem",
        "key_path": "/etc/sing-box/certs/privkey.pem"
      }
    }
INBOUND_HY2
        sed -i "s|PORT_HY2_PLACEHOLDER|$PORT_HY2|g;s|PSK_HY2_PLACEHOLDER|$PSK_HY2|g" "$TEMP_INBOUNDS"
        need_comma=true
    fi

    if $ENABLE_TUIC; then
        $need_comma && echo "," >> "$TEMP_INBOUNDS"
        cat >> "$TEMP_INBOUNDS" <<'INBOUND_TUIC'
    {
      "type": "tuic",
      "tag": "tuic-in",
      "listen": "::",
      "listen_port": PORT_TUIC_PLACEHOLDER,
      "users": [{"uuid": "UUID_TUIC_PLACEHOLDER", "password": "PSK_TUIC_PLACEHOLDER"}],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/certs/fullchain.pem",
        "key_path": "/etc/sing-box/certs/privkey.pem"
      }
    }
INBOUND_TUIC
        sed -i "s|PORT_TUIC_PLACEHOLDER|$PORT_TUIC|g;s|UUID_TUIC_PLACEHOLDER|$UUID_TUIC|g;s|PSK_TUIC_PLACEHOLDER|$PSK_TUIC|g" "$TEMP_INBOUNDS"
        need_comma=true
    fi

    if $ENABLE_REALITY; then
        $need_comma && echo "," >> "$TEMP_INBOUNDS"
        cat >> "$TEMP_INBOUNDS" <<'INBOUND_REALITY'
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": PORT_REALITY_PLACEHOLDER,
      "users": [{"uuid": "UUID_REALITY_PLACEHOLDER", "flow": "xtls-rprx-vision"}],
      "tls": {
        "enabled": true,
        "server_name": "REALITY_SNI_PLACEHOLDER",
        "reality": {
          "enabled": true,
          "handshake": {"server": "REALITY_SNI_PLACEHOLDER", "server_port": 443},
          "private_key": "REALITY_PK_PLACEHOLDER",
          "short_id": ["REALITY_SID_PLACEHOLDER"]
        }
      }
    }
INBOUND_REALITY
        sed -i "s|PORT_REALITY_PLACEHOLDER|$PORT_REALITY|g;s|UUID_REALITY_PLACEHOLDER|$UUID|g" "$TEMP_INBOUNDS"
        sed -i "s|REALITY_PK_PLACEHOLDER|$REALITY_PK|g;s|REALITY_SID_PLACEHOLDER|$REALITY_SID|g;s|REALITY_SNI_PLACEHOLDER|$REALITY_SNI|g" "$TEMP_INBOUNDS"
        need_comma=true
    fi

    if $ENABLE_ANYTLS; then
        $need_comma && echo "," >> "$TEMP_INBOUNDS"
        cat >> "$TEMP_INBOUNDS" <<'INBOUND_ANYTLS'
    {
      "type": "anytls",
      "tag": "anytls-in",
      "listen": "::",
      "listen_port": PORT_ANYTLS_PLACEHOLDER,
      "users": [{"name": "ANYTLS_USER_PLACEHOLDER", "password": "ANYTLS_PSK_PLACEHOLDER"}],
      "padding_scheme": [],
      "tls": {
        "enabled": true,
        "server_name": "REALITY_SNI_PLACEHOLDER",
        "reality": {
          "enabled": true,
          "handshake": {"server": "REALITY_SNI_PLACEHOLDER", "server_port": 443},
          "private_key": "REALITY_PK_PLACEHOLDER",
          "short_id": ["REALITY_SID_PLACEHOLDER"]
        }
      }
    }
INBOUND_ANYTLS
        sed -i "s|PORT_ANYTLS_PLACEHOLDER|$PORT_ANYTLS|g;s|ANYTLS_USER_PLACEHOLDER|$ANYTLS_USER|g;s|ANYTLS_PSK_PLACEHOLDER|$ANYTLS_PSK|g" "$TEMP_INBOUNDS"
        sed -i "s|REALITY_PK_PLACEHOLDER|$REALITY_PK|g;s|REALITY_SID_PLACEHOLDER|$REALITY_SID|g;s|REALITY_SNI_PLACEHOLDER|$REALITY_SNI|g" "$TEMP_INBOUNDS"
    fi

    cat > "$CONFIG_PATH" <<'CONFIG_HEAD'
{
  "log": {"level": "info", "timestamp": true},
  "ntp": {"enabled": true, "server": "time.apple.com", "server_port": 123, "interval": "30m"},
  "inbounds": [
CONFIG_HEAD
    cat "$TEMP_INBOUNDS" >> "$CONFIG_PATH"
    cat >> "$CONFIG_PATH" <<'CONFIG_TAIL'
  ],
  "outbounds": [{"type": "direct", "tag": "direct-out"}]
}
CONFIG_TAIL
    rm -f "$TEMP_INBOUNDS"

    sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1 \
        && info "$(msg config_ok)" \
        || warn "$(msg config_warn)"

    cat > /etc/sing-box/.config_cache <<CACHEEOF
ENABLE_SS=$ENABLE_SS
ENABLE_HY2=$ENABLE_HY2
ENABLE_TUIC=$ENABLE_TUIC
ENABLE_REALITY=$ENABLE_REALITY
ENABLE_ANYTLS=$ENABLE_ANYTLS
CACHEEOF
    $ENABLE_SS      && printf "SS_PORT=%s\nSS_PSK=%s\nSS_METHOD=%s\n"         "$PORT_SS"      "$PSK_SS"      "$SS_METHOD"   >> /etc/sing-box/.config_cache
    $ENABLE_HY2     && printf "HY2_PORT=%s\nHY2_PSK=%s\n"                     "$PORT_HY2"     "$PSK_HY2"                    >> /etc/sing-box/.config_cache
    $ENABLE_TUIC    && printf "TUIC_PORT=%s\nTUIC_UUID=%s\nTUIC_PSK=%s\n"     "$PORT_TUIC"    "$UUID_TUIC"   "$PSK_TUIC"    >> /etc/sing-box/.config_cache
    $ENABLE_REALITY && printf "REALITY_PORT=%s\nREALITY_UUID=%s\nREALITY_PK=%s\nREALITY_SID=%s\nREALITY_PUB=%s\nREALITY_SNI=%s\n" \
                               "$PORT_REALITY" "$UUID" "$REALITY_PK" "$REALITY_SID" "$REALITY_PUB" "$REALITY_SNI" >> /etc/sing-box/.config_cache
    $ENABLE_ANYTLS  && printf "ANYTLS_PORT=%s\nANYTLS_USER=%s\nANYTLS_PSK=%s\n" "$PORT_ANYTLS" "$ANYTLS_USER" "$ANYTLS_PSK" >> /etc/sing-box/.config_cache
    echo "CUSTOM_IP=$CUSTOM_IP" >> /etc/sing-box/.config_cache
    info "$(msg config_saved)"
}
create_config

SERVICE_PATH=""
setup_service() {
    info "$(msg setup_service)"
    if [ "$OS" = "alpine" ]; then
        SERVICE_PATH="/etc/init.d/sing-box"
        cat > "$SERVICE_PATH" <<'OPENRC'
#!/sbin/openrc-run
name="sing-box"
description="Sing-box Proxy Server"
command="/usr/bin/sing-box"
command_args="run -c /etc/sing-box/config.json"
pidfile="/run/${RC_SVCNAME}.pid"
command_background="yes"
output_log="/var/log/sing-box.log"
error_log="/var/log/sing-box.err"
supervisor=supervise-daemon
supervise_daemon_args="--respawn-max 0 --respawn-delay 5"
depend() { need net; after firewall; }
start_pre() {
    checkpath --directory --mode 0755 /var/log
    checkpath --directory --mode 0755 /run
}
OPENRC
        chmod +x "$SERVICE_PATH"
        rc-update add sing-box default >/dev/null 2>&1 || warn "$(msg svc_start_fail)"
        rc-service sing-box restart || {
            err "$(msg svc_start_fail)"
            tail -20 /var/log/sing-box.err 2>/dev/null || true
            exit 1
        }
        sleep 2
        rc-service sing-box status >/dev/null 2>&1 && info "$(msg svc_ok_openrc)" || { err "$(msg svc_abnormal)"; exit 1; }
    else
        SERVICE_PATH="/etc/systemd/system/sing-box.service"
        cat > "$SERVICE_PATH" <<'SYSTEMD'
[Unit]
Description=Sing-box Proxy Server
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target
Wants=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/etc/sing-box
ExecStart=/usr/bin/sing-box run -c /etc/sing-box/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
SYSTEMD
        systemctl daemon-reload
        systemctl enable sing-box >/dev/null 2>&1
        systemctl restart sing-box || {
            err "$(msg svc_start_fail)"
            journalctl -u sing-box -n 30 --no-pager
            exit 1
        }
        sleep 2
        systemctl is-active sing-box >/dev/null 2>&1 && info "$(msg svc_ok_systemd)" || { err "$(msg svc_abnormal)"; exit 1; }
    fi
    info "$(msg svc_done): $SERVICE_PATH"
}
setup_service

get_public_ip() {
    local ip=""
    for url in "https://api.ipify.org" "https://ipinfo.io/ip" "https://ifconfig.me" "https://icanhazip.com"; do
        ip=$(curl -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]' || true)
        [ -n "$ip" ] && echo "$ip" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' && { echo "$ip"; return 0; }
    done
    return 1
}

if [ -n "${CUSTOM_IP:-}" ]; then
    PUB_IP="$CUSTOM_IP"; info "$(msg using_custom_ip): $PUB_IP"
else
    PUB_IP=$(get_public_ip || echo "YOUR_SERVER_IP")
    [ "$PUB_IP" = "YOUR_SERVER_IP" ] && warn "$(msg pub_ip_fail)" || info "$(msg pub_ip_ok): $PUB_IP"
fi

generate_uris() {
    local host="${PUB_IP:-YOUR_SERVER_IP}"
    local node_suffix="${suffix:-}"
    if $ENABLE_SS; then
        ss_userinfo="${SS_METHOD}:${PSK_SS}"
        ss_encoded=$(printf "%s" "$ss_userinfo" | sed 's/:/%3A/g; s/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
        ss_b64=$(printf "%s" "$ss_userinfo" | base64 -w0 2>/dev/null || printf "%s" "$ss_userinfo" | base64 | tr -d '\n')
        echo "=== Shadowsocks (SS) ==="
        echo "ss://${ss_encoded}@${host}:${PORT_SS}#ss${node_suffix}"
        echo "ss://${ss_b64}@${host}:${PORT_SS}#ss${node_suffix}"
        echo ""
    fi
    if $ENABLE_HY2; then
        hy2_encoded=$(printf "%s" "$PSK_HY2" | sed 's/:/%3A/g; s/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
        echo "=== Hysteria2 (HY2) ==="
        echo "hy2://${hy2_encoded}@${host}:${PORT_HY2}/?sni=www.bing.com&alpn=h3&insecure=1#hy2${node_suffix}"
        echo ""
    fi
    if $ENABLE_TUIC; then
        tuic_encoded=$(printf "%s" "$PSK_TUIC" | sed 's/:/%3A/g; s/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
        echo "=== TUIC ==="
        echo "tuic://${UUID_TUIC}:${tuic_encoded}@${host}:${PORT_TUIC}/?congestion_control=bbr&alpn=h3&sni=www.bing.com&insecure=1#tuic${node_suffix}"
        echo ""
    fi
    if $ENABLE_REALITY; then
        echo "=== VLESS Reality ==="
        echo "vless://${UUID}@${host}:${PORT_REALITY}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}#reality${node_suffix}"
        echo ""
    fi
    if $ENABLE_ANYTLS; then
        anytls_pass_encoded=$(printf "%s" "$ANYTLS_PSK" | sed 's/:/%3A/g; s/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
        echo "=== AnyTLS Reality ==="
        echo "anytls://${anytls_pass_encoded}@${host}:${PORT_ANYTLS}/?security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}#anytls${node_suffix}"
        echo ""
    fi
}

echo ""
echo "=========================================="
info "$(msg deploy_done)"
echo "=========================================="
echo ""
info "$(msg config_info)"
$ENABLE_SS      && echo "   SS $(msg port_label): $PORT_SS | $(msg method_label): $SS_METHOD"
$ENABLE_HY2     && echo "   HY2 $(msg port_label): $PORT_HY2"
$ENABLE_TUIC    && echo "   TUIC $(msg port_label): $PORT_TUIC | UUID: $UUID_TUIC"
$ENABLE_REALITY && echo "   Reality $(msg port_label): $PORT_REALITY | UUID: $UUID"
$ENABLE_ANYTLS  && echo "   AnyTLS $(msg port_label): $PORT_ANYTLS | User: $ANYTLS_USER"
echo "   $(msg server_label): $PUB_IP"
echo "   $(msg sni_label): ${REALITY_SNI:-addons.mozilla.org}"
echo ""
info "$(msg file_loc)"
echo "   Config: $CONFIG_PATH"
($ENABLE_HY2 || $ENABLE_TUIC) && echo "   Cert: /etc/sing-box/certs/"
echo "   Service: $SERVICE_PATH"
echo ""
info "$(msg client_links)"
generate_uris | while IFS= read -r line; do echo "   $line"; done
echo ""
info "$(msg mgmt_cmds)"
if [ "$OS" = "alpine" ]; then
    echo "   start:   rc-service sing-box start"
    echo "   stop:    rc-service sing-box stop"
    echo "   restart: rc-service sing-box restart"
    echo "   status:  rc-service sing-box status"
    echo "   log:     tail -f /var/log/sing-box.log"
else
    echo "   start:   systemctl start sing-box"
    echo "   stop:    systemctl stop sing-box"
    echo "   restart: systemctl restart sing-box"
    echo "   status:  systemctl status sing-box"
    echo "   log:     journalctl -u sing-box -f"
fi
echo ""
echo "=========================================="

SB_PATH="/usr/local/bin/candies-sb"
info "$(msg creating_sb): $SB_PATH"

cat > "$SB_PATH" <<'SB_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

LANG_CODE="zh_CN"
[ -f /etc/sing-box/.lang ] && . /etc/sing-box/.lang

msg() {
    local key="$1" text=""
    case "$LANG_CODE" in
        zh_CN) case "$key" in
            menu_title)      text="Candies Sing-box 管理面板 (快捷指令candies-sb)" ;;
            menu_view_uri)   text="查看协议链接" ;;
            menu_view_cfg)   text="查看配置文件路径" ;;
            menu_edit_cfg)   text="编辑配置文件" ;;
            menu_reset_ss)   text="重置 SS 端口" ;;
            menu_reset_hy2)  text="重置 HY2 端口" ;;
            menu_reset_tuic) text="重置 TUIC 端口" ;;
            menu_reset_rl)   text="重置 Vless Reality 端口" ;;
            menu_reset_at)   text="重置 AnyTLS Reality 端口" ;;
            menu_start)      text="启动服务" ;;
            menu_stop)       text="停止服务" ;;
            menu_restart)    text="重启服务" ;;
            menu_status)     text="查看状态" ;;
            menu_update)     text="更新 sing-box" ;;
            menu_relay)      text="生成线路机脚本(出口为本机ss协议)" ;;
            menu_uninstall)  text="卸载 sing-box" ;;
            menu_exit)       text="退出" ;;
            menu_enter)      text="请输入选项: " ;;
            started)         text="已启动" ;;
            stopped)         text="已停止" ;;
            restarted)       text="已重启" ;;
            generating_uri)  text="正在生成并显示 URI..." ;;
            uri_fail)        text="生成 URI 失败" ;;
            uri_saved)       text="URI 已保存到" ;;
            cfg_not_found)   text="配置文件不存在" ;;
            cfg_ok)          text="配置校验通过,已重启服务" ;;
            cfg_fail)        text="配置校验失败,服务未重启" ;;
            proto_disabled)  text="协议未启用" ;;
            new_port)        text="输入新端口(回车保持当前): " ;;
            svc_stop)        text="正在停止服务..." ;;
            svc_start)       text="已启动服务并更新端口" ;;
            svc_stop_fail)   text="停止服务失败" ;;
            svc_start_fail)  text="启动服务失败" ;;
            updating)        text="开始更新 sing-box..." ;;
            update_done)     text="更新完成,已重启服务" ;;
            update_fail)     text="更新失败" ;;
            uninstall_q)     text="确认卸载 sing-box?(y/N): " ;;
            uninstall_cancel) text="已取消" ;;
            uninstalling)    text="正在卸载..." ;;
            uninstall_done)  text="卸载完成" ;;
            no_ss_relay)     text="未检测到 SS 协议,需要先部署 SS 作为入站" ;;
            deploy_ss_q)     text="是否现在部署 SS 协议?(y/N): " ;;
            deploy_ss_ing)   text="开始部署 SS 协议..." ;;
            relay_cancel)    text="取消生成线路机脚本" ;;
            relay_gen)       text="正在生成线路机脚本" ;;
            relay_done)      text="✅ 线路机脚本已生成" ;;
            relay_copy)      text="请复制以下内容到线路机执行:" ;;
            relay_exec)      text="在线路机执行命令示例：" ;;
            relay_finish)    text="复制执行完成后，即可在线路机完成 sing-box 中转节点部署。" ;;
            invalid_opt)     text="无效选项" ;;
        esac ;;
        zh_TW) case "$key" in
            menu_title)      text="Candies Sing-box 管理面板 (快捷指令candies-sb)" ;;
            menu_view_uri)   text="查看協議連結" ;;
            menu_view_cfg)   text="查看設定檔路徑" ;;
            menu_edit_cfg)   text="編輯設定檔" ;;
            menu_reset_ss)   text="重置 SS 連接埠" ;;
            menu_reset_hy2)  text="重置 HY2 連接埠" ;;
            menu_reset_tuic) text="重置 TUIC 連接埠" ;;
            menu_reset_rl)   text="重置 Vless Reality 連接埠" ;;
            menu_reset_at)   text="重置 AnyTLS Reality 連接埠" ;;
            menu_start)      text="啟動服務" ;;
            menu_stop)       text="停止服務" ;;
            menu_restart)    text="重啟服務" ;;
            menu_status)     text="查看狀態" ;;
            menu_update)     text="更新 sing-box" ;;
            menu_relay)      text="生成線路機腳本(出口為本機ss協議)" ;;
            menu_uninstall)  text="解除安裝 sing-box" ;;
            menu_exit)       text="退出" ;;
            menu_enter)      text="請輸入選項: " ;;
            started)         text="已啟動" ;;
            stopped)         text="已停止" ;;
            restarted)       text="已重啟" ;;
            generating_uri)  text="正在生成並顯示 URI..." ;;
            uri_fail)        text="生成 URI 失敗" ;;
            uri_saved)       text="URI 已儲存到" ;;
            cfg_not_found)   text="設定檔不存在" ;;
            cfg_ok)          text="設定驗證通過,已重啟服務" ;;
            cfg_fail)        text="設定驗證失敗,服務未重啟" ;;
            proto_disabled)  text="協議未啟用" ;;
            new_port)        text="輸入新連接埠(回車保持目前): " ;;
            svc_stop)        text="正在停止服務..." ;;
            svc_start)       text="已啟動服務並更新連接埠" ;;
            svc_stop_fail)   text="停止服務失敗" ;;
            svc_start_fail)  text="啟動服務失敗" ;;
            updating)        text="開始更新 sing-box..." ;;
            update_done)     text="更新完成,已重啟服務" ;;
            update_fail)     text="更新失敗" ;;
            uninstall_q)     text="確認解除安裝 sing-box?(y/N): " ;;
            uninstall_cancel) text="已取消" ;;
            uninstalling)    text="正在解除安裝..." ;;
            uninstall_done)  text="解除安裝完成" ;;
            no_ss_relay)     text="未偵測到 SS 協議,需要先部署 SS 作為入站" ;;
            deploy_ss_q)     text="是否現在部署 SS 協議?(y/N): " ;;
            deploy_ss_ing)   text="開始部署 SS 協議..." ;;
            relay_cancel)    text="取消生成線路機腳本" ;;
            relay_gen)       text="正在生成線路機腳本" ;;
            relay_done)      text="✅ 線路機腳本已生成" ;;
            relay_copy)      text="請複製以下內容到線路機執行:" ;;
            relay_exec)      text="在線路機執行指令範例：" ;;
            relay_finish)    text="複製執行完成後，即可在線路機完成 sing-box 中轉節點部署。" ;;
            invalid_opt)     text="無效選項" ;;
        esac ;;
        ja) case "$key" in
            menu_title)      text="Candies Sing-box 管理パネル (コマンド: candies-sb)" ;;
            menu_view_uri)   text="ノードリンクを表示" ;;
            menu_view_cfg)   text="設定ファイルのパスを表示" ;;
            menu_edit_cfg)   text="設定ファイルを編集" ;;
            menu_reset_ss)   text="SS ポートをリセット" ;;
            menu_reset_hy2)  text="HY2 ポートをリセット" ;;
            menu_reset_tuic) text="TUIC ポートをリセット" ;;
            menu_reset_rl)   text="Vless Reality ポートをリセット" ;;
            menu_reset_at)   text="AnyTLS Reality ポートをリセット" ;;
            menu_start)      text="サービスを起動" ;;
            menu_stop)       text="サービスを停止" ;;
            menu_restart)    text="サービスを再起動" ;;
            menu_status)     text="ステータスを確認" ;;
            menu_update)     text="sing-box を更新" ;;
            menu_relay)      text="リレーサーバースクリプトを生成" ;;
            menu_uninstall)  text="sing-box をアンインストール" ;;
            menu_exit)       text="終了" ;;
            menu_enter)      text="番号を入力してください: " ;;
            started)         text="起動しました" ;;
            stopped)         text="停止しました" ;;
            restarted)       text="再起動しました" ;;
            generating_uri)  text="URI を生成して表示しています..." ;;
            uri_fail)        text="URI の生成に失敗しました" ;;
            uri_saved)       text="URI を保存しました:" ;;
            cfg_not_found)   text="設定ファイルが見つかりません" ;;
            cfg_ok)          text="設定の検証に成功しました。サービスを再起動します" ;;
            cfg_fail)        text="設定の検証に失敗しました。サービスは再起動されません" ;;
            proto_disabled)  text="プロトコルが有効になっていません" ;;
            new_port)        text="新しいポートを入力(Enterで現在のポートを維持): " ;;
            svc_stop)        text="サービスを停止しています..." ;;
            svc_start)       text="サービスを起動し、ポートを更新しました" ;;
            svc_stop_fail)   text="サービスの停止に失敗しました" ;;
            svc_start_fail)  text="サービスの起動に失敗しました" ;;
            updating)        text="sing-box の更新を開始..." ;;
            update_done)     text="更新完了。サービスを再起動しました" ;;
            update_fail)     text="更新に失敗しました" ;;
            uninstall_q)     text="sing-box をアンインストールしますか?(y/N): " ;;
            uninstall_cancel) text="キャンセルしました" ;;
            uninstalling)    text="アンインストール中..." ;;
            uninstall_done)  text="アンインストール完了" ;;
            no_ss_relay)     text="SS プロトコルが検出されませんでした" ;;
            deploy_ss_q)     text="SS プロトコルをデプロイしますか?(y/N): " ;;
            deploy_ss_ing)   text="SS プロトコルのデプロイを開始..." ;;
            relay_cancel)    text="リレースクリプトの生成をキャンセルしました" ;;
            relay_gen)       text="リレーサーバースクリプトを生成中" ;;
            relay_done)      text="✅ リレーサーバースクリプトを生成しました" ;;
            relay_copy)      text="以下の内容をリレーサーバーにコピーして実行してください:" ;;
            relay_exec)      text="リレーサーバーでの実行例：" ;;
            relay_finish)    text="コピー実行後、リレーサーバーで sing-box の中継ノードのデプロイが完了します。" ;;
            invalid_opt)     text="無効なオプションです" ;;
        esac ;;
        en) case "$key" in
            menu_title)      text="Candies Sing-box Management Panel (command: candies-sb)" ;;
            menu_view_uri)   text="View node links" ;;
            menu_view_cfg)   text="View config file path" ;;
            menu_edit_cfg)   text="Edit config file" ;;
            menu_reset_ss)   text="Reset SS port" ;;
            menu_reset_hy2)  text="Reset HY2 port" ;;
            menu_reset_tuic) text="Reset TUIC port" ;;
            menu_reset_rl)   text="Reset Vless Reality port" ;;
            menu_reset_at)   text="Reset AnyTLS Reality port" ;;
            menu_start)      text="Start service" ;;
            menu_stop)       text="Stop service" ;;
            menu_restart)    text="Restart service" ;;
            menu_status)     text="View status" ;;
            menu_update)     text="Update sing-box" ;;
            menu_relay)      text="Generate relay server script" ;;
            menu_uninstall)  text="Uninstall sing-box" ;;
            menu_exit)       text="Exit" ;;
            menu_enter)      text="Enter option: " ;;
            started)         text="Started" ;;
            stopped)         text="Stopped" ;;
            restarted)       text="Restarted" ;;
            generating_uri)  text="Generating and displaying URIs..." ;;
            uri_fail)        text="Failed to generate URIs" ;;
            uri_saved)       text="URI saved to" ;;
            cfg_not_found)   text="Config file not found" ;;
            cfg_ok)          text="Config validated, service restarted" ;;
            cfg_fail)        text="Config validation failed, service not restarted" ;;
            proto_disabled)  text="Protocol not enabled" ;;
            new_port)        text="Enter new port (Enter to keep current): " ;;
            svc_stop)        text="Stopping service..." ;;
            svc_start)       text="Service started and port updated" ;;
            svc_stop_fail)   text="Failed to stop service" ;;
            svc_start_fail)  text="Failed to start service" ;;
            updating)        text="Updating sing-box..." ;;
            update_done)     text="Update complete, service restarted" ;;
            update_fail)     text="Update failed" ;;
            uninstall_q)     text="Confirm uninstall sing-box? (y/N): " ;;
            uninstall_cancel) text="Cancelled" ;;
            uninstalling)    text="Uninstalling..." ;;
            uninstall_done)  text="Uninstall complete" ;;
            no_ss_relay)     text="SS protocol not detected, deploy SS first" ;;
            deploy_ss_q)     text="Deploy SS protocol now? (y/N): " ;;
            deploy_ss_ing)   text="Deploying SS protocol..." ;;
            relay_cancel)    text="Relay script generation cancelled" ;;
            relay_gen)       text="Generating relay server script" ;;
            relay_done)      text="✅ Relay server script generated" ;;
            relay_copy)      text="Copy the following to the relay server and execute:" ;;
            relay_exec)      text="Example command on relay server:" ;;
            relay_finish)    text="After copying and executing, sing-box relay node deployment will be complete." ;;
            invalid_opt)     text="Invalid option" ;;
        esac ;;
    esac
    echo "$text"
}

info() { echo -e "\033[1;34m[Candies-INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[Candies-WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[Candies-ERR]\033[0m $*" >&2; }

CONFIG_PATH="/etc/sing-box/config.json"
CACHE_FILE="/etc/sing-box/.config_cache"
SERVICE_NAME="sing-box"

detect_os() {
    if [ -f /etc/os-release ]; then . /etc/os-release; ID="${ID:-}"; ID_LIKE="${ID_LIKE:-}"
    else ID=""; ID_LIKE=""; fi
    if echo "$ID $ID_LIKE" | grep -qi "alpine"; then OS="alpine"
    elif echo "$ID $ID_LIKE" | grep -Ei "debian|ubuntu" >/dev/null; then OS="debian"
    elif echo "$ID $ID_LIKE" | grep -Ei "centos|rhel|fedora" >/dev/null; then OS="redhat"
    else OS="unknown"; fi
}
detect_os

service_start()   { [ "$OS" = "alpine" ] && rc-service "$SERVICE_NAME" start   || systemctl start   "$SERVICE_NAME"; }
service_stop()    { [ "$OS" = "alpine" ] && rc-service "$SERVICE_NAME" stop    || systemctl stop    "$SERVICE_NAME"; }
service_restart() { [ "$OS" = "alpine" ] && rc-service "$SERVICE_NAME" restart || systemctl restart "$SERVICE_NAME"; }
service_status()  { [ "$OS" = "alpine" ] && rc-service "$SERVICE_NAME" status  || systemctl status  "$SERVICE_NAME" --no-pager; }

rand_port() { shuf -i 10000-60000 -n 1 2>/dev/null || echo $((RANDOM % 50001 + 10000)); }
rand_pass()  { openssl rand -base64 16 | tr -d '\n\r' || head -c 16 /dev/urandom | base64 | tr -d '\n\r'; }
rand_uuid()  { cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16; }
url_encode() { printf "%s" "$1" | sed -e 's/%/%25/g' -e 's/:/%3A/g' -e 's/+/%2B/g' -e 's/\//%2F/g' -e 's/=/%3D/g'; }

read_config() {
    [ -f "$CONFIG_PATH" ] || { err "$(msg cfg_not_found): $CONFIG_PATH"; return 1; }
    [ -f "/etc/sing-box/.protocols" ] && . "/etc/sing-box/.protocols"
    [ -f "$CACHE_FILE" ] && . "$CACHE_FILE"
    REALITY_SNI="${REALITY_SNI:-addons.mozilla.org}"
    ENABLE_ANYTLS="${ENABLE_ANYTLS:-false}"
    CUSTOM_IP="${CUSTOM_IP:-}"
    [ "${ENABLE_SS:-false}"      = "true" ] && {
        SS_PORT=$(jq -r '.inbounds[]|select(.type=="shadowsocks")|.listen_port//empty' "$CONFIG_PATH" | head -n1)
        SS_PSK=$(jq  -r '.inbounds[]|select(.type=="shadowsocks")|.password//empty'    "$CONFIG_PATH" | head -n1)
        SS_METHOD=$(jq -r '.inbounds[]|select(.type=="shadowsocks")|.method//empty'    "$CONFIG_PATH" | head -n1)
    }
    [ "${ENABLE_HY2:-false}"     = "true" ] && {
        HY2_PORT=$(jq -r '.inbounds[]|select(.type=="hysteria2")|.listen_port//empty'         "$CONFIG_PATH" | head -n1)
        HY2_PSK=$(jq  -r '.inbounds[]|select(.type=="hysteria2")|.users[0].password//empty'   "$CONFIG_PATH" | head -n1)
    }
    [ "${ENABLE_TUIC:-false}"    = "true" ] && {
        TUIC_PORT=$(jq -r '.inbounds[]|select(.type=="tuic")|.listen_port//empty'       "$CONFIG_PATH" | head -n1)
        TUIC_UUID=$(jq -r '.inbounds[]|select(.type=="tuic")|.users[0].uuid//empty'     "$CONFIG_PATH" | head -n1)
        TUIC_PSK=$(jq  -r '.inbounds[]|select(.type=="tuic")|.users[0].password//empty' "$CONFIG_PATH" | head -n1)
    }
    if [ "${ENABLE_REALITY:-false}" = "true" ] || [ "${ENABLE_ANYTLS:-false}" = "true" ]; then
        REALITY_SID=$(jq -r '.inbounds[]|select(.tls.reality.enabled==true)|.tls.reality.short_id[0]//empty' "$CONFIG_PATH" | head -n1)
        [ -f /etc/sing-box/.reality_pub ] && REALITY_PUB=$(cat /etc/sing-box/.reality_pub)
    fi
    [ "${ENABLE_REALITY:-false}" = "true" ] && {
        REALITY_PORT=$(jq -r '.inbounds[]|select(.type=="vless")|.listen_port//empty'              "$CONFIG_PATH" | head -n1)
        REALITY_UUID=$(jq -r '.inbounds[]|select(.type=="vless")|.users[0].uuid//empty'            "$CONFIG_PATH" | head -n1)
        REALITY_PK=$(jq   -r '.inbounds[]|select(.type=="vless")|.tls.reality.private_key//empty'  "$CONFIG_PATH" | head -n1)
    }
    [ "${ENABLE_ANYTLS:-false}"  = "true" ] && {
        ANYTLS_PORT=$(jq -r '.inbounds[]|select(.type=="anytls")|.listen_port//empty'         "$CONFIG_PATH" | head -n1)
        ANYTLS_USER=$(jq -r '.inbounds[]|select(.type=="anytls")|.users[0].name//empty'       "$CONFIG_PATH" | head -n1)
        ANYTLS_PSK=$(jq  -r '.inbounds[]|select(.type=="anytls")|.users[0].password//empty'   "$CONFIG_PATH" | head -n1)
    }
}

get_public_ip() {
    local ip=""
    for url in "https://api.ipify.org" "https://ipinfo.io/ip" "https://ifconfig.me"; do
        ip=$(curl -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]')
        [ -n "$ip" ] && echo "$ip" && return 0
    done
    echo "YOUR_SERVER_IP"
}

generate_uris() {
    read_config || return 1
    [ -n "${CUSTOM_IP:-}" ] && PUBLIC_IP="$CUSTOM_IP" || PUBLIC_IP=$(get_public_ip)
    node_suffix=$(cat /root/node_names.txt 2>/dev/null || echo "")
    URI_FILE="/etc/sing-box/uris.txt"
    > "$URI_FILE"
    [ "${ENABLE_SS:-false}" = "true" ] && {
        ss_userinfo="${SS_METHOD}:${SS_PSK}"
        ss_encoded=$(url_encode "$ss_userinfo")
        ss_b64=$(printf "%s" "$ss_userinfo" | base64 -w0 2>/dev/null || printf "%s" "$ss_userinfo" | base64 | tr -d '\n')
        { echo "=== Shadowsocks (SS) ==="; echo "ss://${ss_encoded}@${PUBLIC_IP}:${SS_PORT}#ss${node_suffix}"; echo "ss://${ss_b64}@${PUBLIC_IP}:${SS_PORT}#ss${node_suffix}"; echo ""; } >> "$URI_FILE"
    }
    [ "${ENABLE_HY2:-false}" = "true" ] && {
        hy2_encoded=$(url_encode "$HY2_PSK")
        { echo "=== Hysteria2 (HY2) ==="; echo "hy2://${hy2_encoded}@${PUBLIC_IP}:${HY2_PORT}/?sni=www.bing.com&alpn=h3&insecure=1#hy2${node_suffix}"; echo ""; } >> "$URI_FILE"
    }
    [ "${ENABLE_TUIC:-false}" = "true" ] && {
        tuic_encoded=$(url_encode "$TUIC_PSK")
        { echo "=== TUIC ==="; echo "tuic://${TUIC_UUID}:${tuic_encoded}@${PUBLIC_IP}:${TUIC_PORT}/?congestion_control=bbr&alpn=h3&sni=www.bing.com&insecure=1#tuic${node_suffix}"; echo ""; } >> "$URI_FILE"
    }
    [ "${ENABLE_REALITY:-false}" = "true" ] && {
        { echo "=== VLESS Reality ==="; echo "vless://${REALITY_UUID}@${PUBLIC_IP}:${REALITY_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}#reality${node_suffix}"; echo ""; } >> "$URI_FILE"
    }
    [ "${ENABLE_ANYTLS:-false}" = "true" ] && {
        anytls_pass_encoded=$(url_encode "$ANYTLS_PSK")
        { echo "=== AnyTLS Reality ==="; echo "anytls://${anytls_pass_encoded}@${PUBLIC_IP}:${ANYTLS_PORT}/?security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}#anytls${node_suffix}"; echo ""; } >> "$URI_FILE"
    }
    info "$(msg uri_saved): $URI_FILE"
}

action_view_uri() {
    info "$(msg generating_uri)"
    generate_uris || { err "$(msg uri_fail)"; return 1; }
    echo ""
    cat /etc/sing-box/uris.txt
}

action_view_config() { echo "$CONFIG_PATH"; }

action_edit_config() {
    [ -f "$CONFIG_PATH" ] || { err "$(msg cfg_not_found): $CONFIG_PATH"; return 1; }
    ${EDITOR:-nano} "$CONFIG_PATH" 2>/dev/null || ${EDITOR:-vi} "$CONFIG_PATH"
    sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1 \
        && { info "$(msg cfg_ok)"; service_restart || warn "$(msg svc_start_fail)"; generate_uris || true; } \
        || warn "$(msg cfg_fail)"
}

_reset_port() {
    local jq_type="$1" cur_port="$2"
    read_config || return 1
    read -p "$(msg new_port)" new_port
    new_port="${new_port:-$cur_port}"
    info "$(msg svc_stop)"
    service_stop || warn "$(msg svc_stop_fail)"
    cp "$CONFIG_PATH" "${CONFIG_PATH}.bak"
    jq --argjson port "$new_port" ".inbounds |= map(if .type==\"$jq_type\" then .listen_port = \$port else . end)" \
        "$CONFIG_PATH" > "${CONFIG_PATH}.tmp" && mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
    info "$(msg svc_start): $new_port"
    service_start || warn "$(msg svc_start_fail)"
    sleep 1
    generate_uris || warn "$(msg uri_fail)"
}

action_reset_ss()      { [ "${ENABLE_SS:-false}"      = "true" ] || { err "$(msg proto_disabled): SS";            return 1; }; _reset_port "shadowsocks" "$SS_PORT"; }
action_reset_hy2()     { [ "${ENABLE_HY2:-false}"     = "true" ] || { err "$(msg proto_disabled): HY2";           return 1; }; _reset_port "hysteria2"   "$HY2_PORT"; }
action_reset_tuic()    { [ "${ENABLE_TUIC:-false}"    = "true" ] || { err "$(msg proto_disabled): TUIC";          return 1; }; _reset_port "tuic"         "$TUIC_PORT"; }
action_reset_reality() { [ "${ENABLE_REALITY:-false}" = "true" ] || { err "$(msg proto_disabled): VLESS Reality"; return 1; }; _reset_port "vless"        "$REALITY_PORT"; }
action_reset_anytls()  { [ "${ENABLE_ANYTLS:-false}"  = "true" ] || { err "$(msg proto_disabled): AnyTLS";        return 1; }; _reset_port "anytls"       "$ANYTLS_PORT"; }

action_update() {
    info "$(msg updating)"
    if [ "$OS" = "alpine" ]; then
        apk update && apk upgrade sing-box || bash <(curl -fsSL https://sing-box.app/install.sh)
    else
        bash <(curl -fsSL https://sing-box.app/install.sh)
    fi
    command -v sing-box >/dev/null 2>&1 \
        && { info "$(msg update_done): $(sing-box version 2>/dev/null | head -n1)"; service_restart || warn "$(msg svc_start_fail)"; } \
        || warn "$(msg update_fail)"
}

action_uninstall() {
    read -p "$(msg uninstall_q)" confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && info "$(msg uninstall_cancel)" && return 0
    info "$(msg uninstalling)"
    service_stop || true
    if [ "$OS" = "alpine" ]; then
        rc-update del sing-box default 2>/dev/null || true
        rm -f /etc/init.d/sing-box
        apk del sing-box 2>/dev/null || true
    else
        systemctl stop sing-box 2>/dev/null || true
        systemctl disable sing-box 2>/dev/null || true
        rm -f /etc/systemd/system/sing-box.service
        systemctl daemon-reload 2>/dev/null || true
        apt purge -y sing-box >/dev/null 2>&1 || true
    fi
    rm -rf /etc/sing-box /var/log/sing-box* /usr/local/bin/candies-sb /usr/bin/sing-box /root/node_names.txt 2>/dev/null || true
    info "$(msg uninstall_done)"
}

action_generate_relay() {
    read_config || return 1
    if [ "${ENABLE_SS:-false}" != "true" ]; then
        warn "$(msg no_ss_relay)"
        read -p "$(msg deploy_ss_q)" deploy_ss
        if [[ "$deploy_ss" =~ ^[Yy]$ ]]; then
            info "$(msg deploy_ss_ing)"
            read -p "SS port (blank=random): " USER_SS_PORT
            SS_PORT="${USER_SS_PORT:-$(rand_port)}"
            SS_PSK=$(rand_pass); SS_METHOD="aes-128-gcm"
            service_stop || warn "$(msg svc_stop_fail)"
            cp "$CONFIG_PATH" "${CONFIG_PATH}.bak"
            jq --argjson port "$SS_PORT" --arg psk "$SS_PSK" \
                '.inbounds += [{"type":"shadowsocks","listen":"::","listen_port":$port,"method":"aes-128-gcm","password":$psk,"tag":"ss-in"}]' \
                "$CONFIG_PATH" > "${CONFIG_PATH}.tmp" && mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
            sed -i 's/ENABLE_SS=false/ENABLE_SS=true/' "$CACHE_FILE" 2>/dev/null || echo "ENABLE_SS=true" >> "$CACHE_FILE"
            { echo "SS_PORT=$SS_PORT"; echo "SS_PSK=$SS_PSK"; echo "SS_METHOD=$SS_METHOD"; } >> "$CACHE_FILE"
            PROTOCOL_FILE="/etc/sing-box/.protocols"
            [ -f "$PROTOCOL_FILE" ] && sed -i 's/ENABLE_SS=false/ENABLE_SS=true/' "$PROTOCOL_FILE" || echo "ENABLE_SS=true" >> "$PROTOCOL_FILE"
            ENABLE_SS=true
            service_start || warn "$(msg svc_start_fail)"
            sleep 1; read_config
        else
            err "$(msg relay_cancel)"; return 1
        fi
    fi

    [ -n "${CUSTOM_IP:-}" ] && INBOUND_IP="${CUSTOM_IP}" || INBOUND_IP="$(get_public_ip)"
    RELAY_SCRIPT="/tmp/relay-install.sh"
    info "$(msg relay_gen): $RELAY_SCRIPT"

    cat > "$RELAY_SCRIPT" <<'RELAY_EOF'
#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\033[1;34m[Candies-INFO]\033[0m $*"; }
err()  { echo -e "\033[1;31m[Candies-ERR]\033[0m $*" >&2; }
[ "$(id -u)" != "0" ] && err "Must run as root" && exit 1
detect_os(){
    . /etc/os-release 2>/dev/null || true
    case "${ID:-}" in
        alpine) OS=alpine ;; debian|ubuntu) OS=debian ;; centos|rhel|fedora) OS=redhat ;; *) OS=unknown ;;
    esac
}
detect_os
info "Installing dependencies..."
case "$OS" in
    alpine) apk update; apk add --no-cache curl jq bash openssl ca-certificates ;;
    debian) apt-get update -y; apt-get install -y curl jq bash openssl ca-certificates ;;
    redhat) yum install -y curl jq bash openssl ca-certificates ;;
esac
info "Installing sing-box..."
case "$OS" in
    alpine) apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community sing-box ;;
    *) bash <(curl -fsSL https://sing-box.app/install.sh) ;;
esac
UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "00000000-0000-0000-0000-000000000000")
info "Generating Reality key pair..."
REALITY_KEYS=$(sing-box generate reality-keypair 2>/dev/null || echo "")
REALITY_PK=$(echo "$REALITY_KEYS"  | grep "PrivateKey" | awk '{print $NF}' | tr -d '\r' || echo "")
REALITY_PUB=$(echo "$REALITY_KEYS" | grep "PublicKey"  | awk '{print $NF}' | tr -d '\r' || echo "")
REALITY_SID=$(sing-box generate rand 8 --hex 2>/dev/null || echo "0123456789abcdef")
read -p "Enter relay listen port (blank=random 20000-65000): " USER_PORT
LISTEN_PORT="${USER_PORT:-$(shuf -i 20000-65000 -n 1 2>/dev/null || echo 20443)}"
mkdir -p /etc/sing-box
cat > /etc/sing-box/config.json <<EOF
{
  "log": { "level": "info", "timestamp": true },
  "inbounds": [{
    "type": "vless", "listen": "::", "listen_port": $LISTEN_PORT,
    "users": [{ "uuid": "$UUID", "flow": "xtls-rprx-vision" }],
    "tls": {
      "enabled": true, "server_name": "__REALITY_SNI__",
      "reality": {
        "enabled": true,
        "handshake": { "server": "__REALITY_SNI__", "server_port": 443 },
        "private_key": "$REALITY_PK", "short_id": ["$REALITY_SID"]
      }
    }, "tag": "vless-in"
  }],
  "outbounds": [
    { "type": "shadowsocks", "server": "__INBOUND_IP__", "server_port": __INBOUND_PORT__,
      "method": "__INBOUND_METHOD__", "password": "__INBOUND_PASSWORD__", "tag": "relay-out" },
    { "type": "direct", "tag": "direct-out" }
  ],
  "route": { "rules": [{ "inbound": "vless-in", "outbound": "relay-out" }] }
}
EOF
if [ "$OS" = "alpine" ]; then
    cat > /etc/init.d/sing-box <<'SVC'
#!/sbin/openrc-run
name="sing-box"
command="/usr/bin/sing-box"
command_args="run -c /etc/sing-box/config.json"
command_background="yes"
pidfile="/run/sing-box.pid"
supervisor=supervise-daemon
supervise_daemon_args="--respawn-max 0 --respawn-delay 5"
depend() { need net; }
SVC
    chmod +x /etc/init.d/sing-box
    rc-update add sing-box default
    rc-service sing-box restart
else
    cat > /etc/systemd/system/sing-box.service <<'SYSTEMD'
[Unit]
Description=Sing-box Relay
After=network.target
[Service]
ExecStart=/usr/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=10s
[Install]
WantedBy=multi-user.target
SYSTEMD
    systemctl daemon-reload; systemctl enable sing-box; systemctl restart sing-box
fi
PUB_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_RELAY_IP")
RELAY_URI="vless://$UUID@$PUB_IP:$LISTEN_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=__REALITY_SNI__&fp=chrome&pbk=$REALITY_PUB&sid=$REALITY_SID#relay"
mkdir -p /etc/sing-box
echo "$RELAY_URI" > /etc/sing-box/relay_uri.txt
echo ""
info "✅ Installation complete"
echo "=============== Relay Node Reality Link ==============="
echo "$RELAY_URI"
echo "======================================================="
info "Link saved to: /etc/sing-box/relay_uri.txt"
RELAY_EOF

    sed -i "s|__INBOUND_IP__|$INBOUND_IP|g"       "$RELAY_SCRIPT"
    sed -i "s|__INBOUND_PORT__|$SS_PORT|g"         "$RELAY_SCRIPT"
    sed -i "s|__INBOUND_METHOD__|$SS_METHOD|g"     "$RELAY_SCRIPT"
    sed -i "s|__INBOUND_PASSWORD__|$SS_PSK|g"      "$RELAY_SCRIPT"
    sed -i "s|__REALITY_SNI__|${REALITY_SNI:-addons.mozilla.org}|g" "$RELAY_SCRIPT"
    chmod +x "$RELAY_SCRIPT"

    info "$(msg relay_done): $RELAY_SCRIPT"
    echo ""
    info "$(msg relay_copy)"
    echo "----------------------------------------"
    cat "$RELAY_SCRIPT"
    echo "----------------------------------------"
    echo ""
    info "$(msg relay_exec)"
    echo "   nano /tmp/relay-install.sh"
    echo "   chmod +x /tmp/relay-install.sh && bash /tmp/relay-install.sh"
    echo ""
    info "$(msg relay_finish)"
}

show_menu() {
    read_config 2>/dev/null || true
    echo ""
    echo "=========================="
    echo " $(msg menu_title)"
    echo "=========================="
    echo "1) $(msg menu_view_uri)"
    echo "2) $(msg menu_view_cfg)"
    echo "3) $(msg menu_edit_cfg)"
    declare -g -A MENU_MAP
    local option=4
    [ "${ENABLE_SS:-false}"      = "true" ] && { echo "$option) $(msg menu_reset_ss)";   MENU_MAP[$option]="reset_ss";      option=$((option+1)); }
    [ "${ENABLE_HY2:-false}"     = "true" ] && { echo "$option) $(msg menu_reset_hy2)";  MENU_MAP[$option]="reset_hy2";     option=$((option+1)); }
    [ "${ENABLE_TUIC:-false}"    = "true" ] && { echo "$option) $(msg menu_reset_tuic)"; MENU_MAP[$option]="reset_tuic";    option=$((option+1)); }
    [ "${ENABLE_REALITY:-false}" = "true" ] && { echo "$option) $(msg menu_reset_rl)";   MENU_MAP[$option]="reset_reality"; option=$((option+1)); }
    [ "${ENABLE_ANYTLS:-false}"  = "true" ] && { echo "$option) $(msg menu_reset_at)";   MENU_MAP[$option]="reset_anytls";  option=$((option+1)); }
    MENU_MAP[$option]="start";     echo "$option) $(msg menu_start)";     option=$((option+1))
    MENU_MAP[$option]="stop";      echo "$option) $(msg menu_stop)";      option=$((option+1))
    MENU_MAP[$option]="restart";   echo "$option) $(msg menu_restart)";   option=$((option+1))
    MENU_MAP[$option]="status";    echo "$option) $(msg menu_status)";    option=$((option+1))
    MENU_MAP[$option]="update";    echo "$option) $(msg menu_update)";    option=$((option+1))
    MENU_MAP[$option]="relay";     echo "$option) $(msg menu_relay)";     option=$((option+1))
    MENU_MAP[$option]="uninstall"; echo "$option) $(msg menu_uninstall)"
    echo "0) $(msg menu_exit)"
    echo "=========================="
}

while true; do
    show_menu
    read -p "$(msg menu_enter)" opt
    [ "$opt" = "0" ] && exit 0
    case "$opt" in
        1) action_view_uri ;;
        2) action_view_config ;;
        3) action_edit_config ;;
        *)
            action="${MENU_MAP[$opt]:-}"
            case "$action" in
                reset_ss)      action_reset_ss ;;
                reset_hy2)     action_reset_hy2 ;;
                reset_tuic)    action_reset_tuic ;;
                reset_reality) action_reset_reality ;;
                reset_anytls)  action_reset_anytls ;;
                start)         service_start   && info "$(msg started)" ;;
                stop)          service_stop    && info "$(msg stopped)" ;;
                restart)       service_restart && info "$(msg restarted)" ;;
                status)        service_status ;;
                update)        action_update ;;
                relay)         action_generate_relay ;;
                uninstall)     action_uninstall; exit 0 ;;
                *)             warn "$(msg invalid_opt): $opt" ;;
            esac
            ;;
    esac
    echo ""
done
SB_SCRIPT

chmod +x "$SB_PATH"
ln -sf /usr/local/bin/candies-sb /usr/bin/candies-sb
info "$(msg sb_created)"
