#!/usr/bin/env bash
# =============================================================
# Candies Sing-box 多协议一键部署脚本 v2
# Author  : Candies-Sven (https://github.com/candies-sven-007)
# Repo    : https://github.com/candies-sven-007/proxy
# Install : bash <(curl -fsSL https://raw.githubusercontent.com/candies-sven-007/proxy/main/install.sh)
# =============================================================
set -euo pipefail

# -----------------------
# 颜色输出函数
info() { echo -e "\033[1;34m[Candies-INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[Candies-WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[Candies-ERR]\033[0m $*" >&2; }

# -----------------------
# 检测系统类型
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
info "检测到系统: $OS (${OS_ID:-unknown})"

# -----------------------
# 检查 root 权限
if [ "$(id -u)" != "0" ]; then
    err "此脚本需要 root 权限运行"
    exit 1
fi

# -----------------------
# 安装依赖
install_deps() {
    info "安装系统依赖..."
    case "$OS" in
        alpine)
            apk update || { err "apk update 失败"; exit 1; }
            apk add --no-cache bash curl ca-certificates openssl openrc || {
                err "依赖安装失败"; exit 1
            }
            ;;
        debian)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y || { err "apt update 失败"; exit 1; }
            apt-get install -y curl ca-certificates openssl || {
                err "依赖安装失败"; exit 1
            }
            ;;
        redhat)
            yum install -y curl ca-certificates openssl || {
                err "依赖安装失败"; exit 1
            }
            ;;
        *)
            warn "未识别的系统类型，尝试继续..."
            ;;
    esac
    info "依赖安装完成"
}

install_deps

# -----------------------
# 端口 & 密码配置
get_config() {
    if [ -n "${SINGBOX_PORT:-}" ]; then
        BASE_PORT="$SINGBOX_PORT"
        info "使用环境变量起始端口: $BASE_PORT"
    else
        echo ""
        read -r -p "请输入起始端口（留空则随机 10000-60000，各协议依次+1）: " USER_PORT
        if [ -z "$USER_PORT" ]; then
            BASE_PORT=$(shuf -i 10000-60000 -n 1 2>/dev/null || echo $((RANDOM % 50001 + 10000)))
            info "使用随机起始端口: $BASE_PORT"
        else
            if ! echo "$USER_PORT" | grep -qE '^[0-9]+$' || [ "$USER_PORT" -lt 1 ] || [ "$USER_PORT" -gt 65531 ]; then
                err "端口必须为 1-65531 的数字（需预留4个连续端口）"
                exit 1
            fi
            BASE_PORT="$USER_PORT"
        fi
    fi

    SS_PORT=$BASE_PORT
    HY2_PORT=$((BASE_PORT + 1))
    TUIC_PORT=$((BASE_PORT + 2))
    VLESS_PORT=$((BASE_PORT + 3))

    info "SS    端口: $SS_PORT"
    info "HY2   端口: $HY2_PORT"
    info "TUIC  端口: $TUIC_PORT"
    info "VLESS 端口: $VLESS_PORT"

    if [ -n "${SINGBOX_PASSWORD:-}" ]; then
        USER_PWD="$SINGBOX_PASSWORD"
        info "使用环境变量密码"
    else
        echo ""
        read -r -p "请输入 SS 密码（留空则自动生成 Base64 密钥）: " USER_PWD
    fi
}

get_config

# -----------------------
# 安装 sing-box
install_singbox() {
    info "开始安装 sing-box..."

    if command -v sing-box >/dev/null 2>&1; then
        CURRENT_VERSION=$(sing-box version 2>/dev/null | head -1 || echo "unknown")
        warn "检测到已安装 sing-box: $CURRENT_VERSION"
        read -r -p "是否重新安装？(y/N): " REINSTALL
        if ! echo "$REINSTALL" | grep -qi "^y"; then
            info "跳过 sing-box 安装"
            return 0
        fi
    fi

    case "$OS" in
        alpine)
            info "使用 Edge 仓库安装 sing-box"
            apk update || { err "apk update 失败"; exit 1; }
            apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community sing-box || {
                err "sing-box 安装失败"; exit 1
            }
            ;;
        debian|redhat)
            bash <(curl -fsSL https://sing-box.app/install.sh) || {
                err "sing-box 安装失败"; exit 1
            }
            ;;
        *)
            err "未支持的系统，无法安装 sing-box"
            exit 1
            ;;
    esac

    if ! command -v sing-box >/dev/null 2>&1; then
        err "sing-box 安装后未找到可执行文件"
        exit 1
    fi

    INSTALLED_VERSION=$(sing-box version 2>/dev/null | head -1 || echo "unknown")
    info "sing-box 安装成功: $INSTALLED_VERSION"
}

