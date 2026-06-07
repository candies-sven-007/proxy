#!/usr/bin/env bash
# =============================================================
# Candies Sing-box 多协议一键部署脚本
# Author  : Candies-Sven (https://github.com/candies-sven-007)
# Repo    : https://github.com/candies-sven-007/proxy
# License : MIT
# =============================================================
set -euo pipefail

SCRIPT_URL="https://raw.githubusercontent.com/candies-sven-007/proxy/main/install.sh"
SB_PATH="/usr/local/bin/candies-sb"
CONFIG_PATH="/etc/sing-box/config.json"
CERTS_DIR="/etc/sing-box/certs"
SERVICE_NAME="sing-box"

# 颜色输出
info() { echo -e "\033[1;34m[Candies-INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[Candies-WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[Candies-ERR]\033[0m $*" >&2; }

# -----------------------
# 检测系统
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
# 检查 root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        err "此脚本需要 root 权限运行"
        exit 1
    fi
}
check_root

# -----------------------
# 安装依赖
install_deps() {
    info "安装系统依赖..."
    case "$OS" in
        alpine)
            apk update || { err "apk update 失败"; exit 1; }
            apk add --no-cache bash curl ca-certificates openssl openrc python3 || {
                err "依赖安装失败"; exit 1
            }
            ;;
        debian)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y || { err "apt update 失败"; exit 1; }
            apt-get install -y curl ca-certificates openssl python3 || {
                err "依赖安装失败"; exit 1
            }
            ;;
        redhat)
            yum install -y curl ca-certificates openssl python3 || {
                err "依赖安装失败"; exit 1
            }
            ;;
        *)
            warn "未识别系统，尝试继续..."
            ;;
    esac
    info "依赖安装完成"
}
install_deps

# -----------------------
# 安装 sing-box（Alpine 用 edge 仓库原生 musl 版本）
install_singbox() {
    info "开始安装 sing-box..."
    if command -v sing-box >/dev/null 2>&1; then
        CURRENT_VER=$(sing-box version 2>/dev/null | head -1 || echo "unknown")
        warn "检测到已安装 sing-box: $CURRENT_VER"
        read -p "是否重新安装？(y/N): " REINSTALL
        if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
            info "跳过 sing-box 安装"
            return 0
        fi
    fi

    case "$OS" in
        alpine)
            info "从 Alpine edge 仓库安装 sing-box（musl 原生版本）"
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
            err "未支持的系统"; exit 1
            ;;
    esac

    if ! command -v sing-box >/dev/null 2>&1; then
        err "sing-box 安装后未找到可执行文件"
        exit 1
    fi
    info "sing-box 安装成功: $(sing-box version 2>/dev/null | head -1)"
}
install_singbox

# -----------------------
# 端口配置
get_ports() {
    echo ""
    info "端口配置（每个协议占一个独立端口）"

    read -p "请输入起始端口（留空则随机，后续端口依次+1）: " BASE_PORT
    if [ -z "$BASE_PORT" ]; then
        BASE_PORT=$(shuf -i 10000-60000 -n 1 2>/dev/null || echo $((RANDOM % 50001 + 10000)))
        info "使用随机起始端口: $BASE_PORT"
    fi

    SS_PORT=$BASE_PORT
    HY2_PORT=$((BASE_PORT + 1))
    TUIC_PORT=$((BASE_PORT + 2))
    VLESS_PORT=$((BASE_PORT + 3))

    info "SS    端口: $SS_PORT"
    info "HY2   端口: $HY2_PORT"
    info "TUIC  端口: $TUIC_PORT"
    info "VLESS 端口: $VLESS_PORT"
}
get_ports

# -----------------------
# 生成密钥和 UUID
generate_keys() {
    info "生成密钥..."

    # SS 密码（16字节 base64）
    SS_PSK=$(openssl rand -base64 16 | tr -d '\n\r')

    # HY2 密码
    HY2_PWD=$(openssl rand -base64 16 | tr -d '\n\r')

    # TUIC UUID + 密码
    TUIC_UUID=$(cat /proc/sys/kernel/random/uuid)
    TUIC_PWD=$(openssl rand -base64 16 | tr -d '\n\r')

    # VLESS UUID + Reality 密钥对
    VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)
    REALITY_KEYS=$(sing-box generate reality-keypair)
    REALITY_PK=$(echo "$REALITY_KEYS" | grep "PrivateKey" | awk '{print $NF}')
    REALITY_PUB=$(echo "$REALITY_KEYS" | grep "PublicKey" | awk '{print $NF}')
    REALITY_SID=$(sing-box generate rand 8 --hex)

    info "密钥生成完成"
}
generate_keys

