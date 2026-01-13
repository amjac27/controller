#!/usr/bin/env python3
import subprocess
import os
import sys
from pathlib import Path

def main():
    username = "openeuler"
    
    # 获取当前工作目录的绝对路径
    current_dir = Path.cwd()
    
    # 相对路径
    relative_path = "./back.jpg"
    
    # 转换为绝对路径
    abs_path = (current_dir / relative_path).resolve()
    
    # 检查文件是否存在
    if not abs_path.exists():
        print(f"错误: 文件不存在: {abs_path}")
        print(f"当前工作目录: {current_dir}")
        sys.exit(1)
    
    print(f"使用背景图片: {abs_path}")
    print(f"图片URI: file://{abs_path}")
    
    # 方法1: 使用登录shell并导出环境变量
    cmd = f"""
    # 尝试获取当前用户的dbus地址
    if [ -e "/run/user/$(id -u)/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    fi
    
    # 设置DISPLAY
    export DISPLAY=":0"
    export XAUTHORITY="$HOME/.Xauthority"
    
    # 执行dbus命令
    dbus-send --session --print-reply=literal --dest=com.deepin.daemon.Appearance /com/deepin/daemon/Appearance com.deepin.daemon.Appearance.SetMonitorBackground string:Virtual-1 string:"file://{abs_path}"
    """
    
    print("修改用户桌面背景...")
    
    # 使用bash -c执行，这样会加载用户的环境
    result = subprocess.run(
        ["sudo", "-u", username, "bash", "-c", cmd],
        capture_output=True,
        text=True
    )
    
    print(f"返回码: {result.returncode}")
    if result.stdout:
        print(f"输出: {result.stdout}")
    if result.stderr:
        print(f"错误: {result.stderr}")
    
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