install_singbox

# -----------------------
# 生成密码
KEY_BYTES=16
METHOD="2022-blake3-aes-128-gcm"

generate_psk() {
    if [ -n "${USER_PWD:-}" ]; then
        PSK="$USER_PWD"
        info "使用指定密码"
    else
        info "自动生成密码..."
        PSK=""
        if command -v sing-box >/dev/null 2>&1; then
            PSK=$(sing-box generate rand --base64 "$KEY_BYTES" 2>/dev/null | tr -d '\n\r' || true)
        fi
        if [ -z "${PSK:-}" ] && command -v openssl >/dev/null 2>&1; then
            PSK=$(openssl rand -base64 "$KEY_BYTES" | tr -d '\n\r')
        fi
        if [ -z "${PSK:-}" ]; then
            PSK=$(head -c "$KEY_BYTES" /dev/urandom | base64 | tr -d '\n\r')
        fi
        if [ -z "${PSK:-}" ]; then
            err "密码生成失败"; exit 1
        fi
        info "密码生成成功"
    fi
}

generate_psk

# -----------------------
# 生成多协议密钥
generate_multi_keys() {
    info "生成多协议密钥..."

    HY2_PWD=""
    if command -v sing-box >/dev/null 2>&1; then
        HY2_PWD=$(sing-box generate rand --base64 16 2>/dev/null | tr -d '\n\r' || true)
    fi
    [ -z "${HY2_PWD:-}" ] && HY2_PWD=$(openssl rand -base64 16 | tr -d '\n\r')

    TUIC_UUID=$(cat /proc/sys/kernel/random/uuid)
    TUIC_PWD=""
    if command -v sing-box >/dev/null 2>&1; then
        TUIC_PWD=$(sing-box generate rand --base64 16 2>/dev/null | tr -d '\n\r' || true)
    fi
    [ -z "${TUIC_PWD:-}" ] && TUIC_PWD=$(openssl rand -base64 16 | tr -d '\n\r')

    VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)
    REALITY_KEYS=$(sing-box generate reality-keypair)
    REALITY_PK=$(echo "$REALITY_KEYS" | grep "PrivateKey" | awk '{print $NF}')
    REALITY_PUB=$(echo "$REALITY_KEYS" | grep "PublicKey" | awk '{print $NF}')
    REALITY_SID=$(sing-box generate rand 8 --hex)

    mkdir -p /etc/sing-box
    echo "$REALITY_PUB" > /etc/sing-box/.reality_pub
    echo "$REALITY_SID" > /etc/sing-box/.reality_sid

    info "多协议密钥生成完成"
}

generate_multi_keys

# -----------------------
# [BUG FIX #1] 先生成证书，再生成配置，再启动服务
# 原脚本顺序: create_config -> setup_service(启动) -> setup_certs(生成证书) —— 证书不存在导致启动失败
# 修复顺序:   setup_certs -> create_config -> 验证配置 -> setup_service(启动)

# -----------------------
# 生成自签证书（HY2 / TUIC 使用）
setup_certs() {
    info "生成自签 TLS 证书（HY2/TUIC 使用）..."
    mkdir -p /etc/sing-box/certs

    # [BUG FIX #7] 使用 EC P-256 替代 RSA 2048，hy2/tuic 握手更快
    openssl req -x509 \
        -newkey ec \
        -pkeyopt ec_paramgen_curve:P-256 \
        -keyout /etc/sing-box/certs/privkey.pem \
        -out /etc/sing-box/certs/fullchain.pem \
        -days 3650 -nodes \
        -subj "/CN=candies-box.local" \
        >/dev/null 2>&1 \
        && info "自签证书生成完成" \
        || { err "证书生成失败"; exit 1; }
}

setup_certs