# -----------------------
# 申请证书（HY2 和 TUIC 需要）
setup_certs() {
    info "配置 TLS 证书..."
    mkdir -p "$CERTS_DIR"

    echo ""
    read -p "请输入你的域名（用于 HY2/TUIC 证书，留空使用自签证书）: " DOMAIN

    if [ -n "$DOMAIN" ]; then
        # 使用 acme.sh 申请证书
        if ! command -v acme.sh >/dev/null 2>&1; then
            info "安装 acme.sh..."
            curl -fsSL https://get.acme.sh | bash -s email=admin@${DOMAIN} || {
                warn "acme.sh 安装失败，改用自签证书"
                DOMAIN=""
            }
        fi

        if [ -n "$DOMAIN" ]; then
            ~/.acme.sh/acme.sh --issue --standalone -d "$DOMAIN" \
                --cert-file "${CERTS_DIR}/cert.pem" \
                --key-file "${CERTS_DIR}/privkey.pem" \
                --fullchain-file "${CERTS_DIR}/fullchain.pem" || {
                warn "证书申请失败，改用自签证书"
                DOMAIN=""
            }
        fi
    fi

    if [ -z "$DOMAIN" ]; then
        info "使用自签证书（需要客户端开启 skip-cert-verify）"
        DOMAIN="candies-box.local"
        openssl req -x509 -newkey rsa:2048 -keyout "${CERTS_DIR}/privkey.pem" \
            -out "${CERTS_DIR}/fullchain.pem" -days 3650 -nodes \
            -subj "/CN=${DOMAIN}" >/dev/null 2>&1
        cp "${CERTS_DIR}/fullchain.pem" "${CERTS_DIR}/cert.pem"
        SKIP_CERT_VERIFY=true
    else
        SKIP_CERT_VERIFY=false
    fi

    info "证书配置完成: $CERTS_DIR"
}
setup_certs

# -----------------------
# 生成配置文件
create_config() {
    info "生成配置文件: $CONFIG_PATH"
    mkdir -p "$(dirname "$CONFIG_PATH")"

    cat > "$CONFIG_PATH" << EOF
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
      "method": "2022-blake3-aes-128-gcm",
      "password": "${SS_PSK}"
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
        "certificate_path": "${CERTS_DIR}/fullchain.pem",
        "key_path": "${CERTS_DIR}/privkey.pem"
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
        "certificate_path": "${CERTS_DIR}/fullchain.pem",
        "key_path": "${CERTS_DIR}/privkey.pem"
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

    if sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1; then
        info "配置文件验证通过"
    else
        warn "配置文件验证失败，请检查"
    fi
}
create_config

# -----------------------
# 设置服务（OpenRC / systemd）
setup_service() {
    info "配置系统服务..."

    if [ "$OS" = "alpine" ]; then
        SERVICE_PATH="/etc/init.d/sing-box"
        cat > "$SERVICE_PATH" << 'OPENRC'
#!/sbin/openrc-run
name="sing-box"
description="Candies Sing-box Proxy"
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
            err "服务启动失败，查看日志:"
            tail -20 /var/log/sing-box.err 2>/dev/null || true
            exit 1
        }
    else
        SERVICE_PATH="/etc/systemd/system/sing-box.service"
        cat > "$SERVICE_PATH" << 'SYSTEMD'
[Unit]
Description=Candies Sing-box Proxy
After=network.target nss-lookup.target
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
            err "服务启动失败"; journalctl -u sing-box -n 30 --no-pager; exit 1
        }
    fi
    info "服务配置完成"
}
setup_service

# -----------------------
# 获取公网 IP
get_public_ip() {
    local ip=""
    for url in "https://api.ipify.org" "https://ipinfo.io/ip" "https://ifconfig.me" "https://icanhazip.com"; do
        ip=$(curl -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]' || true)
        if [ -n "$ip" ]; then echo "$ip"; return 0; fi
    done
    return 1
}
PUB_IP=$(get_public_ip || echo "YOUR_SERVER_IP")
info "公网 IP: $PUB_IP"