# -----------------------
# 生成配置文件
CONFIG_PATH="/etc/sing-box/config.json"

create_config() {
    info "生成配置文件: $CONFIG_PATH"
    mkdir -p "$(dirname "$CONFIG_PATH")"

    cat > "$CONFIG_PATH" <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m"
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "::",
      "listen_port": ${SS_PORT},
      "method": "$METHOD",
      "password": "$PSK"
    },
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": ${HY2_PORT},
      "users": [
        {
          "password": "${HY2_PWD}"
        }
      ],
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/certs/fullchain.pem",
        "key_path": "/etc/sing-box/certs/privkey.pem"
      }
    },
    {
      "type": "tuic",
      "tag": "tuic-in",
      "listen": "::",
      "listen_port": ${TUIC_PORT},
      "users": [
        {
          "uuid": "${TUIC_UUID}",
          "password": "${TUIC_PWD}"
        }
      ],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/certs/fullchain.pem",
        "key_path": "/etc/sing-box/certs/privkey.pem"
      }
    },
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ${VLESS_PORT},
      "users": [
        {
          "uuid": "${VLESS_UUID}",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "addons.mozilla.org",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "addons.mozilla.org",
            "server_port": 443
          },
          "private_key": "${REALITY_PK}",
          "short_id": ["${REALITY_SID}"],
          "max_time_difference": "1m"
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct-out"
    }
  ]
}
EOF

    # [BUG FIX #2] 配置验证失败直接退出，不再 warn 后继续
    if command -v sing-box >/dev/null 2>&1; then
        if sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1; then
            info "配置文件验证通过"
        else
            err "配置文件验证失败，错误详情："
            sing-box check -c "$CONFIG_PATH" 2>&1 || true
            exit 1
        fi
    fi
}

create_config

# -----------------------
# 设置服务（证书和配置都就绪后再启动）
SERVICE_PATH=""

setup_service() {
    info "配置系统服务..."

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

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --mode 0755 /var/log
    checkpath --directory --mode 0755 /run
}
OPENRC

        chmod +x "$SERVICE_PATH"
        rc-update add sing-box default >/dev/null 2>&1 || warn "添加开机自启失败"

        rc-service sing-box restart || {
            err "服务启动失败，查看日志："
            tail -30 /var/log/sing-box.err 2>/dev/null || tail -30 /var/log/sing-box.log 2>/dev/null || true
            exit 1
        }

        sleep 2

        # [BUG FIX #6] 用 pidfile 判断进程是否真正运行，比 rc-service status 更可靠
        if [ -f "/run/sing-box.pid" ] && kill -0 "$(cat /run/sing-box.pid)" 2>/dev/null; then
            info "✅ OpenRC 服务已启动 (PID: $(cat /run/sing-box.pid))"
        else
            err "服务状态异常，查看日志："
            tail -30 /var/log/sing-box.err 2>/dev/null || true
            exit 1
        fi

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
            err "服务启动失败，查看日志："
            journalctl -u sing-box -n 30 --no-pager
            exit 1
        }

        sleep 2

        if systemctl is-active sing-box >/dev/null 2>&1; then
            info "✅ Systemd 服务已启动"
        else
            err "服务状态异常"
            systemctl status sing-box --no-pager
            exit 1
        fi
    fi

    info "服务配置完成: $SERVICE_PATH"
}

setup_service

# -----------------------
# 获取公网 IP
get_public_ip() {
    local ip=""
    for url in \
        "https://api.ipify.org" \
        "https://ipinfo.io/ip" \
        "https://ifconfig.me" \
        "https://icanhazip.com" \
        "https://ipecho.net/plain"; do
        ip=$(curl -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]' || true)
        if echo "$ip" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
            echo "$ip"
            return 0
        fi
    done
    return 1
}

PUB_IP=$(get_public_ip || echo "YOUR_SERVER_IP")
if [ "$PUB_IP" = "YOUR_SERVER_IP" ]; then
    warn "无法获取公网 IP，请手动替换节点信息中的 IP"
else
    info "检测到公网 IP: $PUB_IP"
fi

# -----------------------
# 保存节点信息
NODE_INFO_PATH="/etc/sing-box/candies-nodes.txt"

save_node_info() {
    cat > "$NODE_INFO_PATH" <<EOF
===== Candies Sing-box 节点信息 =====
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
服务器IP: ${PUB_IP}

---- Shadowsocks 2022 ----
服务器: ${PUB_IP}
端口:   ${SS_PORT}
加密:   ${METHOD}
密码:   ${PSK}
URI:    ss://$(printf '%s' "${METHOD}:${PSK}" | base64 | tr -d '\n')@${PUB_IP}:${SS_PORT}#Candies-SS

---- Hysteria2 ----（自签证书，客户端需 skip-cert-verify: true）
服务器: ${PUB_IP}
端口:   ${HY2_PORT}
密码:   ${HY2_PWD}
URI:    hysteria2://${HY2_PWD}@${PUB_IP}:${HY2_PORT}?insecure=1&sni=candies-box.local#Candies-HY2

---- TUIC ----（自签证书，客户端需 skip-cert-verify: true）
服务器: ${PUB_IP}
端口:   ${TUIC_PORT}
UUID:   ${TUIC_UUID}
密码:   ${TUIC_PWD}

---- VLESS Reality ----
服务器:    ${PUB_IP}
端口:      ${VLESS_PORT}
UUID:      ${VLESS_UUID}
PublicKey: ${REALITY_PUB}
ShortID:   ${REALITY_SID}
SNI:       addons.mozilla.org
Flow:      xtls-rprx-vision
URI:       vless://${VLESS_UUID}@${PUB_IP}:${VLESS_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=${REALITY_PUB}&sid=${REALITY_SID}#Candies-VLESS

===== Mihomo/Clash YAML =====
proxies:
  - name: "🇭🇰 HK Candies SS"
    type: ss
    server: ${PUB_IP}
    port: ${SS_PORT}
    cipher: ${METHOD}
    password: "${PSK}"
    udp: true

  - name: "🇭🇰 HK Candies HY2"
    type: hysteria2
    server: ${PUB_IP}
    port: ${HY2_PORT}
    password: "${HY2_PWD}"
    sni: candies-box.local
    alpn:
      - h3
    skip-cert-verify: true
    udp: true

  - name: "🇭🇰 HK Candies TUIC"
    type: tuic
    server: ${PUB_IP}
    port: ${TUIC_PORT}
    uuid: ${TUIC_UUID}
    password: "${TUIC_PWD}"
    sni: candies-box.local
    congestion-controller: bbr
    alpn:
      - h3
    skip-cert-verify: true
    udp: true

  - name: "🇭🇰 HK Candies VLESS"
    type: vless
    server: ${PUB_IP}
    port: ${VLESS_PORT}
    uuid: ${VLESS_UUID}
    flow: xtls-rprx-vision
    tls: true
    servername: addons.mozilla.org
    reality-opts:
      public-key: ${REALITY_PUB}
      short-id: "${REALITY_SID}"
    client-fingerprint: chrome
    network: tcp
EOF
    info "节点信息已保存到: $NODE_INFO_PATH"
}

save_node_info

# -----------------------
# 最终输出
echo ""
echo "=========================================="
info "🎉 Candies Sing-box 部署完成！"
echo "=========================================="
echo ""
cat "$NODE_INFO_PATH"
echo ""
info "📁 文件位置："
echo "   配置: $CONFIG_PATH"
echo "   节点: $NODE_INFO_PATH"
echo "   证书: /etc/sing-box/certs/"
echo ""
info "🔧 管理命令："
if [ "$OS" = "alpine" ]; then
    echo "   启动: rc-service sing-box start"
    echo "   停止: rc-service sing-box stop"
    echo "   重启: rc-service sing-box restart"
    echo "   状态: rc-service sing-box status"
    echo "   日志: tail -f /var/log/sing-box.log"
else
    echo "   启动: systemctl start sing-box"
    echo "   停止: systemctl stop sing-box"
    echo "   重启: systemctl restart sing-box"
    echo "   状态: systemctl status sing-box"
    echo "   日志: journalctl -u sing-box -f"
fi
echo ""
info "📋 管理面板: candies-sb"
echo "=========================================="

# -----------------------
# 创建 candies-sb 管理脚本
SB_PATH="/usr/local/bin/candies-sb"
info "正在创建管理脚本: $SB_PATH"