# -----------------------
# 保存节点信息
save_node_info() {
    INFO_PATH="/etc/sing-box/candies-nodes.txt"
    SKIP_STR=""
    [ "${SKIP_CERT_VERIFY:-false}" = "true" ] && SKIP_STR="  (自签证书，客户端需开启 skip-cert-verify)"

    cat > "$INFO_PATH" << EOF
===== Candies Sing-box 节点信息 =====
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
服务器IP: ${PUB_IP}

---- Shadowsocks 2022 ----
服务器: ${PUB_IP}
端口:   ${SS_PORT}
加密:   2022-blake3-aes-128-gcm
密码:   ${SS_PSK}

---- Hysteria2 ----${SKIP_STR}
服务器: ${PUB_IP}
端口:   ${HY2_PORT}
密码:   ${HY2_PWD}
SNI:    ${DOMAIN}

---- TUIC ----${SKIP_STR}
服务器: ${PUB_IP}
端口:   ${TUIC_PORT}
UUID:   ${TUIC_UUID}
密码:   ${TUIC_PWD}
SNI:    ${DOMAIN}

---- VLESS Reality ----
服务器:     ${PUB_IP}
端口:       ${VLESS_PORT}
UUID:       ${VLESS_UUID}
PublicKey:  ${REALITY_PUB}
ShortID:    ${REALITY_SID}
SNI:        addons.mozilla.org
Flow:       xtls-rprx-vision

===== Mihomo/Clash YAML 格式 =====
proxies:
  - name: 🇭🇰 Candies SS
    type: ss
    server: ${PUB_IP}
    port: ${SS_PORT}
    cipher: 2022-blake3-aes-128-gcm
    password: "${SS_PSK}"
    udp: true

  - name: 🇭🇰 Candies HY2
    type: hysteria2
    server: ${PUB_IP}
    port: ${HY2_PORT}
    password: "${HY2_PWD}"
    sni: ${DOMAIN}
    alpn:
      - h3
    skip-cert-verify: ${SKIP_CERT_VERIFY:-false}
    udp: true

  - name: 🇭🇰 Candies TUIC
    type: tuic
    server: ${PUB_IP}
    port: ${TUIC_PORT}
    uuid: ${TUIC_UUID}
    password: "${TUIC_PWD}"
    sni: ${DOMAIN}
    congestion-controller: bbr
    alpn:
      - h3
    skip-cert-verify: ${SKIP_CERT_VERIFY:-false}
    udp: true

  - name: 🇭🇰 Candies VLESS
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

    info "节点信息已保存到: $INFO_PATH"
}
save_node_info

# -----------------------
# 创建 candies-sb 管理工具
create_sb_tool() {
    info "创建管理工具: $SB_PATH"

    cat > "$SB_PATH" << 'SB_TOOL'
#!/usr/bin/env bash
# Candies Sing-box 管理工具
set -euo pipefail

info() { echo -e "\033[1;34m[Candies]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR]\033[0m $*" >&2; }

CONFIG_PATH="/etc/sing-box/config.json"
INFO_PATH="/etc/sing-box/candies-nodes.txt"
SERVICE_NAME="sing-box"

detect_os() {
    . /etc/os-release 2>/dev/null || true
    case "${ID:-}" in
        alpine) OS=alpine ;;
        debian|ubuntu) OS=debian ;;
        *) OS=other ;;
    esac
}
detect_os

svc() {
    if [ "$OS" = "alpine" ]; then rc-service "$SERVICE_NAME" "$1"
    else systemctl "$1" "$SERVICE_NAME"; fi
}

while true; do
    echo ""
    echo "======================================"
    echo "  Candies Sing-box 管理面板"
    echo "  https://github.com/candies-sven-007"
    echo "======================================"
    echo "1) 查看节点信息 / YAML"
    echo "2) 查看配置文件"
    echo "3) 编辑配置文件"
    echo "4) 启动服务"
    echo "5) 停止服务"
    echo "6) 重启服务"
    echo "7) 查看服务状态"
    echo "8) 查看实时日志"
    echo "9) 更新 sing-box"
    echo "0) 退出"
    echo "======================================"
    read -p "请输入选项: " opt

    case "${opt:-}" in
        1)
            if [ -f "$INFO_PATH" ]; then cat "$INFO_PATH"
            else err "节点信息文件不存在，请重新运行安装脚本"; fi
            ;;
        2) cat "$CONFIG_PATH" ;;
        3)
            ${EDITOR:-vi} "$CONFIG_PATH"
            if sing-box check -c "$CONFIG_PATH" >/dev/null 2>&1; then
                info "配置校验通过，重启服务..."
                svc restart || warn "重启失败"
            else
                warn "配置校验失败，服务未重启"
            fi
            ;;
        4) svc start && info "已启动" ;;
        5) svc stop && info "已停止" ;;
        6) svc restart && info "已重启" ;;
        7) svc status ;;
        8)
            if [ "$OS" = "alpine" ]; then tail -f /var/log/sing-box.log
            else journalctl -u sing-box -f; fi
            ;;
        9)
            info "更新 sing-box..."
            if [ "$OS" = "alpine" ]; then
                apk add --upgrade --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community sing-box || warn "更新失败"
            else
                bash <(curl -fsSL https://sing-box.app/install.sh) || warn "更新失败"
            fi
            svc restart || warn "重启失败"
            info "更新完成: $(sing-box version 2>/dev/null | head -1)"
            ;;
        0) exit 0 ;;
        *) warn "无效选项" ;;
    esac
done
SB_TOOL

    chmod +x "$SB_PATH"
    info "管理工具已创建，输入 candies-sb 运行"
}
create_sb_tool

# -----------------------
# 最终输出
echo ""
echo "=========================================="
info "🎉 Candies Sing-box 部署完成！"
echo "=========================================="
cat /etc/sing-box/candies-nodes.txt
echo ""
echo "=========================================="
info "管理命令: candies-sb"
info "节点信息: cat /etc/sing-box/candies-nodes.txt"
if [ "$OS" = "alpine" ]; then
    info "日志查看: tail -f /var/log/sing-box.log"
else
    info "日志查看: journalctl -u sing-box -f"
fi
echo "=========================================="