cat > "$SB_PATH" <<'SB_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

info() { echo -e "\033[1;34m[Candies-INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[Candies-WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[Candies-ERR]\033[0m $*" >&2; }

CONFIG_PATH="/etc/sing-box/config.json"
NODE_INFO_PATH="/etc/sing-box/candies-nodes.txt"
BIN_PATH="/usr/bin/sing-box"
SERVICE_NAME="sing-box"

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID:-}"
        OS_ID_LIKE="${ID_LIKE:-}"
    else
        OS_ID=""; OS_ID_LIKE=""
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

service_start()   {
    if [ "$OS" = "alpine" ]; then rc-service "$SERVICE_NAME" start
    else systemctl start "$SERVICE_NAME"; fi
}
service_stop()    {
    if [ "$OS" = "alpine" ]; then rc-service "$SERVICE_NAME" stop
    else systemctl stop "$SERVICE_NAME"; fi
}
service_restart() {
    if [ "$OS" = "alpine" ]; then rc-service "$SERVICE_NAME" restart
    else systemctl restart "$SERVICE_NAME"; fi
}
service_status()  {
    if [ "$OS" = "alpine" ]; then rc-service "$SERVICE_NAME" status
    else systemctl status "$SERVICE_NAME" --no-pager; fi
}

# 查看节点信息
action_view_uri() {
    if [ -f "$NODE_INFO_PATH" ]; then
        cat "$NODE_INFO_PATH"
    else
        err "节点信息文件不存在: $NODE_INFO_PATH"
        err "请重新运行安装脚本，或手动查看: $CONFIG_PATH"
    fi
}

# 查看配置文件路径
action_view_config() {
    echo "$CONFIG_PATH"
    echo ""
    cat "$CONFIG_PATH"
}

# 编辑配置文件
action_edit_config() {
    if [ ! -f "$CONFIG_PATH" ]; then
        err "配置文件不存在: $CONFIG_PATH"
        return 1
    fi
    ${EDITOR:-vi} "$CONFIG_PATH"
    if command -v sing-box >/dev/null 2>&1; then
        if sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1; then
            info "配置校验通过，重启服务..."
            service_restart || warn "重启失败"
        else
            warn "配置校验失败，服务未重启，错误如下："
            sing-box check -c "$CONFIG_PATH" 2>&1 || true
        fi
    fi
}

# [BUG FIX #3] 重置端口/密码：保留全部4个协议，重新生成所有密钥
action_reset_port_pwd() {
    [ -f "$CONFIG_PATH" ] || { err "配置文件不存在: $CONFIG_PATH"; return 1; }

    read -r -p "输入新起始端口（回车随机 10000-60000）: " new_base
    if [ -z "$new_base" ]; then
        new_base=$((RANDOM % 50001 + 10000))
        info "使用随机起始端口: $new_base"
    fi

    NEW_SS_PORT=$new_base
    NEW_HY2_PORT=$((new_base + 1))
    NEW_TUIC_PORT=$((new_base + 2))
    NEW_VLESS_PORT=$((new_base + 3))

    read -r -p "输入新 SS 密码（回车随机生成）: " new_ss_pwd
    [ -z "$new_ss_pwd" ] && new_ss_pwd=$(openssl rand -base64 16 | tr -d '\n\r')

    new_hy2_pwd=$(openssl rand -base64 16 | tr -d '\n\r')
    new_tuic_uuid=$(cat /proc/sys/kernel/random/uuid)
    new_tuic_pwd=$(openssl rand -base64 16 | tr -d '\n\r')
    new_vless_uuid=$(cat /proc/sys/kernel/random/uuid)

    REALITY_KEYS=$(sing-box generate reality-keypair)
    new_reality_pk=$(echo "$REALITY_KEYS" | grep "PrivateKey" | awk '{print $NF}')
    new_reality_pub=$(echo "$REALITY_KEYS" | grep "PublicKey" | awk '{print $NF}')
    new_reality_sid=$(sing-box generate rand 8 --hex)

    info "停止服务..."
    service_stop || warn "停止服务失败（可能未运行）"

    cat > "$CONFIG_PATH" <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m"
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "::",
      "listen_port": ${NEW_SS_PORT},
      "method": "2022-blake3-aes-128-gcm",
      "password": "$new_ss_pwd"
    },
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": ${NEW_HY2_PORT},
      "users": [{"password": "$new_hy2_pwd"}],
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/certs/fullchain.pem",
        "key_path": "/etc/sing-box/certs/privkey.pem"
      }
    },
    {
      "type": "tuic",
      "tag": "tuic-in",
      "listen": "::",
      "listen_port": ${NEW_TUIC_PORT},
      "users": [{"uuid": "$new_tuic_uuid", "password": "$new_tuic_pwd"}],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/certs/fullchain.pem",
        "key_path": "/etc/sing-box/certs/privkey.pem"
      }
    },
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ${NEW_VLESS_PORT},
      "users": [{"uuid": "$new_vless_uuid", "flow": "xtls-rprx-vision"}],
      "tls": {
        "enabled": true,
        "server_name": "addons.mozilla.org",
        "reality": {
          "enabled": true,
          "handshake": {"server": "addons.mozilla.org", "server_port": 443},
          "private_key": "$new_reality_pk",
          "short_id": ["$new_reality_sid"],
          "max_time_difference": "1m"
        }
      }
    }
  ],
  "outbounds": [
    {"type": "direct", "tag": "direct-out"}
  ]
}
EOF

    if sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1; then
        info "配置验证通过，启动服务..."
        service_start || warn "启动服务失败"
    else
        err "新配置验证失败："
        sing-box check -c "$CONFIG_PATH" 2>&1 || true
        return 1
    fi

    # 更新节点信息文件
    PUB_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null | tr -d '[:space:]' || echo "YOUR_SERVER_IP")
    cat > "$NODE_INFO_PATH" <<EOF2
===== Candies Sing-box 节点信息（已重置）=====
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
服务器IP: ${PUB_IP}

---- Shadowsocks 2022 ----
端口: ${NEW_SS_PORT} | 密码: $new_ss_pwd

---- Hysteria2 ----（skip-cert-verify: true）
端口: ${NEW_HY2_PORT} | 密码: $new_hy2_pwd

---- TUIC ----（skip-cert-verify: true）
端口: ${NEW_TUIC_PORT} | UUID: $new_tuic_uuid | 密码: $new_tuic_pwd

---- VLESS Reality ----
端口: ${NEW_VLESS_PORT} | UUID: $new_vless_uuid
PublicKey: $new_reality_pub | ShortID: $new_reality_sid

===== Mihomo/Clash YAML =====
proxies:
  - name: "🇭🇰 HK Candies SS"
    type: ss
    server: ${PUB_IP}
    port: ${NEW_SS_PORT}
    cipher: 2022-blake3-aes-128-gcm
    password: "$new_ss_pwd"
    udp: true

  - name: "🇭🇰 HK Candies HY2"
    type: hysteria2
    server: ${PUB_IP}
    port: ${NEW_HY2_PORT}
    password: "$new_hy2_pwd"
    sni: candies-box.local
    alpn:
      - h3
    skip-cert-verify: true
    udp: true

  - name: "🇭🇰 HK Candies TUIC"
    type: tuic
    server: ${PUB_IP}
    port: ${NEW_TUIC_PORT}
    uuid: $new_tuic_uuid
    password: "$new_tuic_pwd"
    sni: candies-box.local
    congestion-controller: bbr
    alpn:
      - h3
    skip-cert-verify: true
    udp: true

  - name: "🇭🇰 HK Candies VLESS"
    type: vless
    server: ${PUB_IP}
    port: ${NEW_VLESS_PORT}
    uuid: $new_vless_uuid
    flow: xtls-rprx-vision
    tls: true
    servername: addons.mozilla.org
    reality-opts:
      public-key: $new_reality_pub
      short-id: "$new_reality_sid"
    client-fingerprint: chrome
    network: tcp
EOF2

    info "节点信息已更新: $NODE_INFO_PATH"
    cat "$NODE_INFO_PATH"
}

# 更新 sing-box
action_update() {
    info "开始更新 sing-box..."
    if [ "$OS" = "alpine" ]; then
        apk update || warn "apk update 失败"
        apk add --upgrade --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community sing-box || {
            warn "apk 更新失败"
        }
    else
        bash <(curl -fsSL https://sing-box.app/install.sh) || err "更新失败"
    fi
    if command -v sing-box >/dev/null 2>&1; then
        NEW_VER=$(sing-box version 2>/dev/null | head -1 || echo "unknown")
        info "当前 sing-box 版本: $NEW_VER"
        service_restart || warn "重启失败"
    else
        warn "更新后未检测到 sing-box 可执行文件"
    fi
}

# 卸载
action_uninstall() {
    info "正在卸载 sing-box..."
    service_stop || true
    if [ "$OS" = "alpine" ]; then
        rc-update del "$SERVICE_NAME" default >/dev/null 2>&1 || true
        rm -f "/etc/init.d/$SERVICE_NAME"
        apk del sing-box >/dev/null 2>&1 || true
    else
        systemctl disable "$SERVICE_NAME" >/dev/null 2>&1 || true
        rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi
    rm -rf /etc/sing-box /var/log/sing-box* /usr/local/bin/candies-sb >/dev/null 2>&1 || true
    info "卸载完成"
}

# 生成线路机一键安装脚本
action_generate_relay_script() {
    info "准备生成线路机一键安装脚本..."
    [ -f "$CONFIG_PATH" ] || { err "配置文件不存在"; return 1; }

    SS_PWD=$(python3 -c "import json; c=json.load(open('$CONFIG_PATH')); print(c['inbounds'][0]['password'])" 2>/dev/null \
        || grep -m1 '"password"' "$CONFIG_PATH" | sed -E 's/.*"password"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    SS_PORT_VAL=$(python3 -c "import json; c=json.load(open('$CONFIG_PATH')); print(c['inbounds'][0]['listen_port'])" 2>/dev/null \
        || grep -m1 '"listen_port"' "$CONFIG_PATH" | sed -E 's/.*"listen_port"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
    SS_METHOD="2022-blake3-aes-128-gcm"

    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null | tr -d '[:space:]' || echo "YOUR_SERVER_IP")
    info "落地机出口节点：${PUBLIC_IP}:${SS_PORT_VAL}"

    RELAY_SCRIPT_PATH="/tmp/relay-install.sh"
    cat > "$RELAY_SCRIPT_PATH" <<RELAY_TEMPLATE
#!/usr/bin/env bash
set -euo pipefail
INBOUND_IP="${PUBLIC_IP}"
INBOUND_PORT="${SS_PORT_VAL}"
INBOUND_METHOD="${SS_METHOD}"
INBOUND_PASSWORD="${SS_PWD}"
info() { echo -e "\033[1;34m[INFO]\033[0m \$*"; }
err()  { echo -e "\033[1;31m[ERR]\033[0m \$*" >&2; }
[ "\$(id -u)" = "0" ] || { err "必须以 root 运行"; exit 1; }
detect_os() {
    . /etc/os-release 2>/dev/null || true
    case "\${ID:-}" in
        alpine) OS=alpine ;;
        debian|ubuntu) OS=debian ;;
        centos|rhel|fedora) OS=redhat ;;
        *) OS=unknown ;;
    esac
}
detect_os
info "检测到系统: \$OS"
case "\$OS" in
    alpine)
        apk update && apk add --no-cache curl bash openssl ca-certificates
        apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community sing-box
        ;;
    debian)
        apt-get update -y && apt-get install -y curl bash openssl ca-certificates
        bash <(curl -fsSL https://sing-box.app/install.sh)
        ;;
    redhat)
        yum install -y curl bash openssl ca-certificates
        bash <(curl -fsSL https://sing-box.app/install.sh)
        ;;
esac
UUID=\$(cat /proc/sys/kernel/random/uuid)
REALITY_KEYS=\$(sing-box generate reality-keypair)
REALITY_PK=\$(echo "\$REALITY_KEYS" | grep "PrivateKey" | awk '{print \$NF}')
REALITY_PUB=\$(echo "\$REALITY_KEYS" | grep "PublicKey" | awk '{print \$NF}')
REALITY_SID=\$(sing-box generate rand 8 --hex)
read -r -p "输入线路机监听端口（留空则随机 20000-65000）: " USER_PORT
if [ -z "\$USER_PORT" ]; then
    LISTEN_PORT=\$(shuf -i 20000-65000 -n 1 2>/dev/null || echo \$((RANDOM % 45001 + 20000)))
else
    LISTEN_PORT="\$USER_PORT"
fi
info "线路机监听端口: \$LISTEN_PORT"
mkdir -p /etc/sing-box
cat > /etc/sing-box/config.json <<EOF
{
  "log": {"level": "info", "timestamp": true},
  "inbounds": [{
    "type": "vless",
    "listen": "::",
    "listen_port": \$LISTEN_PORT,
    "users": [{"uuid": "\$UUID", "flow": "xtls-rprx-vision"}],
    "tls": {
      "enabled": true,
      "server_name": "addons.mozilla.org",
      "reality": {
        "enabled": true,
        "handshake": {"server": "addons.mozilla.org", "server_port": 443},
        "private_key": "\$REALITY_PK",
        "short_id": ["\$REALITY_SID"],
        "max_time_difference": "1m"
      }
    },
    "tag": "vless-in"
  }],
  "outbounds": [
    {
      "type": "shadowsocks",
      "server": "\$INBOUND_IP",
      "server_port": \$INBOUND_PORT,
      "method": "\$INBOUND_METHOD",
      "password": "\$INBOUND_PASSWORD",
      "tag": "relay-out"
    },
    {"type": "direct", "tag": "direct-out"}
  ],
  "route": {
    "rules": [{"inbound": "vless-in", "outbound": "relay-out"}]
  }
}
EOF
if [ "\$OS" = "alpine" ]; then
    cat > /etc/init.d/sing-box <<'SVC'
#!/sbin/openrc-run
name="sing-box"
command="/usr/bin/sing-box"
command_args="run -c /etc/sing-box/config.json"
command_background="yes"
pidfile="/run/sing-box.pid"
output_log="/var/log/sing-box.log"
error_log="/var/log/sing-box.err"
depend() { need net; }
SVC
    chmod +x /etc/init.d/sing-box
    rc-update add sing-box default
    rc-service sing-box restart
else
    cat > /etc/systemd/system/sing-box.service <<'SVC'
[Unit]
Description=Sing-box Relay
After=network.target
[Service]
ExecStart=/usr/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
SVC
    systemctl daemon-reload
    systemctl enable sing-box
    systemctl restart sing-box
fi
PUB_IP=\$(curl -s https://api.ipify.org || echo "YOUR_RELAY_IP")
echo ""
echo "✅ 安装完成"
echo "vless://\$UUID@\$PUB_IP:\$LISTEN_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=\$REALITY_PUB&sid=\$REALITY_SID#relay"
RELAY_TEMPLATE

    chmod +x "$RELAY_SCRIPT_PATH"
    info "✅ 线路机脚本已生成: $RELAY_SCRIPT_PATH"
    echo ""
    info "在线路机上执行："
    echo "   bash /tmp/relay-install.sh"
    echo ""
    echo "------------------------------------------"
    cat "$RELAY_SCRIPT_PATH"
    echo "------------------------------------------"
}

# -----------------------
# 菜单
while true; do
    cat <<'MENU'

==========================
 Candies Sing-box 管理面板
==========================
1) 查看节点信息 / YAML
2) 查看配置文件
3) 编辑配置文件
4) 重置密码/端口（保留全部协议）
5) 启动服务
6) 停止服务
7) 重启服务
8) 查看状态
9) 更新 sing-box
10) 生成线路机一键安装脚本
11) 卸载 sing-box
0) 退出
==========================
MENU

    read -r -p "请输入选项: " opt
    case "${opt:-}" in
        1) action_view_uri ;;
        2) action_view_config ;;
        3) action_edit_config ;;
        4) action_reset_port_pwd ;;
        5) service_start && info "已发送启动命令" ;;
        6) service_stop && info "已发送停止命令" ;;
        7) service_restart && info "已发送重启命令" ;;
        8) service_status ;;
        9) action_update ;;
        10) action_generate_relay_script ;;
        11) action_uninstall; exit 0 ;;
        0) exit 0 ;;
        *) warn "无效选项" ;;
    esac
    echo ""
done
SB_SCRIPT

chmod +x "$SB_PATH"
info "candies-sb 管理脚本已创建，输入 candies-sb 运行"
